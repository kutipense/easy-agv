const std = @import("std");

const geometry_types = @import("../types/geometry.zig");
const map_types = @import("../types/map.zig");
const navigation_types = @import("types.zig");

const LocalPlanner = @import("local_planner.zig").LocalPlanner;
const GlobalPlanner = @import("global_planner.zig").GlobalPlanner;
const Costmap = @import("costmap.zig").Costmap;

const Rate = @import("../utils/rate.zig").Rate;

const Pose = geometry_types.Pose;
const Map2D = map_types.Map2D;
const Plan = navigation_types.Plan;

const Navigation = struct {
    path_update_tolerance: u32 = 1,

    controller: anyopaque,

    localization: anyopaque,

    costmap: Costmap,
    global_planner: GlobalPlanner,
    local_planner: LocalPlanner,
    global_thread: std.Thread,

    latest_plan: ?Plan = null,
    global_plan_mtx: std.Thread.Mutex = .{},

    target: ?Pose,

    global_plan_loop_mtx: std.Thread.Mutex,
    global_plan_loop_cond: std.Thread.Condition,
    stopped: std.atomic.Value(bool),
    aborted: std.atomic.Value(bool),

    pub fn init(self: *Navigation) !void {
        self.stopped = std.atomic.Value(bool).init(false);
        self.aborted = std.atomic.Value(bool).init(false);
        self.global_thread = try std.Thread.spawn(.{}, self.global_loop, .{self}) catch unreachable;
    }

    pub fn deinit(self: *Navigation) void {
        self.stopped.store(true, .release);
        self.aborted.store(true, .release);
        self.global_plan_loop_cond.signal();
        self.global_thread.join();
    }

    fn global_loop(self: *Navigation) void {
        while (!self.stopped.load(.acquire)) {
            self.global_plan_loop_mtx.lock();
            while (self.target == null and !self.stopped.load(.acquire)) {
                self.global_plan_loop_cond.wait(self.global_plan_loop_mtx);
            }
            const target = self.target.?;
            self.target = null;
            self.aborted.store(false, .release);
            self.global_plan_loop_mtx.unlock();

            var rate = try Rate.init(1);
            while (!self.stopped.load(.acquire) and !self.aborted.load(.acquire)) {
                if (self.costmap.global_costmap()) |costmap| {
                    const pose = self.localization.get_pose();
                    if (self.global_planner.get_path(costmap, pose, target)) |plan| {
                        self.global_plan_mtx.lock();
                        self.latest_plan = plan;
                        self.global_plan_mtx.unlock();
                    }
                }
                if (!self.aborted.load(.acquire))
                    rate.sleep();
            }
        }
    }

    fn set_target(self: *Navigation, target: Pose) void {
        self.aborted.store(true, .release);
        self.global_plan_loop_mtx.lock();
        self.target = target;
        self.global_plan_loop_cond.signal();
        self.global_plan_loop_mtx.unlock();
    }

    fn global_planner_step(self: *Navigation, goal: Pose) void {
        const global_costmap = try self.costmap.global_costmap();
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
            const local_costmap = self.costmap.local_costmap();

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
