pub const consts = @import("consts.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CandidateValue = struct { value: usize, isCandidate: bool };

pub const Cell = struct {
    value: ?usize,
    candidateValues: [consts.PUZZLE_MAXIMUM_VALUE]CandidateValue,
    _containedInGroups: [3]*ValidatableGroup, // Used when we set a value, and cascade that value change such that it is disqualified from all cells in the same row, column, and block.

    pub fn initEmpty(referencedBy: [3]*ValidatableGroup) Cell {
        return initFromValue(null, referencedBy);
    }

    pub fn initFromValue(value: ?usize, referencedBy: [3]*ValidatableGroup) Cell {
        var candidateValues = [_]CandidateValue{undefined} ** consts.PUZZLE_MAXIMUM_VALUE;

        for (1..consts.PUZZLE_MAXIMUM_VALUE + 1) |i| {
            candidateValues[i - 1] = CandidateValue{ .value = i, .isCandidate = value == null or value == i };
        }

        return Cell{ .value = value, .candidateValues = candidateValues, ._containedInGroups = referencedBy };
    }

    pub fn setValue(self: *Cell, value: usize) void {
        self.value = value;
        for (self._containedInGroups) |group| {
            group.eliminateCandidateFromAllCells(value);
        }
    }

    /// Use this to test that you can update all neighbours
    pub fn setAllNeighboursTo(self: *Cell, value: usize) void {
        for (self._containedInGroups) |group| {
            for (group.cells) |cell| {
                cell.value = value;
            }
        }
    }

    pub fn deinit(self: Cell) void {
        _ = self; // provide deinit for consistency
    }
};

pub const CellGrid = [consts.PUZZLE_DIMENTION][consts.PUZZLE_DIMENTION]Cell;

pub const ValidatableGroup = struct {
    identifier: usize,
    cells: [consts.PUZZLE_DIMENTION]*Cell,

    pub fn eliminateCandidateFromAllCells(self: *ValidatableGroup, value: usize) void {
        for (self.cells) |cell| {
            for (cell.candidateValues) |candidateValue| {
                if (candidateValue.value == value) {
                    candidateValue.isCandidate = false;
                    break;
                }
            }
        }
    }
};

pub const Views = struct {
    rows: [consts.PUZZLE_DIMENTION]ValidatableGroup,
    columns: [consts.PUZZLE_DIMENTION]ValidatableGroup,
    blocks: [consts.PUZZLE_DIMENTION]ValidatableGroup,
};

pub fn getCellBlockCoordinates(row: usize, column: usize, rowsPerBlock: usize, columnsPerBlock: usize) struct { number: usize, index: usize } {
    return .{
        .number = (row / rowsPerBlock) * rowsPerBlock + (column / columnsPerBlock),
        .index = (row % rowsPerBlock) * rowsPerBlock + (column % columnsPerBlock),
    };
}

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
            puzzle.views.rows[identifier] = ValidatableGroup{ .identifier = identifier, .cells = undefined }; //todo: Drop this identifier once we have a better understanding of what is going on
            puzzle.views.columns[identifier] = ValidatableGroup{ .identifier = identifier, .cells = undefined };
            puzzle.views.blocks[identifier] = ValidatableGroup{ .identifier = identifier, .cells = undefined };
        }

        // todo: I would like this to not have to be a second loop. The thing is that the columns collections aren't set in time in the first loop. We can make a choice to accept that later. For now, i'd like
        // rows and columns to look like the underlying grid, where possible, at least as I learn to interact with memory management
        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                puzzle.views.rows[row].cells[column] = &(puzzle.grid[row][column]);
                puzzle.views.columns[column].cells[row] = &(puzzle.grid[row][column]);

                const blockCoordinates = getCellBlockCoordinates(row, column, consts.PUZZLE_BLOCK_ROWCOUNT, consts.PUZZLE_BLOCK_COLUMNCOUNT);
                puzzle.views.blocks[blockCoordinates.number].cells[blockCoordinates.index] = &(puzzle.grid[row][column]);

                const containingGroups = [_]*ValidatableGroup{
                    &puzzle.views.rows[row],
                    &puzzle.views.columns[column],
                    &puzzle.views.blocks[blockCoordinates.number],
                };

                puzzle.grid[row][column] = Cell.initEmpty(containingGroups);
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
