const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Create your main module
    const mod = b.addModule("open_l5", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // 2. Define the Executable
    const exe = b.addExecutable(.{
        .name = "open_l5",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "open_l5", .module = mod },
            },
        }),
    });

    // --- Dependencies (kept from your snippet) ---
    // webui
    const zig_webui = b.dependency("zig_webui", .{
        .target = target,
        .optimize = optimize,
        .enable_tls = false,
        .is_static = true,
    });
    exe.root_module.addImport("webui", zig_webui.module("webui"));

    // zalgebra
    const zalgebra = b.dependency("zalgebra", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zalgebra", zalgebra.module("zalgebra"));

    // cuda
    const cuda_obj = compileCuda(b, optimize);

    exe.step.dependOn(cuda_obj[0]);
    exe.addObjectFile(cuda_obj[1]);

    b.getInstallStep().dependOn(&b.addInstallFile(
        cuda_obj[1],
        b.pathJoin(&.{ "lib", "cuda", "cuda.o" }),
    ).step);

    const cuda_path = std.process.getEnvVarOwned(b.allocator, "CUDA_PATH") catch "/usr/local/cuda";

    exe.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{cuda_path}) });
    exe.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/lib64", .{cuda_path}) });
    exe.linkSystemLibrary("cuda");
    exe.linkSystemLibrary("cudart");
    exe.linkLibCpp(); // CUDA usually requires LibCpp

    // cuda

    b.installArtifact(exe);

    // --- Run and Test Steps (Standard) ---
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const mod_tests = b.addTest(.{ .root_module = mod });
    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}

// Function returns a LazyPath. This is the "future" path of the compiled object.
fn compileCuda(b: *std.Build, optimize: std.builtin.OptimizeMode) struct { *std.Build.Step, std.Build.LazyPath } {
    const source_path = b.path(b.pathJoin(&.{ "src", "cuda", "add.cu" }));

    // 1. Detect GPU Architecture (Config time)
    // We wrap this in a catch so the build doesn't crash on non-NVIDIA machines.
    // Ideally, this should be a `b.option` passed by the user like -Dgpu_arch=sm_80
    const gpu_arch_str = getGpuArch(b) catch "75";

    // 2. Setup NVCC command
    const nvcc = b.addSystemCommand(&.{"nvcc"});

    // Input file
    nvcc.addArg("-c");
    nvcc.addFileArg(source_path);

    // Optimization flags based on Zig build mode
    switch (optimize) {
        .Debug => nvcc.addArg("-G"), // CUDA Debug symbols
        else => nvcc.addArg("-O3"),
    }

    // Architecture flag
    nvcc.addArg(b.fmt("-arch=sm_{s}", .{gpu_arch_str}));

    // Compiler options
    nvcc.addArg("--compiler-options");
    nvcc.addArg("-fPIC");

    // 3. Define the Output
    // This is the magic part. We tell Zig: "Expect this command to output a file named cuda.o".
    // Zig will append `-o /path/to/cache/cuda.o` to the command automatically.
    nvcc.addArg("-o");
    const output_file = nvcc.addOutputFileArg("cuda.o");

    return .{ &nvcc.step, output_file };
}

fn getGpuArch(b: *std.Build) ![]const u8 {
    // Attempt to run nvidia-smi
    const result = std.process.Child.run(.{
        .allocator = b.allocator,
        .argv = &.{ "nvidia-smi", "--query-gpu=compute_cap", "--format=csv,noheader" },
    }) catch return error.NvidiaSmiNotFound;

    defer b.allocator.free(result.stdout);
    defer b.allocator.free(result.stderr);

    if (result.stdout.len == 0) return error.NoGpuFound;

    var buffer = try b.allocator.alloc(u8, result.stdout.len);
    var i: usize = 0;
    for (result.stdout) |c| {
        if (std.ascii.isDigit(c)) {
            buffer[i] = c;
            i += 1;
        }
    }
    return buffer[0..i];
}
