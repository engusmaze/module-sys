const std = @import("std");

const module_sys = @import("module-sys");

const ModuleSystem = module_sys.ModuleSystem;
const module = module_sys.module;
const invoke = module_sys.invoke;
const require_modules = module_sys.require_modules;

// pub const std_options: std.Options = .{
//     .log_level = .info,
// };

const ModuleA = struct {
    data: u64,

    const Self = @This();
    pub fn new() Self {
        return Self{
            .data = 69,
        };
    }

    pub fn start(self: *Self, sys: anytype) void {
        _ = self;
        _ = sys;
        std.debug.print("ModuleA started\n", .{});
    }
};

const ModuleB = struct {
    const Self = @This();
    pub fn start(self: *Self, sys: anytype) void {
        _ = self;
        require_modules(sys, Self, &.{ModuleA});
        const module_a = module(sys, ModuleA);
        std.debug.print("DATA!!!!!!!!!!!!!!!! {any}\n", .{module_a.data});
    }
};

pub fn main() !void {
    const TestSystem = ModuleSystem(.{
        ModuleA,
        ModuleB,
    });
    var test_system = TestSystem.init(.{
        ModuleA.new(),
        ModuleB{},
    });
    test_system.invoke("start", .{});
}
