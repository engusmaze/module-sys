const std = @import("std");

pub const ModuleSystem = @import("module-sys.zig").ModuleSystem;

pub fn module(sys: anytype, comptime M: type) *M {
    return sys.get_module(M);
}
pub fn invoke(sys: anytype, comptime function_name: []const u8, args: anytype) void {
    sys.invoke(function_name, args);
}
pub fn require_modules(sys: anytype, comptime current_module: type, comptime required_modules: []const type) void {
    std.meta.Child(@TypeOf(sys)).require_modules(current_module, required_modules);
}
