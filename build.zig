const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addModule("mimalloc", .{
        .root_source_file = b.path("src/mimalloc.zig"),
        .link_libc = true
    });
    
    // mimalloc C library
    const mimalloc = b.dependency("mimalloc_c", .{});

    lib.addIncludePath(mimalloc.path("include"));

    // macOS SDK for cross-compilation
    const macos_sdk = b.dependency("macos_sdk", .{});

    // Add macOS SDK headers if applicable
    if (target.result.os.tag == .macos) {
        lib.addSystemIncludePath(macos_sdk.path("include"));
    }

    var c_flags = std.ArrayList([]const u8).init(b.allocator);
    if (optimize != .Debug) {
        c_flags.append("-DNDEBUG=1") catch unreachable;
        c_flags.append("-DMI_SECURE=0") catch unreachable;
        c_flags.append("-DMI_STAT=0") catch unreachable;
    }

    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        "src/alloc.c",
        "src/alloc-aligned.c",
        "src/page.c",
        "src/heap.c",
        "src/random.c",
        "src/options.c",
        "src/bitmap.c",
        "src/os.c",
        "src/init.c",
        "src/segment.c",
        "src/segment-map.c",
        "src/arena.c",
        "src/stats.c",
        "src/prim/prim.c",
        "src/libc.c",
    }) catch unreachable;

    for (sources.items) |src| {
        lib.addCSourceFile(.{
            .file = mimalloc.path(src),
            .flags = c_flags.items,
        });
    }

    if (target.result.os.tag != .windows) {
        lib.addCSourceFile(.{
            .file = mimalloc.path("src/alloc-posix.c"),
            .flags = c_flags.items,
        });
    }

    // Tests
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.root_module.addImport("mimalloc", lib);
    lib_unit_tests.linkLibC();

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}