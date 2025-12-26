const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const ztracy = @import("ztracy");

const DayResult = @import("../framework.zig").DayResult;
const Octree = @import("../octree.zig").Octree;
const OctreeNode = @import("../octree.zig").Node;
const BoundedMinHeap = @import("../bounded_min_heap.zig").BoundedMinHeap;
const RingBuffer = @import("../ring_buffer.zig").RingBuffer;

const Point = [3]u64;

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    // There's a new line after every line except for the last
    const num_points = std.mem.count(u8, input, "\n") + 1;

    const points = try allocator.alloc(Point, num_points);
    defer allocator.free(points);

    var lines = std.mem.splitScalar(u8, input, '\n');
    {
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
    }

    var pairs = try ClosestPairIterator.init(allocator, points);
    defer pairs.deinit(allocator);

    // We'll represent our graphs via an adjacency list
    const adj_list: AdjacencyList = try allocator.alloc(std.ArrayList(usize), num_points);
    for (adj_list) |*list| list.* = .empty;
    defer {
        for (adj_list) |*list| {
            list.deinit(allocator);
        }
        allocator.free(adj_list);
    }

    var part1: u32 = 0;
    var part2: u64 = 0;

    const visited = try allocator.alloc(bool, num_points);
    defer allocator.free(visited);
    @memset(visited, false);
    visited[0] = true;
    var total_visited: u32 = 1;

    const queue_buf = try allocator.alloc(usize, num_points);
    defer allocator.free(queue_buf);

    var queue = RingBuffer(usize).init(queue_buf);

    var i: usize = 0;
    while (try pairs.next(allocator)) |pair| {
        i += 1;
        try adj_list[pair.p1].append(allocator, pair.p2);
        try adj_list[pair.p2].append(allocator, pair.p1);

        // After 1000 pairs, we can answer part 1
        if (i == 999) {
            part1 = try solvePart1(allocator, adj_list);
        }

        if (visited[pair.p1] and !visited[pair.p2]) {
            total_visited += floodFill(adj_list, pair.p2, visited, &queue);
        } else if (visited[pair.p2] and !visited[pair.p1]) {
            total_visited += floodFill(adj_list, pair.p1, visited, &queue);
        }

        if (total_visited == num_points) {
            // Our graph is now fully connected, we can answer part 2
            // Part 2 is the product of the x coordinates of the last two connected junction boxes.
            part2 = points[pair.p1][0] * points[pair.p2][0];
            break;
        }
    }

    return DayResult.both_parts(part1_buf, part2_buf, part1, part2);
}

fn solvePart1(allocator: Allocator, adj_list: AdjacencyList) !u32 {
    _ = allocator;
    _ = adj_list;
    return 0;
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

const ClosestPairIterator = struct {
    // The iterators keep a pointer to their octree, so we can't let the octree
    // get moved.
    octree: *Octree(usize),
    it_heap: BoundedMinHeap(NNIPair, NNIPair.lt),
    iterators: ArrayList(Octree(usize).NNIterator),

    pub fn init(allocator: Allocator, points: []Point) !ClosestPairIterator {
        // Our octree will be a cube containing every point, so we need to find
        // how large the cube's side length will need to be.
        var max_coord: u64 = 0;
        for (points) |point| {
            max_coord = @max(max_coord, point[0], point[1], point[2]);
        }

        var octree = try allocator.create(Octree(usize));
        errdefer allocator.destroy(octree);

        octree.* = try Octree(usize).init(allocator, max_coord + 1);
        errdefer octree.deinit(allocator);

        for (points, 0..) |point, i| {
            try octree.insert(allocator, point, i);
        }

        var iterators = try ArrayList(Octree(usize).NNIterator).initCapacity(allocator, points.len);
        errdefer {
            for (iterators.items) |*it| {
                it.deinit(allocator);
            }
            iterators.deinit(allocator);
        }

        for (points) |point| {
            iterators.appendAssumeCapacity(try octree.iterator(allocator, point));
        }

        var it_heap = try BoundedMinHeap(NNIPair, NNIPair.lt).initCapacity(allocator, points.len);
        errdefer it_heap.deinit(allocator);

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

        return ClosestPairIterator{
            .octree = octree,
            .it_heap = it_heap,
            .iterators = iterators,
        };
    }

    pub fn deinit(self: *ClosestPairIterator, allocator: Allocator) void {
        self.octree.deinit(allocator);
        allocator.destroy(self.octree);
        self.it_heap.deinit(allocator);
        for (self.iterators.items) |*it| {
            it.deinit(allocator);
        }
        self.iterators.deinit(allocator);
    }

    pub fn next(self: *ClosestPairIterator, allocator: Allocator) !?Pair {
        return try nextClosestPair(allocator, &self.it_heap, self.iterators.items);
    }
};

fn nextClosestPair(allocator: Allocator, it_heap: *BoundedMinHeap(NNIPair, NNIPair.lt), iterators: []Octree(usize).NNIterator) !?Pair {
    const tracy_zone = ztracy.ZoneN(@src(), "nextClosestPair");
    defer tracy_zone.End();

    const nni_pair_opt = it_heap.peek();
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
        it_heap.replace(item);
    } else {
        _ = it_heap.pop();
    }

    return pair;
}

fn getNextLeaf(allocator: Allocator, it: *Octree(usize).NNIterator, it_idx: usize) !?OctreeNode(usize).Leaf {
    const tracy_zone = ztracy.ZoneN(@src(), "getNextLeaf");
    defer tracy_zone.End();

    while (try it.next(allocator)) |leaf| {
        if (leaf.data > it_idx) return leaf;
    }
    return null;
}

fn calcSqDist(point1: Point, point2: Point) u64 {
    const tracy_zone = ztracy.ZoneN(@src(), "calcSqDist");
    defer tracy_zone.End();

    const dx = @max(point1[0], point2[0]) - @min(point1[0], point2[0]);
    const dy = @max(point1[1], point2[1]) - @min(point1[1], point2[1]);
    const dz = @max(point1[2], point2[2]) - @min(point1[2], point2[2]);
    return dx * dx + dy * dy + dz * dz;
}

const AdjacencyList = []ArrayList(usize);

/// Visit all unvisited vertices connected to the given vertex.
///
/// The connections are defined by the adjacency list, and the visited flag for
/// each connected vertex will be set.
///
/// The queue must be a ring buffer with capacity at least equal to the total number of vertices.
/// The queue may be modified by this function.
///
/// Returns the number of newly visited vertices.
fn floodFill(adj_list: AdjacencyList, vertex: usize, visited: []bool, queue: *RingBuffer(usize)) u32 {
    queue.clear();

    // Invariant: all vertices in the queue must not be visited prior to being
    // placed in the queue, and are considered visited once they are in the queue.
    // This ensures that each vertex is only added to the queue once.

    if (visited[vertex]) return 0;

    var count: u32 = 0;
    queue.pushBack(vertex);
    visited[vertex] = true;
    
    while (queue.popFront()) |v| {
        // By invariant, we are not double-counting
        count += 1;

        for (adj_list[v].items) |neighbour| {
            if (visited[neighbour]) continue;

            queue.pushBack(neighbour);
            visited[neighbour] = true;
        }
    }

    return count;
}

