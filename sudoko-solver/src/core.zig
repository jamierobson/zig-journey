pub const consts = @import("consts.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CandidateValue = struct { value: usize, isCandidate: bool };

pub const Cell = struct {
    _value: ?usize,
    candidateValues: [consts.PUZZLE_MAXIMUM_VALUE]CandidateValue,
    _containedInGroups: [3]*ValidatableGroup, // Used when we set a value, and cascade that value change such that it is disqualified from all cells in the same row, column, and block.

    pub fn initEmpty(referencedBy: [3]*ValidatableGroup) Cell {
        return initFromValue(null, referencedBy);
    }

    pub fn autocompleteValueIfOnlyOneCanndidateRemaining(self: *Cell) void {
        if (self._value != null) {
            return;
        }

        var lastConsideredCandidate: ?usize = null;

        for (self.candidateValues) |candidate| {
            if (candidate.isCandidate) {
                if (lastConsideredCandidate != null) {
                    return; // Second candidate value found, so we can't reliably autocomplete
                }
                lastConsideredCandidate = candidate.value;
            }
        }

        self._value = lastConsideredCandidate;
    }

    pub fn initFromValue(value: ?usize, referencedBy: [3]*ValidatableGroup) Cell {
        var candidateValues = [_]CandidateValue{undefined} ** consts.PUZZLE_MAXIMUM_VALUE;

        for (1..consts.PUZZLE_MAXIMUM_VALUE + 1) |i| {
            candidateValues[i - 1] = CandidateValue{ .value = i, .isCandidate = value == null or value == i };
        }

        return Cell{ ._value = value, .candidateValues = candidateValues, ._containedInGroups = referencedBy };
    }

    pub fn getValue(self: *Cell) ?usize {
        return self._value;
    }

    pub fn setValue(self: *Cell, value: usize) void {
        self._value = value;
        for (self._containedInGroups) |group| {
            group.eliminateCandidateFromAllCells(value);
        }
    }

    pub fn disqualifyValue(self: *Cell, value: usize) void {
        self.candidateValues[value - 1].isCandidate = false; // Note that value is 1- based, while index is 0- based;
    }

    /// Use this to test that you can update all neighbours
    pub fn setAllNeighboursTo(self: *Cell, value: usize) void {
        for (self._containedInGroups) |group| {
            for (group.cells) |cell| {
                cell._value = value;
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
            cell.disqualifyValue(value);
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
    _allocator: Allocator,
    grid: CellGrid,
    views: Views,

    pub fn create(allocator: Allocator) !*SudokuPuzzle {
        var puzzle = try allocator.create(SudokuPuzzle);
        errdefer {
            allocator.destroy(puzzle);
        }

        puzzle._allocator = allocator;

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            const identifier = row; // for reusing the iteration
            puzzle.views.rows[identifier] = ValidatableGroup{ .identifier = identifier, .cells = undefined };
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

    pub fn destroy(self: *SudokuPuzzle) void {
        for (self.grid) |cellRow| {
            for (cellRow) |cell| {
                cell.deinit();
            }
        }
        self._allocator.destroy(self);
    }
};

test "autocomplete cell when single candidate" {
    var cell = Cell.initEmpty([_]*ValidatableGroup{undefined} ** 3);

    const expectedValue = 6;

    for (&cell.candidateValues) |*candidate| {
        if (candidate.value != expectedValue) {
            candidate.isCandidate = false;
        }
    }

    cell.autocompleteValueIfOnlyOneCanndidateRemaining();

    try std.testing.expectEqual(expectedValue, cell._value);
}

test "autocomplete cell when more than one candidate leaves value as null" {
    var cell = Cell.initEmpty([_]*ValidatableGroup{undefined} ** 3);
    cell.candidateValues[0].isCandidate = false;
    cell.candidateValues[1].isCandidate = false;
    cell.candidateValues[2].isCandidate = true;
    cell.candidateValues[3].isCandidate = true;

    cell.autocompleteValueIfOnlyOneCanndidateRemaining();

    try std.testing.expectEqual(cell._value, null);
}

test "autocomplete cell when value set does not alter value" {
    var cell = Cell.initEmpty([_]*ValidatableGroup{undefined} ** 3);

    const expectedValue = 3;
    const onlyRemainingCandidateValue = 6;

    for (&cell.candidateValues) |*candidate| {
        if (candidate.value != onlyRemainingCandidateValue) {
            candidate.isCandidate = false;
        }
    }

    cell._value = expectedValue;
    cell.autocompleteValueIfOnlyOneCanndidateRemaining();

    try std.testing.expectEqual(cell._value, expectedValue);
}

test "autocomplete cell when no valid candidates - this scenario needs considering" {
    // todo: This test is here as a reminder to consider this scenario, especially when we get to an attempt to brute force a solution
}
