pub const consts = @import("consts.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CandidateValue = struct { value: usize, isCandidate: bool };

pub const Cell = struct {
    _allocator: Allocator,
    _value: ?usize,
    _candidateValues: [consts.PUZZLE_MAXIMUM_VALUE]CandidateValue,
    _containedInGroups: [3]*ValidatableGroup, // Used when we set a value, and cascade that value change such that it is disqualified from all cells in the same row, column, and block.

    pub fn create(value: ?usize, row: *ValidatableGroup, column: *ValidatableGroup, block: *ValidatableGroup, allocator: Allocator) !*Cell {
        var cell = try allocator.create(Cell);

        var candidateValues = [_]CandidateValue{undefined} ** consts.PUZZLE_MAXIMUM_VALUE;

        for (1..consts.PUZZLE_MAXIMUM_VALUE + 1) |i| {
            candidateValues[i - 1] = CandidateValue{ .value = i, .isCandidate = value == null or value == i };
        }

        cell._allocator = allocator;
        cell._value = value;
        cell._containedInGroups = [3]*ValidatableGroup{ row, column, block };
        cell._candidateValues = candidateValues;

        return cell;
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
        self._candidateValues[value - 1].isCandidate = false; // Note that value is 1- based, while index is 0- based;
    }

    /// Use this to test that you can update all neighbours
    pub fn setAllNeighboursTo(self: *Cell, value: usize) void {
        for (self._containedInGroups) |group| {
            for (group.cells) |cell| {
                cell._value = value;
            }
        }
    }

    pub fn destroy(self: *Cell) void {
        self._allocator.destroy(self);
    }
};

pub const CellGrid = [consts.PUZZLE_DIMENTION][consts.PUZZLE_DIMENTION]*Cell;

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

    // pub fn createFromValues(allocator: Allocator) !*SudokuPuzzle {
    //     var puzzle = try createWithoutCells(allocator);
    //     errdefer {
    //         allocator.destroy(puzzle);
    //     }

    //     return puzzle;
    // }

    fn createEmpty(allocator: Allocator) !*SudokuPuzzle {
        var puzzle = try allocator.create(SudokuPuzzle);
        errdefer {
            allocator.destroy(puzzle);
        }

        puzzle._allocator = allocator;
        for (0..consts.PUZZLE_MAXIMUM_VALUE) |identifier| {
            puzzle.views.rows[identifier] = ValidatableGroup{ .identifier = identifier, .cells = undefined };
            puzzle.views.columns[identifier] = ValidatableGroup{ .identifier = identifier, .cells = undefined };
            puzzle.views.blocks[identifier] = ValidatableGroup{ .identifier = identifier, .cells = undefined };
        }

        return puzzle;
    }

    pub fn create(allocator: Allocator) !*SudokuPuzzle {
        var puzzle = try createEmpty(allocator);
        errdefer {
            allocator.destroy(puzzle);
        }

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                const blockCoordinates = getCellBlockCoordinates(row, column, consts.PUZZLE_BLOCK_ROWCOUNT, consts.PUZZLE_BLOCK_COLUMNCOUNT);

                const cell = try Cell.create(
                    null,
                    &puzzle.views.rows[row],
                    &puzzle.views.columns[column],
                    &puzzle.views.blocks[blockCoordinates.number],
                    allocator,
                );
                puzzle.grid[row][column] = cell;

                puzzle.views.rows[row].cells[column] = puzzle.grid[row][column];
                puzzle.views.columns[column].cells[row] = puzzle.grid[row][column];
                puzzle.views.blocks[blockCoordinates.number].cells[blockCoordinates.index] = puzzle.grid[row][column];
            }
        }
        return puzzle;
    }

    pub fn destroy(self: *SudokuPuzzle) void {
        for (self.grid) |cellRow| {
            for (cellRow) |cell| {
                cell.destroy();
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
