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

    build_graphs(closest1000);

    return DayResult.both_parts(part1_buf, part2_buf, num_points, null);
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
                .sq_dist = calc_sq_dist(point1, point2), 
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

fn calc_sq_dist(point1: Point, point2: Point) u64 {
    return point1[0] * point2[0] 
        + point1[1] * point2[1]
        + point1[2] * point2[2];
}

// tmp
// Graph is an adjacency list
const Graph = []std.ArrayList(usize);

fn build_graphs(allocator: Allocator, pairs: []Pair) ![3]Graph {
    
}
