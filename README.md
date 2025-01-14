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
## Structure
`zig init` creates both a `main.zig` which creates an executable, and `root.zig`, which creates a library.

## Accessibility
It seems like a function can be declared private or public, a struct, and so on. Fields on that struct however seem to be always public. From what I'm reading, prefixing with underscore seems to be a preferred way to indicate that we prefer the member being private.

## Imports


Without defining a module, we need to import from specific zig files, as such:
```
const core = @import("core.zig"); // todo: There must be better than this?
const consts = @import("consts.zig");
```

However, this feels wonky. Better would be an import that describes our grouped functionality. Hence, modules. In this case, in build.zig, we define the module and add as an import to the executable
```
    const core_mod = b.addModule("core", .{ .root_source_file = b.path("src/core.zig"), .target = target, .optimize = optimize });
    exe.root_module.addImport("core", core_mod);
```

Note however that we replaced both `core.zig`, and `consts.zig`. This seems to be because `core.zig` already imports `consts.zig`, and so `main` was complaining that `consts` was imported twice. Changing the visibility of `consts` from `core`, we have also included `consts` in our `core` module, accessible as `core.consts`. Nice 👍.


## Initialization

It looks like I have taken some time to understand that creating views, grid, cells and so on in the init function, that they are created on the stack and released at the end of scope. This means that I was looking at pointers to essentially freed memory. Oops!

The below is the flawed implementation

```
    pub fn initEmpty_flawed(allocator: Allocator) SudokuPuzzle {

        var views = Views{ .rows = undefined, .columns = undefined, .blocks = undefined };
        var grid: CellGrid = undefined;

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            // Set up the views
        }

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                grid[row][column] = Cell.initEmpty(allocator);
                // Set up the pointers
            }
        }

        return SudokuPuzzle{ .grid = grid, .views = views };
    }
```

Below, using the `allocator.create` to make sure that the initialized resources live beyond the scope of the `init` function. Note how `allocator.Create(T)` returns a `*T`.
```
 pub fn initEmpty(allocator: Allocator) !*SudokuPuzzle {
        var puzzle = try allocator.create(SudokuPuzzle);
        errdefer allocator.destroy(puzzle);

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            // Set up the views
        }

        for (0..consts.PUZZLE_MAXIMUM_VALUE) |row| {
            for (0..consts.PUZZLE_MAXIMUM_VALUE) |column| {
                puzzle.grid[row][column] = Cell.initEmpty(allocator);
                // Set up the pointers
            }
        }
        return puzzle;
    }
```

# References
- [Setting up VSCode for Zig](vhttps://zig.news/jarredsumner/setting-up-visual-studio-code-for-writing-zig-kcj)
- [Getting started with Zig](https://ziglang.org/learn/getting-started/)