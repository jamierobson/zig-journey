const std = @import("std");
const core = @import("core.zig"); // todo: There must be better than this?

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const cell = core.Cell.initFromValue(3, allocator);

    std.debug.print("cell was created with value {any}", .{cell.value});
}
