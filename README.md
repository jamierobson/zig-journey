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

# References
- [Setting up VSCode for Zig](vhttps://zig.news/jarredsumner/setting-up-visual-studio-code-for-writing-zig-kcj)
- [Getting started with Zig](https://ziglang.org/learn/getting-started/)