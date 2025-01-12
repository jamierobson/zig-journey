# zig-journey

A repository that journals my initial explorations into [The Zig Programming Language](https://ziglang.org). 

# Installing
I'll be using VS Code on Windows, so here's what I did to install everything.

```
choco install zig -y
choco install vscode -y
code --install-extension ziglang.vscode-zig
```

Getting the first app running
```
mkdir your:\\folder
cd your:\\folder
zig init
zig build run
zig build test
```

After doing this, I can run `zig` in the cli. Easy!

# Explorations
`zig init` creates both a `main.zig` which creates an executable, and `root.zig`, which creates a library.

## Initialization

It looks like I have taken some time to understand that creating views, grid, cells and so on in the init function, that they are created on the stack and released at the end of scope. This means that I was looking at pointers to essentially freed memory. Oops!

The below is the flawed implementation

```
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
```

Below, using the `allocator.create` to make sure that the initialized resources live beyond the scope of the `init` function
```
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
```

# References
- [Setting up VSCode for Zig](vhttps://zig.news/jarredsumner/setting-up-visual-studio-code-for-writing-zig-kcj)
- [Getting started with Zig](https://ziglang.org/learn/getting-started/)