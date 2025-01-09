const consts = @import("consts.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Cell = struct {
    value: ?u8,
    discountedValues: std.ArrayList(u8),

    pub fn initEmpty(allocator: Allocator) Cell {
        return initFromValue(null, allocator);
    }

    pub fn initFromValue(value: ?u8, allocator: Allocator) Cell {
        return Cell{ .value = value, .discountedValues = std.ArrayList(u8).init(allocator) };
    }

    pub fn deinit(self: *Cell) void {
        self.discountedValues.deinit();
    }
};

pub const CellGrid = [consts.PUZZLE_DIMENTION][consts.PUZZLE_DIMENTION]Cell;

pub const ValidatableGroup = [consts.PUZZLE_DIMENTION]Cell;

pub const Views = struct {
    rows: [consts.PUZZLE_DIMENTION]*Cell,
    columns: [consts.PUZZLE_DIMENTION]*Cell,
    blocks: [consts.PUZZLE_DIMENTION]*Cell,
};

pub const SudokuPuzzle = struct {
    grid: CellGrid,
    views: Views,
};
