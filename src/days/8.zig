const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

const Point = [3]u64;

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    // There's a new line after every line except for the last
    const num_points = std.mem.count(u8, input, "\n") + 1;

    const points = try allocator.alloc(Point, num_points);
    defer allocator.free(points);

    var lines = std.mem.splitScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |line| {
        var coords = std.mem.splitScalar(u8, line, ',');
        
        const x_str = coords.next() orelse return error.ExpectedCoord;
        const y_str = coords.next() orelse return error.ExpectedCoord;
        const z_str = coords.next() orelse return error.ExpectedCoord;

        const x = try std.fmt.parseInt(u64, x_str, 10);
        const y = try std.fmt.parseInt(u64, y_str, 10);
        const z = try std.fmt.parseInt(u64, z_str, 10);

        const point: Point = [_]u64{x, y, z};

        points[i] = point;
        i += 1;
    }

    const pairs: []Pair = try findPairsSlow(allocator, points);
    defer allocator.free(pairs);

    std.mem.sortUnstable(Pair, pairs, {}, pairLessThan);

    const closest1000 = pairs[0..1000];

    const top3 = try buildGraphs(allocator, closest1000, points.len);

    const part1 = top3[0] * top3[1] * top3[2];

    return DayResult.both_parts(part1_buf, part2_buf, part1, null);
}

const Pair = struct {
    sq_dist: u64,
    p1: usize,
    p2: usize,
};

fn pairLessThan(ctx: void, pair1: Pair, pair2: Pair) bool {
    _ = ctx;
    return pair1.sq_dist < pair2.sq_dist;
}

fn findPairsSlow(allocator: Allocator, points: []Point) ![]Pair {
    const pairs: []Pair = try allocator.alloc(Pair, points.len * (points.len - 1) / 2);
    errdefer allocator.free(pairs);

    var pair_idx: usize = 0;
    for (points, 0..) |point1, i| {
        for (i+1..points.len) |j| {
            const point2 = points[j];
            const pair: Pair = .{ 
                .sq_dist = calcSqDist(point1, point2), 
                .p1 = i, 
                .p2 = j,
            };
            pairs[pair_idx] = pair;
            pair_idx += 1;
        }
    }

    std.debug.assert(pair_idx == pairs.len);

    return pairs;
}

fn calcSqDist(point1: Point, point2: Point) u64 {
    const dx = @max(point1[0], point2[0]) - @min(point1[0], point2[0]);
    const dy = @max(point1[1], point2[1]) - @min(point1[1], point2[1]);
    const dz = @max(point1[2], point2[2]) - @min(point1[2], point2[2]);
    return dx * dx + dy * dy + dz * dz;
}

const AdjacencyList = []std.ArrayList(usize);

fn buildGraphs(allocator: Allocator, pairs: []Pair, num_points: usize) ![3]u64 {
    const adjacency_list = try allocator.alloc(std.ArrayList(usize), num_points);
    defer {
        for (adjacency_list) |*list| {
            list.deinit(allocator);
        }
        allocator.free(adjacency_list);
    }

    for (adjacency_list) |*list| {
        list.* = try std.ArrayList(usize).initCapacity(allocator, 5);
    }

    for (pairs) |pair| {
        try adjacency_list[pair.p1].append(allocator, pair.p2);
        try adjacency_list[pair.p2].append(allocator, pair.p1);
    }


    var visited: std.AutoHashMapUnmanaged(usize, void) = .empty;
    defer visited.deinit(allocator);

    var graph_sizes: std.ArrayList(usize) = .empty;
    defer graph_sizes.deinit(allocator);

    for (0..num_points) |point_idx| {
        if (visited.contains(point_idx)) continue;

        try graph_sizes.append(allocator, try getGraphSize(allocator, point_idx, adjacency_list, &visited));
    }

    std.mem.sortUnstable(usize, graph_sizes.items, {}, usizelessThan);

    return [_]u64{
        graph_sizes.items[graph_sizes.items.len - 1],
        graph_sizes.items[graph_sizes.items.len - 2],
        graph_sizes.items[graph_sizes.items.len - 3],
    };
}

fn usizelessThan(ctx: void, a: usize, b: usize) bool {
    _ = ctx;
    return a < b;
}

fn u8LessThan(a: u8, b: u8) bool {
    return a < b;
}

fn getGraphSize(allocator: Allocator, point_idx: usize, adjacency_list: AdjacencyList, visited: *std.AutoHashMapUnmanaged(usize, void)) !usize {
    if (visited.contains(point_idx)) return 0;

    try visited.put(allocator, point_idx, {});
    var total: usize = 1;

    for (adjacency_list[point_idx].items) |next| {
        total += try getGraphSize(allocator, next, adjacency_list, visited);
    }

    return total;
}
