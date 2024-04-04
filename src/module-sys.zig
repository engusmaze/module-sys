const std = @import("std");
const Type = std.builtin.Type;
const meta = std.meta;

pub fn ModuleSystem(comptime modules: anytype) type {
    const t = @typeInfo(@TypeOf(modules));
    if (t != .Struct) {
        @compileError("Expected tuple of modules");
    }
    const s = t.Struct;
    if (!s.is_tuple) {
        @compileError("Expected tuple of modules");
    }
    const module_count = s.fields.len;
    const module_types: [module_count]type = modules;

    const Modules = @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &result: {
            var fields: [module_count]Type.StructField = undefined;
            for (&fields, module_types) |*field, Module| {
                field.* = .{
                    .name = @typeName(Module),
                    .type = Module,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = 0,
                };
            }
            break :result fields;
        },
        .decls = &[_]Type.Declaration{},
        .is_tuple = false,
    } });
    const Loaded = @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &result: {
            var fields: [module_count]Type.StructField = undefined;
            for (&fields, module_types) |*field, Module| {
                field.* = .{
                    .name = @typeName(Module),
                    .type = bool,
                    .default_value = &false,
                    .is_comptime = false,
                    .alignment = 0,
                };
            }
            break :result fields;
        },
        .decls = &[_]Type.Declaration{},
        .is_tuple = false,
    } });

    return struct {
        modules: Modules,

        const Self = @This();

        pub fn init(init_modules: anytype) Self {
            var module_map: Modules = undefined;
            comptime var loaded = Loaded{};
            inline for (init_modules) |module| {
                @field(module_map, @typeName(@TypeOf(module))) = module;
                @field(loaded, @typeName(@TypeOf(module))) = true;
            }
            inline for (std.meta.fields(Loaded)) |field| {
                if (!@field(loaded, field.name)) {
                    @compileError(std.fmt.comptimePrint("Module `{s}` wasn't loaded", .{field.name}));
                }
            }

            return Self{ .modules = module_map };
        }

        pub fn get_module(self: *Self, comptime M: type) *M {
            const module_name = @typeName(M);
            if (@hasField(Modules, module_name)) {
                return @as(*M, &@field(self.modules, module_name));
            }
            @compileError(std.fmt.comptimePrint("Failed to find module `{s}`", .{module_name}));
        }
        pub fn invoke(self: *Self, comptime function_name: []const u8, args: anytype) void {
            inline for (meta.fields(Modules)) |module| {
                const Module = module.type;
                if (meta.hasFn(Module, function_name)) {
                    const ArgTypes = .{ *Module, null } ++ comptime arg_types: {
                        var arr: [args.len]?type = undefined;
                        for (&arr, meta.fields(@TypeOf(args))) |*arg_type, field| {
                            arg_type.* = field.type;
                        }
                        break :arg_types arr;
                    };
                    const ParamTypes = comptime arg_types: {
                        const params = @typeInfo(@TypeOf(@field(Module, function_name))).Fn.params;
                        var arr: [params.len]?type = undefined;
                        for (&arr, params) |*arg_type, field| {
                            arg_type.* = field.type;
                        }
                        break :arg_types arr;
                    };

                    if (comptime std.mem.eql(?type, &ArgTypes, &ParamTypes)) {
                        const module_value = &@field(self.modules, module.name);
                        @call(.auto, @field(Module, function_name), .{ module_value, self } ++ args);
                    }
                }
            }
        }
        pub fn require_modules(comptime current_module: type, comptime required_modules: []const type) void {
            comptime {
                for (required_modules) |module| {
                    if (!@hasField(Modules, @typeName(module))) {
                        @compileError(std.fmt.comptimePrint("Module `{s}` requires module `{s}` but it wasn't found", .{ @typeName(current_module), @typeName(module) }));
                    }
                }
            }
        }
    };
}
