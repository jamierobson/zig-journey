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

    pub fn deinit(self: *Cell) void {
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

    pub fn initEmpty(allocator: Allocator) SudokuPuzzle {
        var grid: CellGrid = undefined;
        var views = Views{ .rows = undefined, .columns = undefined, .blocks = undefined };

        for (0..consts.PUZZLE_MAXIMUM_VALUE - 1) |i| {
            views.rows[i] = ValidatableGroup{ .identifier = i, .members = undefined };
            views.columns[i] = ValidatableGroup{ .identifier = i, .members = undefined };
            views.blocks[i] = ValidatableGroup{ .identifier = i, .members = undefined };
        }

        for (0..consts.PUZZLE_MAXIMUM_VALUE - 1) |i| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE - 1) |j| {
                var cell = Cell.initEmpty(allocator);
                grid[i][j] = cell;
                views.rows[i].members[j] = &cell;
                views.columns[j].members[i] = &cell;
                views.blocks[i].members[j] = &cell;
            }
        }

        return SudokuPuzzle{ .grid = grid, .views = views };
    }
};
