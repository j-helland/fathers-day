# Overview

A simple Father's Day shader with a standalone runtime. Implemented with zig-gamedev and WGSL.

The entire message is a single 2D Signed Distance Function (SDF), composed of the following SDF primitives (courtesy of [Inigo Quilez](https://iquilezles.org/articles/distfunctions2d/)):
- Line segments
- Arcs
- Rings

# Running

If you happen to have an arm64-based macos system, you can run (obligatory disclaimer that you should always be careful running arbitrary binaries downloaded from the internet, run at your own risk, yada yada yada)
```bash
$ curl -L https://github.com/j-helland/fathers-day/releases/download/v0.0.0-macos-alpha/happy-fathers-day.tar.gz | tar -xz && ./happy-fathers-day
```

# Building From Source

The quickest way to build and run the app is
```bash
$ zig build run
```

To build the project for distribution, run
```bash
$ make release
```
which will generate a `release/happy-fathers-day.tar.gz`.
