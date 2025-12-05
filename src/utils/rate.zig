const std = @import("std");

pub const Rate = struct {
    target_ns: u64,
    last_time: ?i128,

    pub fn init(frequency: f64) !Rate {
        if (frequency <= 0) return error.InvalidFrequency;

        return Rate{
            .target_ns = @intFromFloat(@as(f64, std.time.ns_per_s) / frequency),
            .last_time = null,
        };
    }

    pub fn sleep(self: *Rate) void {
        const current_time = std.time.nanoTimestamp();

        if (self.last_time == null) {
            std.Thread.sleep(self.target_ns);
            // std.debug.print("slept first time {d}\n", .{self.target_ns});
            self.last_time = current_time;
        } else {
            const sleep_ns = self.last_time.? - current_time + self.target_ns;

            if (sleep_ns > 0) {
                std.Thread.sleep(@intCast(sleep_ns));
                // std.debug.print("slept {d}\n", .{sleep_ns});
            } else {
                // don't sleep, we are behind
                // std.debug.print("skipping this sleep\n", .{});
            }
        }
        self.last_time.? += self.target_ns;
    }
};
