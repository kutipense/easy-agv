const std = @import("std");

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
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) GlobalPlanner {
        return .{ .allocator = allocator };
    }

    pub fn get_path(
        self: *GlobalPlanner,
        costmap: Map2D(u8),
        start_pose: Pose,
        end_pose: Pose,
    ) NavigationError!*Plan {
        _ = start_pose;
        _ = end_pose;
        _ = costmap;

        // const vec: [1]geometry_types.Vec3(f32) = .{
        //     .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        // };

        // const max_vel: [1]f32 = .{0};

        return self.allocator.create(Plan) catch unreachable; // TODO
        // return Plan{ .length_m = 0, .max_vel = &max_vel, .path = &vec };
    }
};
