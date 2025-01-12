const consts = @import("consts.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Cell = struct {
    value: ?usize,
    discountedValues: std.ArrayList(usize),

    pub fn initEmpty(allocator: Allocator) Cell {
        return initFromValue(null, allocator);
    }

    pub fn initFromValue(value: ?usize, allocator: Allocator) Cell {
        return Cell{ .value = value, .discountedValues = std.ArrayList(usize).init(allocator) };
    }

    pub fn deinit(self: Cell) void {
        self.discountedValues.deinit();
    }
};

pub const CellGrid = [consts.PUZZLE_DIMENTION][consts.PUZZLE_DIMENTION]Cell;

pub const ValidatableGroup = struct {
    identifier: usize,
    members: [consts.PUZZLE_DIMENTION]*Cell,
};

pub const Views = struct {
    rows: [consts.PUZZLE_DIMENTION]ValidatableGroup,
    columns: [consts.PUZZLE_DIMENTION]ValidatableGroup,
    blocks: [consts.PUZZLE_DIMENTION]ValidatableGroup,
};

pub const SudokuPuzzle = struct {
    grid: CellGrid,
    views: Views,

    pub fn initEmpty(allocator: Allocator) !*SudokuPuzzle {
        var puzzle = try allocator.create(SudokuPuzzle);
        errdefer allocator.destroy(puzzle);

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            const identifier = row; // for reusing the iteration
            puzzle.views.rows[identifier] = ValidatableGroup{ .identifier = identifier, .members = undefined }; //todo: Drop this identifier once we have a better understanding of what is going on
            puzzle.views.columns[identifier] = ValidatableGroup{ .identifier = identifier, .members = undefined };
            puzzle.views.blocks[identifier] = ValidatableGroup{ .identifier = identifier, .members = undefined };
        }

        // todo: I would like this to not have to be a second loop. The thing is that the columns collections aren't set in time in the first loop. We can make a choice to accept that later. For now, i'd like
        // rows and columns to look like the underlying grid, where possible, at least as I learn to interact with memory management
        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                puzzle.grid[row][column] = Cell.initEmpty(allocator);
                puzzle.views.rows[row].members[column] = &(puzzle.grid[row][column]);
                puzzle.views.columns[column].members[row] = &(puzzle.grid[row][column]);
                puzzle.views.blocks[row].members[column] = &(puzzle.grid[row][column]);
            }
        }
        return puzzle;
    }

    pub fn deinit(self: SudokuPuzzle, allocator: Allocator) void {
        for (self.grid) |row| {
            for (row) |cell| {
                cell.deinit();
            }
        }

        allocator.destroy(self);
    }

    pub fn initEmpty_flawed(allocator: Allocator) SudokuPuzzle {

        // Keeping this here as a comparison of something I learned.

        var views = Views{ .rows = undefined, .columns = undefined, .blocks = undefined };

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            const identifier = row; // for reusing the iteration
            views.rows[identifier] = ValidatableGroup{ .identifier = identifier, .members = undefined }; //todo: I can probably drop that identifier now. It's all identifiable by position in the collections
            views.columns[identifier] = ValidatableGroup{ .identifier = identifier, .members = undefined };
            views.blocks[identifier] = ValidatableGroup{ .identifier = identifier, .members = undefined };
        }

        // todo: I would like this to not have to be a second loop. The thing is that the columns collections aren't set in time in the first loop. We can make a choice to accept that later. For now, i'd like
        // rows and columns to look like the underlying grid, where possible, at least as I learn to interact with memory management

        // I'm getting stuck here. It doesn't look like the pointer setup I have alters values correctly, or reads them so either.
        // The goal is that each row, column, block, can use the cell, for example, when it works out if there are any duplicates among the cells in that group. Recalculating those groups all the time will be costly
        // and I want to explore making sure that all of the memory is correctly accounted for.

        var grid: CellGrid = undefined;

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                grid[row][column] = Cell.initEmpty(allocator);
                views.rows[row].members[column] = &grid[row][column];
                views.columns[column].members[row] = &grid[row][column];
                views.blocks[row].members[column] = &grid[row][column];
            }
        }

        return SudokuPuzzle{ .grid = grid, .views = views };
    }
};
