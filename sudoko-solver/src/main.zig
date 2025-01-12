const std = @import("std");
const core = @import("core.zig"); // todo: There must be better than this?
const consts = @import("consts.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var puzzle = try core.SudokuPuzzle.initEmpty(allocator);
    // defer puzzle.deinit(allocator);
    defer _ = gpa.deinit();

    puzzle.grid[1][1].value = 5;
    puzzle.views.columns[0].members[0].*.value = 1;
    puzzle.views.rows[8].members[8].*.value = 2;

    std.debug.print("Unholy monster of an amalgamation of all values from grid, row, and then column \n \n", .{});

    for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
        std.debug.print("\n", .{});

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
            const rowView = &puzzle.views.rows[row];
            const columnView = &puzzle.views.columns[column];
            std.debug.print("| Grid: {any}, R{any}: {any}, C{any}: {any} |", .{ puzzle.grid[row][column].value orelse 0, rowView.identifier, rowView.members[column].value orelse 0, columnView.identifier, columnView.members[row].value orelse 0 });
        }
    }

    // // try use after free
    // puzzle.deinit();
    // _ = gpa.deinit();

    // puzzle.grid[3][3].value = 8;
    // std.debug.print(" \n \n Try use after free. 3, 3 = {any} \n ", .{puzzle.grid[3][3].value}); // interesting that this works just fine.

    // // try double free
    // puzzle.deinit();
    // _ = gpa.deinit();
}
