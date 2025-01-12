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

    pub fn create(allocator: Allocator) !*SudokuPuzzle {
        var puzzle = try allocator.create(SudokuPuzzle);
        errdefer {
            allocator.destroy(puzzle);
        }

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

    pub fn destroy(self: *SudokuPuzzle, allocator: Allocator) void {
        for (self.grid) |cellRow| {
            for (cellRow) |cell| {
                cell.deinit();
            }
        }
        allocator.destroy(self);
    }
};
