const std = @import("std");

const geometry_types = @import("../types/geometry.zig");
const map_types = @import("../types/map.zig");
const navigation_types = @import("types.zig");

const Costmap = @import("costmap.zig").Costmap;

const NavigationGoal = navigation_types.NavigationGoal;
const GoalReached = navigation_types.GoalReached;
const VelocityCommand = navigation_types.VelocityCommand;
const PlannerError = navigation_types.PlannerError;
const Plan = navigation_types.Plan;
const Map2D = map_types.Map2D;

const Pose = geometry_types.Pose;

const Localization = struct {
    pub fn init() Localization {
        return .{};
    }

    pub fn get_pose(self: *Localization) !Pose {
        _ = self;
        return Pose.Zero();
    }
};

pub const LocalPlanner = struct {
    allocator: std.mem.Allocator,

    plan: *Plan,
    tolerance_m: f32,
    tolerance_rad: f32,
    lookahed_dist: f32,

    linear_vel: f32,
    angular_vel: f32,

    costmap: Costmap,
    localization: Localization,

    pub fn init(allocator: std.mem.Allocator) LocalPlanner {
        return .{
            .allocator = allocator,

            .plan = null,
            .tolerance_m = 0.1,
            .tolerance_rad = 0.1,
            .lookahed_dist = 1.0,
            .linear_vel = 1.0,
            .angular_vel = 1.0,

            .costmap = Costmap.init(),
            .localization = Localization.init(),
        };
    }

    pub fn set_plan(self: *LocalPlanner, new_plan: *Plan) void {
        if (self.plan) |p| self.allocator.destroy(p); // won't work TODO
        self.plan = new_plan;
    }

    pub fn step(self: *LocalPlanner, pose: Pose) PlannerError!VelocityCommand {
        const costmap = self.costmap.get_costmap() catch return .CostmapError;
        _ = costmap;

        const lp = get_lookahead_point(self.plan.*, self.lookahed_dist);
        const alpha = 2 * std.math.acos(@abs(pose.orientation.dot(lp.orientation)));
        const curvature = 2 * std.math.sin(alpha) / self.lookahed_dist / self.lookahed_dist;

        // make linear gain TODO
        const angular_vel = std.math.clamp(curvature * self.linear_vel, -self.angular_vel, self.angular_vel);

        return .{ .linear = geometry_types.Vec3.new(self.linear_vel, 0, 0), .angular = geometry_types.Vec3.new(0, 0, angular_vel) };
    }

    pub fn is_done(self: *LocalPlanner) PlannerError!GoalReached {
        const pose = self.localization.get_pose() catch return .LocalizationError;
        return self.plan.target.is_close(pose, self.tolerance_m, self.tolerance_rad);
    }

    pub fn get_lookahead_point(plan: Plan, ld: f32) Pose {
        _ = plan;
        _ = ld;

        return Pose.Zero();
    }
};
