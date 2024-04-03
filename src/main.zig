const std = @import("std");

const module_sys = @import("module-sys");

const ModuleSystem = module_sys.ModuleSystem;
const module = module_sys.module;
const invoke = module_sys.module;

const ModuleA = struct {
    data: u64,

    const Self = @This();
    pub fn init(sys: anytype) Self {
        _ = sys;
        return Self{
            .data = 69,
        };
    }

    pub fn start(self: *Self, sys: anytype) void {
        _ = self;
        _ = sys;
        std.debug.print("ModuleA STARTED\n", .{});
    }
};

const ModuleB = struct {
    const Self = @This();
    pub fn init(sys: anytype) Self {
        const module_a = module(sys, ModuleA);
        std.debug.print("DATA!!!!!!!!!!!!!!!! {any}\n", .{module_a.data});
        return Self{};
    }
};

pub fn main() !void {
    var sys = ModuleSystem(&.{ ModuleA, ModuleB }).init();
    sys.invoke("start", .{});
}
