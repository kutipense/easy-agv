const geometry_types = @import("../types/geometry.zig");

pub const PlannerError = error{
    CostmapError,
    LocalizationError,

    PathBlocked,
    Stuck,
    InvalidGoal,
};

pub const Path = struct {
    path: []const geometry_types.Vec3(f32),
    target: geometry_types.Pose,
    length_m: f32,
    max_vel: []const f32,
};

pub const Plan = Path;

pub const GoalReached = struct {
    reached: bool,
    duration_ms: usize,
};

pub const VelocityCommand = struct {
    linear: geometry_types.Vec3(f32),
    angular: geometry_types.Vec3(f32),
};
