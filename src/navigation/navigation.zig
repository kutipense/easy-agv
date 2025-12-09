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

    allocator: std.mem.Allocator,

    costmap: Costmap,
    localization: Localization,
    global_planner: GlobalPlanner,
    local_planner: LocalPlanner,

    status: std.atomic.Value(NavigationStatus),
    new_plan: std.atomic.Value(?*Plan),
    new_target: std.atomic.Value(?*Pose),

    global_plan_thread: ?std.Thread,

    pub fn init(allocator: std.mem.Allocator) Navigation {
        return .{
            .allocator = allocator,

            .costmap = Costmap.init(),
            .localization = Localization.init(),
            .global_planner = GlobalPlanner.init(allocator),
            .local_planner = LocalPlanner.init(),

            .status = std.atomic.Value(NavigationStatus).init(.WAITING),
            .new_plan = std.atomic.Value(?*Plan).init(null),
            .new_target = std.atomic.Value(?*Pose).init(null),

            .global_plan_thread = null,
        };
    }

    // TODO init returns the struct, no default
    pub fn start(self: *Navigation) !void {
        if (self.global_plan_thread != null) return error.AlreadyStarted;

        self.status = std.atomic.Value(NavigationStatus).init(.WAITING);
        self.global_plan_thread = try std.Thread.spawn(.{}, Navigation.global_loop, .{self});
    }

    pub fn stop(self: *Navigation) void {
        self.status.store(.STOPPED, .release);
        if (self.global_plan_thread) |t| t.join();
    }

    pub fn global_loop(self: *Navigation) void {
        var target: ?Pose = null;
        defer if (self.new_plan.load(.acquire)) |p| self.allocator.destroy(p); // won't work

        var rate = Rate.init(std.time.ns_per_s * 2);
        while (self.status.load(.acquire) != .STOPPED) {
            std.debug.print("sleeping for the next global plan\n", .{});
            rate.sleep();

            if (self.status.load(.acquire) != .RUNNING) continue;

            if (self.new_target.swap(null, .acq_rel)) |nt| {
                target = nt.*;
                self.allocator.destroy(nt);
                std.debug.print("new target acquired\n", .{});
            }

            const costmap = self.costmap.global_costmap() catch |err| {
                std.debug.print("can't get the global costmap: {s}\n", .{@errorName(err)});
                continue;
            };

            std.debug.print("costmap acquired\n", .{});
            const pose = self.localization.get_pose();

            const plan_ptr: ?*Plan = self.global_planner.get_path(costmap, pose, target.?) catch |err| {
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
                continue;
            };

            std.debug.print("path acquired\n", .{});

            const old_plan = self.new_plan.swap(plan_ptr, .acq_rel);

            if (old_plan) |p| {
                self.allocator.destroy(p); // won't work TODO
            }
        }
    }

    pub fn set_target(self: *Navigation, target: ?*Pose) void {
        if (self.new_target.swap(target, .acq_rel)) |t| self.allocator.destroy(t);
        self.status.store(.RUNNING, .release);
    }

    pub fn abort_target(self: *Navigation) void {
        self.status.store(.WAITING, .release);
        if (self.new_target.swap(null, .acq_rel)) |t| self.allocator.destroy(t);
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
