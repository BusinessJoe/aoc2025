const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;
const Octree = @import("../octree.zig").Octree;
const OctreeNode = @import("../octree.zig").Node;
const BoundedMinHeap = @import("../bounded_min_heap.zig").BoundedMinHeap;

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

    const pairs: []Pair = try findPairsFast(allocator, points);
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

/// Pair from a NNIterator
const NNIPair = struct {
    it_idx: usize,
    pair: Pair,

    fn lt(lhs: NNIPair, rhs: NNIPair) bool {
        return lhs.pair.sq_dist < rhs.pair.sq_dist;
    }
};

fn findPairsFast(allocator: Allocator, points: []Point) ![]Pair {
    var max_coord: u64 = 0;
    for (points) |point| {
        max_coord = @max(max_coord, point[0], point[1], point[2]);
    }

    var octree = try Octree(usize).init(allocator, max_coord + 1);
    defer octree.deinit(allocator);

    for (points, 0..) |point, i| {
        try octree.insert(allocator, point, i);
    }

    var iterators = try ArrayList(Octree(usize).NNIterator).initCapacity(allocator, points.len);
    defer {
        for (iterators.items) |*it| {
            it.deinit(allocator);
        }
        iterators.deinit(allocator);
    }

    for (points) |point| {
        iterators.appendAssumeCapacity(try octree.iterator(allocator, point));
    }

    var it_heap = try BoundedMinHeap(NNIPair, NNIPair.lt).initCapacity(allocator, points.len);
    defer it_heap.deinit(allocator);

    for (iterators.items, 0..) |*it, i| {
        if (try getNextLeaf(allocator, it, i)) |leaf| {
            const sq_dist = calcSqDist(points[i], leaf.point);
            const pair: NNIPair = .{
                .it_idx = i,
                .pair = .{ .p1 = i, .p2 = leaf.data, .sq_dist = sq_dist },
            };
            try it_heap.insert(pair);
        }
    }

    const pairs = try allocator.alloc(Pair, 1000);
    errdefer allocator.free(pairs);
    for (pairs) |*pair| {
        pair.* = try nextClosestPair(allocator, &it_heap, iterators.items) orelse unreachable;
    }

    return pairs;
}

fn nextClosestPair(allocator: Allocator, it_heap: *BoundedMinHeap(NNIPair, NNIPair.lt), iterators: []Octree(usize).NNIterator) !?Pair {
    const nni_pair_opt = it_heap.pop();
    if (nni_pair_opt == null) return null;
    const nni_pair = nni_pair_opt.?;
    const pair = nni_pair.pair;
    
    const it = &iterators[nni_pair.it_idx];
    if (try getNextLeaf(allocator, it, nni_pair.it_idx)) |next_leaf| {
        const next_pair = Pair{
            .p1 = nni_pair.it_idx,
            .p2 = next_leaf.data,
            .sq_dist = calcSqDist(it.target, next_leaf.point),
        };
        const item: NNIPair = .{
            .it_idx = nni_pair.it_idx,
            .pair = next_pair,
        };
        try it_heap.insert(item);
    }

    return pair;
}

fn getNextLeaf(allocator: Allocator, it: *Octree(usize).NNIterator, it_idx: usize) !?OctreeNode(usize).Leaf {
    while (try it.next(allocator)) |leaf| {
        if (leaf.data > it_idx) return leaf;
    }
    return null;
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
