const std = @import("std");
const core = @import("core.zig"); // todo: There must be better than this?
const consts = @import("consts.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const cell = core.Cell.initFromValue(3, allocator);
    const puzzle = core.SudokuPuzzle.initEmpty(allocator);

    std.debug.print("cell was created with value {any} \n", .{cell.value});

    for (0..consts.PUZZLE_MAXIMUM_VALUE - 1) |i| {
        std.debug.print("\n", .{});

        for (0..consts.PUZZLE_MAXIMUM_VALUE - 1) |j| {
            std.debug.print("| {} |", .{puzzle.grid[i][j].value orelse 0});
        }
    }
}
