const std = @import("std");
const core = @import("core.zig"); // todo: There must be better than this?
const consts = @import("consts.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var puzzle = try core.SudokuPuzzle.create(arena.allocator());
    defer puzzle.destroy(arena.allocator());

    puzzle.grid[1][1].value = 5;
    puzzle.views.columns[0].cells[0].*.value = 1;
    puzzle.views.rows[8].cells[8].*.value = 2;

    puzzle.grid[5][5].setAllNeighboursTo(4);

    std.debug.print("Unholy monster of an amalgamation of all values from grid, row, and then column \n \n", .{});

    for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
        std.debug.print("\n", .{});

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
            const rowView = &puzzle.views.rows[row];
            const columnView = &puzzle.views.columns[column];
            std.debug.print("| Grid: {any}, R{any}: {any}, C{any}: {any} |", .{ puzzle.grid[row][column].value orelse 0, rowView.identifier, rowView.cells[column].value orelse 0, columnView.identifier, columnView.cells[row].value orelse 0 });
        }
    }
}
