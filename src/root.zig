const std = @import("std");

fn get_module_field_name(sys: anytype, comptime M: type) ?[]const u8 {
    inline for (std.meta.fields(@TypeOf(sys))) |field| {
        if (field.type == M) {
            return field.name;
        }
    }
    return null;
}
pub fn get(sys: anytype, comptime M: type) *M {
    return if (get_module_field_name(sys, M)) |field_name|
        &@field(sys, field_name)
    else
        @compileError(std.fmt.comptimePrint("Module `{any}` wasn't found", @typeName(M)));
}
pub fn invoke(sys: anytype, comptime function_name: []const u8, args: anytype) void {
    search: inline for (std.meta.fields(@TypeOf(sys))) |field| {
        const Module = field.type;
        if (!std.meta.hasMethod(Module, function_name))
            continue :search;

        const params = @typeInfo(@TypeOf(@field(Module, function_name))).Fn.params;
        if (params[0].type != *Module)
            continue :search;
        if (!params[1].is_generic)
            continue :search;
        for (std.meta.fields(args), params[2..params.len]) |arg, param| {
            if (arg.type != param.type) {
                continue :search;
            }
        }

        const module_value = &@field(sys, field.name);
        @call(.auto, @field(Module, function_name), .{ module_value, sys } ++ args);
    }
}
pub fn require(sys: anytype, comptime CurrentModule: type, comptime required_modules: []const type) void {
    comptime for (required_modules) |Module| {
        if (get_module_field_name(sys, Module) == null) {
            @compileError(std.fmt.comptimePrint("Module `{s}` requires module `{s}` but it wasn't found", .{ @typeName(CurrentModule), @typeName(Module) }));
        }
    };
}
