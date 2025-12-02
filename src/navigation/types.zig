const geometry_types = @import("../types/geometry.zig");

pub const NavigationError = error{
    PATH_BLOCKED,
    STUCK,
    INVALID_GOAL,
};

pub const Path = struct {
    path: []const geometry_types.Vec3(f32),
    length_m: f32,
    max_vel: []const f32,
};

pub const Plan = Path;

pub const NavigationGoal = struct {
    path: Path,

    position: geometry_types.Vec3(f32),
    rotation: geometry_types.Quat,
    tolerance_m: f32,
};

pub const GoalReached = struct {
    reached: bool,
    duration_ms: usize,
};

pub const VelocityCommand = struct {
    linear: geometry_types.Vec3(f32),
    angular: geometry_types.Vec3(f32),
};
