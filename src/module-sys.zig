const std = @import("std");
const meta = std.meta;
const Type = std.builtin.Type;

pub fn ModuleSystem(comptime modules: []const type) type {
    const Modules = @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &result: {
            var fields: [modules.len]Type.StructField = undefined;
            for (&fields, modules) |*field, Module| {
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

    comptime var is_init = false;
    comptime var loaded = @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &result: {
            var fields: [modules.len]Type.StructField = undefined;
            for (&fields, modules) |*field, Module| {
                field.* = .{
                    .name = @typeName(Module),
                    .type = bool,
                    .default_value = &true,
                    .is_comptime = false,
                    .alignment = 0,
                };
            }
            break :result fields;
        },
        .decls = &[_]Type.Declaration{},
        .is_tuple = false,
    } }){};

    return struct {
        modules: Modules,

        const Self = @This();

        pub fn init() Self {
            if (is_init) {
                @compileError("ModuleSystem is already init");
            } else {
                is_init = true;

                var sys = Self{
                    .modules = undefined,
                };
                inline for (meta.fields(Modules)) |module| {
                    @field(sys.modules, module.name) = module.type.init(&sys);
                    @field(loaded, module.name) = true;
                }
                return sys;
            }
        }

        pub fn get_module(self: *Self, comptime M: type) *M {
            const module_name = @typeName(M);
            if (@hasField(Modules, module_name)) {
                if (@field(loaded, module_name)) {
                    return @as(*M, &@field(self.modules, module_name));
                }
                @compileError(std.fmt.comptimePrint("Module `{s}` was't yet loaded", .{module_name}));
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
                    // const ParamTypes = meta.ArgsTuple()
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
    };
}
