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

pub fn main() !void {
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
