const map_types = @import("../types/map.zig");
const Map2D = map_types.Map2D;

pub const Costmap = struct {
    pub fn local_costmap(self: *Costmap) !Map2D(u8) {
        _ = self;
        return error.NotImplemented;
    }

    pub fn global_costmap(self: *Costmap) !Map2D(u8) {
        _ = self;
        return error.NotImplemented;
    }
};
