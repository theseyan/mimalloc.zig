const std = @import("std");
const testing = std.testing;
const mimalloc = @import("mimalloc").Allocator{};
const allocator = mimalloc.allocator();

test "basic allocation and deallocation" {
    // Test simple allocation
    const slice = try allocator.alloc(u8, 100);
    defer allocator.free(slice);
    try testing.expectEqual(@as(usize, 100), slice.len);

    // Fill with data to ensure memory is writable
    @memset(slice, 0xAA);
    for (slice) |byte| {
        try testing.expectEqual(@as(u8, 0xAA), byte);
    }
}

test "zero-sized allocation" {
    // Test allocation of zero bytes
    const empty = try allocator.alloc(u8, 0);
    defer allocator.free(empty);
    try testing.expectEqual(@as(usize, 0), empty.len);
}

test "realloc behavior" {
    // Initial allocation
    var slice = try allocator.alloc(u8, 50);
    defer allocator.free(slice);

    // Fill with pattern
    @memset(slice, 0xBB);

    // Grow
    slice = try allocator.realloc(slice, 100);
    try testing.expectEqual(@as(usize, 100), slice.len);

    // Verify original data is preserved
    for (slice[0..50]) |byte| {
        try testing.expectEqual(@as(u8, 0xBB), byte);
    }

    // Shrink
    slice = try allocator.realloc(slice, 25);
    try testing.expectEqual(@as(usize, 25), slice.len);

    // Verify data is still preserved
    for (slice) |byte| {
        try testing.expectEqual(@as(u8, 0xBB), byte);
    }
}

test "multiple allocations" {
    var slices = std.ArrayList([]u8).init(testing.allocator);
    defer {
        for (slices.items) |slice| {
            allocator.free(slice);
        }
        slices.deinit();
    }

    // Perform multiple allocations of varying sizes
    const sizes = [_]usize{ 8, 16, 32, 64, 128, 256, 512, 1024 };
    for (sizes) |size| {
        const slice = try allocator.alloc(u8, size);
        try slices.append(slice);
        @memset(slice, @as(u8, @truncate(size % 256)));
    }

    // Verify all allocations
    for (slices.items, 0..) |slice, i| {
        try testing.expectEqual(sizes[i], slice.len);
        for (slice) |byte| {
            try testing.expectEqual(@as(u8, @truncate(sizes[i] % 256)), byte);
        }
    }
}

test "alignment requirements" {
    const AlignedStruct = struct {
        a: u32 align(16),
        b: u64,
    };

    var slice = try allocator.alloc(AlignedStruct, 1);
    defer allocator.free(slice);

    // Verify alignment
    try testing.expectEqual(@as(usize, 0), @intFromPtr(&slice[0]) & 15);
}