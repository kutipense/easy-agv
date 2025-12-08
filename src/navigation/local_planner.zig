const geometry_types = @import("../types/geometry.zig");
const map_types = @import("../types/map.zig");
const navigation_types = @import("types.zig");

const NavigationGoal = navigation_types.NavigationGoal;
const GoalReached = navigation_types.GoalReached;
const VelocityCommand = navigation_types.VelocityCommand;
const NavigationError = navigation_types.NavigationError;
const Map2D = map_types.Map2D;

const Pose = geometry_types.Pose;

pub const LocalPlanner = struct {
    goal: ?NavigationGoal,

    pub fn init() LocalPlanner {
        return .{ .goal = null };
    }

    pub fn step(self: *LocalPlanner, pose: Pose, costmap: Map2D(u8)) NavigationError!VelocityCommand {
        _ = pose;
        _ = costmap;
        _ = self;
    }

    pub fn is_goal_reached(self: *LocalPlanner) GoalReached {
        _ = self;
    }
};
