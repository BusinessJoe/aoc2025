# Advent of Code 2025
Solutions for Advent of Code 2025, written in Zig 0.15.2.

## Running 
The inputs are encrypted with `git-crypt` and will have to be decrypted or replaced with your own.

Run with `zig build run -- demo` or `zig build run -- real`.

## Profiling (note for myself)
```
zig build -Dtarget=x86_64-linux-gnu -Dcpu=x86_64 -Doptimize=ReleaseSafe
valgrind --tool=callgrind --dump-instr=yes --simulate-cache=yes --collect-jumps=yes <executable> [args...]
gprof2dot.py --format=callgrind --output=out.dot /path/to/callgrind.out
dot -Tpng out.dot -o graph.png
```

