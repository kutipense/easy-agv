const map_types = @import("../types/map.zig");
const Map2D = map_types.Map2D;

pub const Costmap = struct {
    pub fn init() Costmap {
        return .{};
    }

    pub fn get_costmap(self: *Costmap) !Map2D(u8) {
        _ = self;

        return .{
            .resolution = 0.01,
            .origin = .{ .x = 0, .y = 0 },
            .size = .{ .x = 1, .y = 1 },
            .data = &[1]u8{0},
        };
        // return error.NotImplemented;
    }
};
