const webui = @import("webui");
const std = @import("std");
const zalgebra = @import("zalgebra");
const xev = @import("xev");

const Rate = @import("utils/rate.zig").Rate;

const navigation = @import("navigation/navigation.zig");

const geometry_types = @import("types/geometry.zig");

const html_file = @embedFile("gui/html/index.html");

fn close_window(e: *webui.Event) void {
    const win = e.getWindow();
    win.close();
}

fn always_true(_: usize) bool {
    return true;
}

extern fn cudaMalloc(ptr: *?*anyopaque, size: usize) c_int;
extern fn cudaMemcpy(dest: *anyopaque, src: *const anyopaque, size: usize, kind: c_int) c_int;
extern fn cudaFree(ptr: *anyopaque) c_int;
extern "C" fn launchAddKernel(a: *anyopaque, b: *anyopaque, c: *anyopaque) void;

const cudaMemcpyHostToDevice = 1;
const cudaMemcpyDeviceToHost = 2;

export fn add(a: i32, b: i32) i32 {
    var d_a: ?*anyopaque = undefined;
    var d_b: ?*anyopaque = undefined;
    var d_c: ?*anyopaque = undefined;
    var result: i32 = undefined;

    _ = cudaMalloc(&d_a, @sizeOf(i32));
    _ = cudaMalloc(&d_b, @sizeOf(i32));
    _ = cudaMalloc(&d_c, @sizeOf(i32));

    _ = cudaMemcpy(d_a.?, &a, @sizeOf(i32), cudaMemcpyHostToDevice);
    _ = cudaMemcpy(d_b.?, &b, @sizeOf(i32), cudaMemcpyHostToDevice);

    launchAddKernel(d_a.?, d_b.?, d_c.?);

    _ = cudaMemcpy(&result, d_c.?, @sizeOf(i32), cudaMemcpyDeviceToHost);

    _ = cudaFree(d_a.?);
    _ = cudaFree(d_b.?);
    _ = cudaFree(d_c.?);

    return result;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{ .thread_safe = true }).init;
    var allocator = gpa.allocator();
    var nav = navigation.Navigation.init(allocator);

    try nav.start();

    // var loop = try xev.Loop.init(.{});
    // defer loop.deinit();

    // const w = try xev.Timer.init();
    // defer w.deinit();

    // var rate = try Rate.init(1);

    // // std.Thread.sleep(std.time.ns_per_s * 3);

    // rate.sleep();
    // std.debug.print("helo\n\n", .{});

    // rate.sleep();
    // std.debug.print("helo\n\n", .{});

    std.Thread.sleep(std.time.ns_per_s * 1.5);

    var pose0: ?*geometry_types.Pose = try allocator.create(geometry_types.Pose);
    pose0.?.* = geometry_types.Pose.Zero();

    nav.set_target(pose0);

    std.Thread.sleep(std.time.ns_per_s * 5);
    nav.abort();

    pose0 = try allocator.create(geometry_types.Pose);
    pose0.?.* = geometry_types.Pose.Zero();

    std.Thread.sleep(std.time.ns_per_s * 5);

    nav.cancel();
    // nav.set_target(pose0);

    nav.global_plan_thread.?.join();
    // rate.sleep();
    // std.debug.print("helo\n\n", .{});

    // rate.sleep();
    // std.debug.print("helo\n\n", .{});

    // // 5s timer
    // var c: xev.Completion = undefined;
    // w.run(&loop, &c, 5000, void, null, &timerCallback);

    // try loop.run(.until_done);

    // const result = add(12, 12);

    // std.debug.print("result: {d}\n\n", .{result});

    // var nwin = webui.newWindow();

    // nwin.setCloseHandlerWv(always_true);

    // _ = try nwin.bind("close_window", close_window);

    // nwin.setSize(1920, 1080);
    // nwin.setPosition((3840 - 1920) / 2, (2160 - 1080) / 2);
    // nwin.setFrameless(true);
    // // nwin.setTransparent(true);
    // nwin.setResizable(true);

    // // show the content
    // // nwin.setFrameless(true);
    // try nwin.showWv(html_file);

    // webui.wait();

    // webui.clean();
}

fn timerCallback(
    userdata: ?*void,
    loop: *xev.Loop,
    c: *xev.Completion,
    result: xev.Timer.RunError!void,
) xev.CallbackAction {
    _ = userdata;
    _ = loop;
    _ = c;
    _ = result catch unreachable;
    return .disarm;
}
