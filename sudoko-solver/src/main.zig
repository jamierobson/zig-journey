const std = @import("std");
const core = @import("core");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    // var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    // defer arena.deinit();

    try runTest(gpa.allocator());
}

fn runTest(allocator: std.mem.Allocator) !void {
    var puzzle = try core.SudokuPuzzle.create(allocator);
    defer puzzle.destroy();

    puzzle.grid[1][1].setValue(5);
    puzzle.views.blocks[4].cells[1].setValue(2);
    puzzle.views.columns[0].cells[0].*._value = 1;
    puzzle.views.rows[8].cells[8].*._value = 2;

    puzzle.grid[5][5].setAllNeighboursTo(4);
    puzzle.grid[0][0].setAllNeighboursTo(3);
    puzzle.grid[8][8].setAllNeighboursTo(3);

    std.debug.print("Unholy monster of an amalgamation of all values from grid, row, and then column \n \n", .{});

    for (0..core.consts.PUZZLE_MAXIMUM_VALUE) |row| {
        std.debug.print("\n", .{});

        for (0..core.consts.PUZZLE_MAXIMUM_VALUE) |column| {
            const groups = core.getCellGroupReferences(row, column);

            const rowView = &puzzle.views.rows[row];
            const columnView = &puzzle.views.columns[column];
            const blockView = &puzzle.views.blocks[groups.block.number];
            std.debug.print("| G:{any}, R{any}: {any}, C{any}: {any}, B{any}: {any} |", .{
                puzzle.grid[row][column].getValue() orelse 0,
                rowView.identifier,
                rowView.cells[column].getValue() orelse 0,
                columnView.identifier,
                columnView.cells[row].getValue() orelse 0,
                blockView.identifier,
                blockView.cells[groups.block.index].getValue() orelse 0,
            });
        }
    }
}
