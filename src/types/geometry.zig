pub fn Vec2(comptime T: type) type {
    return struct { x: T, y: T };
}
pub fn Vec3(comptime T: type) type {
    return struct { x: T, y: T, z: T };
}
pub const Quat = struct { x: f32, y: f32, z: f32, w: f32 };

pub const Pose = struct {
    position: Vec3(f32) = .{ .x = 0, .y = 0, .z = 0 },
    orientation: Quat = .{ .x = 0, .y = 0, .z = 0, .w = 1 },

    pub fn Zero() Pose {
        return .{
            .position = .{ .x = 0, .y = 0, .z = 0 },
            .orientation = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
        };
    }
};
