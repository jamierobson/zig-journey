const std = @import("std");
const core = @import("core");

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
    puzzle.grid[0][0].setAllNeighboursTo(3);
    puzzle.grid[8][8].setAllNeighboursTo(3);

    std.debug.print("Unholy monster of an amalgamation of all values from grid, row, and then column \n \n", .{});

    for (0..core.consts.PUZZLE_MAXIMUM_VALUE) |row| {
        std.debug.print("\n", .{});

        for (0..core.consts.PUZZLE_MAXIMUM_VALUE) |column| {
            const rowView = &puzzle.views.rows[row];
            const columnView = &puzzle.views.columns[column];

            const blockCoordinates = core.getCellBlockCoordinates(row, column, core.consts.PUZZLE_BLOCK_ROWCOUNT, core.consts.PUZZLE_BLOCK_COLUMNCOUNT);
            const blockView = &puzzle.views.blocks[blockCoordinates.number];
            std.debug.print("| G:{any}, R{any}: {any}, C{any}: {any}, B{any}: {any} |", .{
                puzzle.grid[row][column].value orelse 0,
                rowView.identifier,
                rowView.cells[column].value orelse 0,
                columnView.identifier,
                columnView.cells[row].value orelse 0,
                blockView.identifier,
                blockView.cells[blockCoordinates.index].value orelse 0,
            });
        }
    }
}
