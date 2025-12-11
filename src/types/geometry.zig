const zalgebra = @import("zalgebra");
const std = @import("std");

const acos = std.math.acos;

const Vec2 = zalgebra.Vec2;
const Vec3 = zalgebra.Vec3;
const Quat = zalgebra.Quat;

pub const Pose = struct {
    position: Vec3 = Vec3.zero(),
    orientation: Quat = Quat.identity(),

    pub fn Zero() Pose {
        return .{
            .position = .{ .x = 0, .y = 0, .z = 0 },
            .orientation = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
        };
    }

    pub fn is_close(self: *Pose, other: Pose, tol_m: f32, tol_rad: f32) bool {
        if (self.position.distanceSq(other.position) <= tol_m * tol_m) {
            return 2 * acos(@abs(self.orientation.dot(other.orientation))) <= tol_rad;
        }
        return false;
    }
};
