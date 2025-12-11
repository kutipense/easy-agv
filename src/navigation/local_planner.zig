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
    plan: *Plan,
    tolerance_m: f32,
    tolerance_rad: f32,

    costmap: Costmap,
    localization: Localization,

    pub fn init() LocalPlanner {
        return .{
            .goal = null,
            .tolerance_m = 0.1,
            .tolerance_rad = 0.1,

            .costmap = Costmap.init(),
            .localization = Localization.init(),
        };
    }

    pub fn step(self: *LocalPlanner, pose: Pose) PlannerError!VelocityCommand {
        const costmap = self.costmap.get_costmap() catch return .CostmapError;
        _ = pose;
        _ = costmap;

        return .CostmapError;
    }

    pub fn is_goal_reached(self: *LocalPlanner) PlannerError!GoalReached {
        const pose = self.localization.get_pose() catch return .LocalizationError;
        return self.plan.target.is_close(pose, self.tolerance_m, self.tolerance_rad);
    }
};
