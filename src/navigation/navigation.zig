const std = @import("std");

const geometry_types = @import("../types/geometry.zig");
const map_types = @import("../types/map.zig");

const LocalPlanner = @import("local_planner.zig").LocalPlanner;
const GlobalPlanner = @import("global_planner.zig").GlobalPlanner;

const Pose = geometry_types.Pose;
const Map2D = map_types.Map2D;

const Navigation = struct {
    path_update_tolerance: u32 = 1,

    controller: anyopaque,

    costmap: anyopaque,
    localization: anyopaque,

    global_planner: GlobalPlanner,
    local_planner: LocalPlanner,
    global_thread: std.Thread,

    pub fn init(self: *Navigation) !void {
        self.global_thread = try std.Thread.spawn(.{}, self.global_loop, .{}) orelse unreachable;
    }

    pub fn deinit(self: *Navigation) void {
        self.global_thread.join();
    }

    fn global_planner_step(self: *Navigation, goal: Pose) void {
        const global_costmap = self.get_global_costmap();
        const start_pose = self.localization.get_pose();

        const plan = self.global_planner.get_path(global_costmap, start_pose, goal) catch |err| switch (err) {
            .PATH_BLOCKED => {
                request_new_path();
            },
            .STUCK => {
                request_recovery();
            },
            .INVALID_GOAL => {
                request_failure();
            },
        };

        if (self.local_planner.goal == null or
            path.length_m < self.local_planner.goal.path.length_m + self.path_update_tolerance)
        {
            request_path_change();
        } else {
            //
        }
    }

    fn local_planner_step(self: *Navigation, local_planner: LocalPlanner) void {
        while (!self.aborted and !local_planner.is_goal_reached()) {
            const pose: Pose = self.localization.get_pose();
            const local_costmap: Map2D(u8) = self.costmap.get_local_costmap();

            const cmd = local_planner.step(pose, local_costmap) catch |err| switch (err) {
                .PATH_BLOCKED => {
                    request_new_path();
                },
                .STUCK => {
                    request_recovery();
                },
                .INVALID_GOAL => {
                    request_failure();
                },
            };
        }
    }
};
