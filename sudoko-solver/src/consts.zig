pub const PUZZLE_BLOCK_ROWCOUNT: comptime_int = 3;
pub const PUZZLE_BLOCK_COLUMNCOUNT: comptime_int = 3;

pub const PUZZLE_DIMENTION: comptime_int = PUZZLE_BLOCK_ROWCOUNT * PUZZLE_BLOCK_COLUMNCOUNT;
pub const PUZZLE_TOTAL_CELL_COUNT: comptime_int = PUZZLE_DIMENTION * PUZZLE_DIMENTION;
pub const PUZZLE_MAXIMUM_VALUE: comptime_int = PUZZLE_DIMENTION;
