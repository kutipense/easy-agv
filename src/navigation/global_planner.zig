const geometry_types = @import("../types/geometry.zig");
const map_types = @import("../types/map.zig");
const navigation_types = @import("types.zig");

const NavigationGoal = navigation_types.NavigationGoal;
const GoalReached = navigation_types.GoalReached;
const VelocityCommand = navigation_types.VelocityCommand;
const NavigationError = navigation_types.NavigationError;
const Map2D = map_types.Map2D;

const Pose = geometry_types.Pose;
const Plan = navigation_types.Plan;

pub const GlobalPlanner = struct {
    pub fn get_path(self: *GlobalPlanner, costmap: Map2D(u8), start_pose: Pose, end_pose: Pose) NavigationError!Plan {
        _ = start_pose;
        _ = end_pose;
        _ = costmap;
        _ = self;
    }
};
