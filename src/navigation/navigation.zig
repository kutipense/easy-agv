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

pub const NavigationStatus = enum(u8) {
    RUNNING,
    WAITING,
    STOPPED,
};

fn request_recovery() void {}

const Localization = struct {
    pub fn init() Localization {
        return .{};
    }

    pub fn get_pose(self: *Localization) Pose {
        _ = self;
        return Pose.Zero();
    }
};

pub const Navigation = struct {
    // controller: anyopaque,

    localization: Localization,

    costmap: Costmap,
    global_planner: GlobalPlanner,
    local_planner: LocalPlanner,

    status: std.atomic.Value(NavigationStatus),
    latest_plan: ?Plan,
    target: ?Pose,

    global_plan_thread: ?std.Thread,
    global_plan_mtx: std.Thread.Mutex,
    global_plan_loop_mtx: std.Thread.Mutex,
    global_plan_loop_cond: std.Thread.Condition,

    pub fn init() Navigation {
        return .{
            .costmap = Costmap.init(),
            .localization = Localization.init(),
            .global_planner = GlobalPlanner.init(),
            .local_planner = LocalPlanner.init(),

            .status = std.atomic.Value(NavigationStatus).init(.WAITING),
            .latest_plan = null,
            .target = null,

            .global_plan_thread = null,
            .global_plan_mtx = .{},
            .global_plan_loop_mtx = .{},
            .global_plan_loop_cond = .{},
        };
    }

    // TODO init returns the struct, no default
    pub fn start(self: *Navigation) !void {
        if (self.global_plan_thread != null) return error.AlreadyStarted;

        self.status = std.atomic.Value(NavigationStatus).init(.WAITING);
        self.global_plan_thread = try std.Thread.spawn(.{}, Navigation.global_loop, .{self});
    }

    pub fn deinit(self: *Navigation) void {
        self.status.store(.STOPPED, .acquire);

        self.global_plan_loop_cond.signal();
        self.global_thread.join();
    }

    pub fn global_loop(self: *Navigation) void {
        while (self.status.load(.acquire) != .STOPPED) {
            std.debug.print("\n\nstarting to the  global loop\n", .{});
            self.global_plan_loop_mtx.lock();

            while (self.target == null and self.status.load(.acquire) == .WAITING) {
                std.debug.print("waiting for a target\n", .{});
                self.global_plan_loop_cond.wait(&self.global_plan_loop_mtx);
            }

            if (self.status.load(.acquire) == .STOPPED) {
                self.global_plan_loop_mtx.unlock();
                break;
            }

            const target = self.target.?;
            self.target = null;
            self.status.store(.RUNNING, .release);
            self.global_plan_loop_mtx.unlock();
            std.debug.print("\ntarget acquired\n", .{});

            var rate = Rate.init(std.time.ns_per_s * 2);
            while (self.status.load(.acquire) == .RUNNING) {
                if (self.costmap.global_costmap()) |costmap| {
                    std.debug.print("costmap acquired\n", .{});
                    const pose = self.localization.get_pose();
                    if (self.global_planner.get_path(costmap, pose, target)) |plan| {
                        std.debug.print("path acquired\n", .{});

                        self.global_plan_mtx.lock();
                        self.latest_plan = plan;
                        self.global_plan_mtx.unlock();
                    } else |err| {
                        std.debug.print("target error\n", .{});
                        switch (err) {
                            error.PATH_BLOCKED => {
                                // log or alert failure TODO
                                // continue planning
                            },
                            error.STUCK => {
                                request_recovery();
                            },
                            error.INVALID_GOAL => {
                                // log or alert failure TODO
                                self.status.store(.WAITING, .release);
                            },
                        }
                    }
                } else |err| {
                    std.debug.print("can't get the global costmap: {s}\n", .{@errorName(err)});
                }

                if (self.status.load(.acquire) == .RUNNING) {
                    std.debug.print("sleeping for the next global plan\n", .{});
                    rate.sleep();
                }
            }
        }
    }

    pub fn set_target(self: *Navigation, target: ?Pose) void {
        self.status.store(.WAITING, .release);

        self.global_plan_loop_mtx.lock();
        self.target = target;
        self.global_plan_loop_cond.signal();
        self.global_plan_loop_mtx.unlock();
    }

    pub fn abort(self: *Navigation) void {
        self.set_target(null);
    }

    // fn global_planner_step(self: *Navigation, goal: Pose) void {

    //     // put that to the local planner logic
    //     if (self.local_planner.goal == null or
    //         path.length_m < self.local_planner.goal.path.length_m + self.path_update_tolerance)
    //     {
    //         request_path_change();
    //     } else {
    //         //
    //     }
    // }

    // fn local_planner_step(self: *Navigation, local_planner: LocalPlanner) void {
    //     while (!self.aborted and !local_planner.is_goal_reached()) {
    //         const pose: Pose = self.localization.get_pose();
    //         const local_costmap = self.costmap.local_costmap();

    //         const cmd = local_planner.step(pose, local_costmap) catch |err| switch (err) {
    //             .PATH_BLOCKED => {
    //                 request_new_path();
    //             },
    //             .STUCK => {
    //                 request_recovery();
    //             },
    //             .INVALID_GOAL => {
    //                 request_failure();
    //             },
    //         };
    //     }
    // }
};
