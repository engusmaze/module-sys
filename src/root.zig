const std = @import("std");

fn findModuleName(SystemType: type, comptime ModuleType: type) ?[]const u8 {
    inline for (std.meta.fields(SystemType)) |field| {
        if (field.type == ModuleType) {
            return field.name;
        }
    }
    return null;
}

pub fn getSystemType(TopType: type) type {
    const topTypeInfo = @typeInfo(TopType);
    if (topTypeInfo != .Pointer) {
        @compileError("Expected a reference to a module system instance");
    }
    const SystemType = topTypeInfo.Pointer.child;
    if (@typeInfo(SystemType) != .Struct) {
        @compileError("Module system should be a struct of modules");
    }
    return SystemType;
}

/// Gets a moduel from module system
pub inline fn get(sys: anytype, comptime ModuleType: type) *ModuleType {
    const SystemType = getSystemType(@TypeOf(sys));
    if (comptime findModuleName(SystemType, ModuleType)) |module_name| {
        return &@field(sys, module_name);
    } else {
        @compileError(std.fmt.comptimePrint("Module `{any}` not found in the system", @typeName(ModuleType)));
    }
}

/// Calls a function on each module of system with specified arguments
pub fn invoke(sys: anytype, comptime function_name: []const u8, args: anytype) void {
    const SystemType = getSystemType(@TypeOf(sys));
    search: inline for (std.meta.fields(SystemType)) |field| {
        const ModuleType = field.type;

        if (!std.meta.hasFn(ModuleType, function_name))
            continue :search;
        const function = @field(ModuleType, function_name);

        const params = @typeInfo(@TypeOf(function)).Fn.params;
        if (params.len < 2)
            continue :search;
        if (params[0].type != *ModuleType or params[1].type != null)
            continue :search;

        const arg_fields = std.meta.fields(@TypeOf(args));
        const real_params = params[2..params.len];
        if (arg_fields.len != real_params.len)
            continue :search;
        inline for (arg_fields, real_params) |arg, param| {
            if (arg.type != param.type) {
                continue :search;
            }
        }

        @call(.auto, function, .{ if (@sizeOf(ModuleType) > 0)
            &@field(sys, field.name)
        else
            @constCast(&ModuleType{}), sys } ++ args);
    }
}

pub fn require(sys: anytype, comptime CurrentModule: type, comptime required_modules: []const type) void {
    const SystemType = getSystemType(@TypeOf(sys));
    inline for (required_modules) |Module| {
        if (comptime findModuleName(SystemType, Module) == null) {
            @compileError(std.fmt.comptimePrint("Module `{s}` requires module `{s}` which is not found in the system", .{ @typeName(CurrentModule), @typeName(Module) }));
        }
    }
}

pub fn requireBefore(sys: anytype, comptime CurrentModule: type, comptime required_modules: []const type) void {
    const SystemType = getSystemType(@TypeOf(sys));
    comptime var current_module_index = 0;
    const system_struct = @typeInfo(SystemType).Struct;
    inline while (true) {
        if (current_module_index < system_struct.fields.len) {
            if (system_struct.fields[current_module_index].type == CurrentModule) {
                break;
            }
            current_module_index += 1;
        } else {
            @compileError("Module `{any}` is not present in the current module system");
        }
    }
    comptime var fields_before: [current_module_index]std.builtin.Type.StructField = undefined;
    @memcpy(&fields_before, system_struct.fields[0..current_module_index]);
    const SystemBefore = @Type(.{
        .Struct = .{
            .layout = .auto,
            .fields = &fields_before,
            .decls = &.{},
            .is_tuple = false,
        },
    });
    inline for (required_modules) |Module| {
        if (comptime findModuleName(SystemBefore, Module) == null) {
            @compileError(std.fmt.comptimePrint("Module {s} is required to be defined before module {s} but it wasn't found", .{ @typeName(CurrentModule), @typeName(Module) }));
        }
    }
}
