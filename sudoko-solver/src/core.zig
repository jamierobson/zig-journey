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

pub const GroupReferences = struct { row: usize, column: usize, block: struct { number: usize, index: usize } };

pub fn getCellGroupReferences(row: usize, column: usize) GroupReferences {
    const rowsPerBlock = consts.PUZZLE_BLOCK_ROWCOUNT;
    const columnsPerBlock = consts.PUZZLE_BLOCK_COLUMNCOUNT;
    return .{
        .row = row,
        .column = column,
        .block = .{
            .number = (row / rowsPerBlock) * rowsPerBlock + (column / columnsPerBlock),
            .index = (row % rowsPerBlock) * rowsPerBlock + (column % columnsPerBlock),
        },
    };
}

pub const SudokuPuzzle = struct {
    _allocator: Allocator,
    grid: CellGrid,
    views: Views,

    pub fn createFromValues(values: [consts.PUZZLE_TOTAL_CELL_COUNT]?usize, allocator: Allocator) !*SudokuPuzzle {
        var puzzle = try createEmpty(allocator);
        errdefer {
            allocator.destroy(puzzle);
        }
        puzzle._allocator = allocator;
        var i: usize = 0;
        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                const cellGroupReferences = getCellGroupReferences(row, column);
                try createAndAssignCell(puzzle, values[i], cellGroupReferences, allocator);
                i += 1;
            }
        }
        return puzzle;
    }

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

    fn createAndAssignCell(puzzle: *SudokuPuzzle, value: ?usize, references: GroupReferences, allocator: Allocator) !void {
        const cell = try Cell.create(
            value,
            &puzzle.views.rows[references.row],
            &puzzle.views.columns[references.column],
            &puzzle.views.blocks[references.block.number],
            allocator,
        );

        puzzle.grid[references.row][references.column] = cell;
        puzzle.views.rows[references.row].cells[references.column] = cell;
        puzzle.views.columns[references.column].cells[references.row] = cell;
        puzzle.views.blocks[references.block.number].cells[references.block.index] = cell;
    }

    pub fn create(allocator: Allocator) !*SudokuPuzzle {
        const puzzle = try createEmpty(allocator);
        errdefer {
            allocator.destroy(puzzle);
        }

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                const cellGroupReferences = getCellGroupReferences(row, column);
                try createAndAssignCell(puzzle, null, cellGroupReferences, allocator);
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

test "can create empty sudoku from values" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const values = [_]?usize{null} ** consts.PUZZLE_TOTAL_CELL_COUNT;
    const puzzle = try SudokuPuzzle.createFromValues(values, gpa.allocator());

    for (0..consts.PUZZLE_MAXIMUM_VALUE) |i| {
        for (0..consts.PUZZLE_MAXIMUM_VALUE) |j| {
            try std.testing.expectEqual(null, puzzle.grid[i][j].getValue());
        }
    }
}

test "can create sudoku from with values" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const values = [_]?usize{null} ** consts.PUZZLE_TOTAL_CELL_COUNT;
    values[0] = 1;
    values[81] = 8;
    const puzzle = try SudokuPuzzle.createFromValues(values, gpa.allocator());

    try std.testing.expectEqual(1, puzzle.grid[0][0].getValue());
    try std.testing.expectEqual(8, puzzle.grid[8][8].getValue());
}

const ReferenceWithValue = struct {
    references: GroupReferences,
    value: usize,
    fn init(row: usize, column: usize, value: usize) ReferenceWithValue {
        return .{ .references = getCellGroupReferences(row, column), .value = value };
    }
};

test "rows, blocks, columns, are different" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const puzzle = try SudokuPuzzle.create(gpa.allocator());

    try std.testing.expect(&puzzle.views.blocks != &puzzle.views.rows);
    try std.testing.expect(&puzzle.views.blocks != &puzzle.views.columns);
    try std.testing.expect(&puzzle.views.rows != &puzzle.views.columns);

    std.debug.print("\n grid {*} \n blocks {*} \n rows {*} \n columns {*} \n", .{
        &puzzle.grid,
        &puzzle.views.blocks,
        &puzzle.views.rows,
        &puzzle.views.columns,
    });
}

test "rows, blocks, columns, all point at same data as the raw cell grid" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var puzzle = try SudokuPuzzle.create(gpa.allocator());

    const Test_1_1 = ReferenceWithValue.init(1, 1, 5);
    const Test_4_4 = ReferenceWithValue.init(4, 4, 4);
    const Test_6_0 = ReferenceWithValue.init(6, 0, 6);
    const Test_8_8 = ReferenceWithValue.init(8, 8, 2);
    const Test_0_7 = ReferenceWithValue.init(0, 7, 7);
    const Test_8_0 = ReferenceWithValue.init(8, 0, 3);

    puzzle.grid[Test_1_1.references.row][Test_1_1.references.column].setValue(Test_1_1.value);
    puzzle.grid[Test_4_4.references.row][Test_4_4.references.column].*.setValue(Test_4_4.value);
    puzzle.grid[Test_6_0.references.row][Test_6_0.references.column].*._value = Test_6_0.value;
    puzzle.views.blocks[Test_8_8.references.block.number].cells[Test_8_8.references.block.index].setValue(Test_8_8.value);
    puzzle.views.columns[Test_0_7.references.column].cells[Test_0_7.references.row].*._value = Test_0_7.value;
    puzzle.views.rows[Test_8_0.references.row].cells[Test_8_0.references.column]._value = Test_8_0.value;

    for ([_]ReferenceWithValue{ Test_1_1, Test_4_4, Test_6_0, Test_8_0, Test_8_8, Test_0_7 }) |testData| {
        try std.testing.expectEqual(testData.value, puzzle.grid[testData.references.row][testData.references.column].getValue());
        try std.testing.expectEqual(testData.value, puzzle.grid[testData.references.row][testData.references.column].*._value);
        try std.testing.expectEqual(testData.value, puzzle.views.rows[testData.references.row].cells[testData.references.column].getValue());
        try std.testing.expectEqual(testData.value, puzzle.views.columns[testData.references.column].cells[testData.references.row].getValue());
        try std.testing.expectEqual(testData.value, puzzle.views.blocks[testData.references.block.number].cells[testData.references.block.index].getValue());
    }
}
