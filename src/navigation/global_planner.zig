const std = @import("std");

const geometry_types = @import("../types/geometry.zig");
const map_types = @import("../types/map.zig");
const navigation_types = @import("types.zig");

const Costmap = @import("costmap.zig").Costmap;

const NavigationGoal = navigation_types.NavigationGoal;
const GoalReached = navigation_types.GoalReached;
const VelocityCommand = navigation_types.VelocityCommand;
const PlannerError = navigation_types.PlannerError;
const Map2D = map_types.Map2D;

const Pose = geometry_types.Pose;
const Plan = navigation_types.Plan;

const Localization = struct {
    pub fn init() Localization {
        return .{};
    }

    pub fn get_pose(self: *Localization) !Pose {
        _ = self;
        return Pose.Zero();
    }
};

pub const GlobalPlanner = struct {
    allocator: std.mem.Allocator,

    costmap: Costmap,
    localization: Localization,

    pub fn init(allocator: std.mem.Allocator) GlobalPlanner {
        return .{
            .allocator = allocator,

            .costmap = Costmap.init(),
            .localization = Localization.init(),
        };
    }

    pub fn plan(self: *GlobalPlanner, target: Pose) PlannerError!*Plan {
        const costmap = self.costmap.global_costmap() catch return .CostmapError;
        const pose = self.localization.get_pose() catch return .LocalizationError;

        // const vec: [1]geometry_types.Vec3(f32) = .{
        //     .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        // };

        // const max_vel: [1]f32 = .{0};

        _ = costmap;
        _ = pose;
        _ = target;

        return self.allocator.create(Plan) catch unreachable; // TODO
        // return Plan{ .length_m = 0, .max_vel = &max_vel, .path = &vec };
    }
};
