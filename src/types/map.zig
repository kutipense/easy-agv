const geometry_types = @import("geometry.zig");

const Vec2 = geometry_types.Vec2;

pub fn Map2D(comptime T: type) type {
    return struct {
        resolution: f32,
        size: Vec2(i32), // # elements
        origin: Vec2(f32), // [0,0] position TODO
        data: []const T,
    };
}
