const webui = @import("webui");
const std = @import("std");
const zalgebra = @import("zalgebra");

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
    const result = add(12, 12);

    std.debug.print("result: {d}\n\n", .{result});

    var nwin = webui.newWindow();

    nwin.setCloseHandlerWv(always_true);

    _ = try nwin.bind("close_window", close_window);

    nwin.setSize(1920, 1080);
    nwin.setPosition((3840 - 1920) / 2, (2160 - 1080) / 2);
    nwin.setFrameless(true);
    // nwin.setTransparent(true);
    nwin.setResizable(true);

    // show the content
    // nwin.setFrameless(true);
    try nwin.showWv(html_file);

    webui.wait();

    // webui.clean();
}
