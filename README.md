# mimalloc.zig

A simple implementation of Zig's `std.mem.Allocator` interface over the excellent [mimalloc](https://github.com/microsoft/mimalloc) by Microsoft.

## Usage

```
const mimalloc = @import("mimalloc").Allocator{};
const allocator = mimalloc.allocator();

// Use `allocator` here...
```