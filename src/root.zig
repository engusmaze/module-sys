pub const ModuleSystem = @import("module-sys.zig").ModuleSystem;

pub fn module(sys: anytype, comptime M: type) *M {
    return sys.get_module(M);
}
pub fn invoke(sys: anytype, comptime function_name: []const u8, args: anytype) void {
    return sys.invoke(function_name, args);
}
