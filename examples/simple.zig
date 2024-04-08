const std = @import("std");

const mods = @import("module-sys");

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
        mods.requireBefore(sys, Self, &.{ModuleA});
        const module_a = mods.get(sys, ModuleA);
        std.debug.print("DATA!!!!!!!!!!!!!!!! {any}\n", .{module_a.data});
    }
};

pub fn main() !void {
    const TestSystem = struct {
        ModuleA,
        ModuleB,
    };
    var test_system = TestSystem{
        ModuleA.new(),
        ModuleB{},
    };
    mods.invoke(&test_system, "start", .{});
}
