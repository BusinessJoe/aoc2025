const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const BoundedMinHeap = @import("bounded_min_heap.zig").BoundedMinHeap;
const MinHeap = @import("min_heap.zig").MinHeap;

const ztracy = @import("ztracy");

const BranchNode = struct {
    branches: [8]?usize,

    offset: [3]u64,
    // width is always a power of 2 greater than 1
    width: u64,

    /// Get index of branch (0..8) containing the needle.
    /// The needle must be within the bounds of this branch node.
    pub fn indexOfBranchWithPoint(self: BranchNode, needle: [3]u64) usize {
        // Bound sanity checks
        for (0..3) |i| {
            std.debug.assert(self.offset[i] <= needle[i]);
            std.debug.assert(needle[i] < self.offset[i] + self.width);
        }
    
        var index: usize = 0; 

        for (0..3) |i| {
            if (needle[i] >= self.offset[i] + self.width / 2) {
                index |= @as(usize, 1) << @intCast(i);
            }
        }

        return index;
    }

    pub fn closestPointTo(self: BranchNode, point: [3]u64) [3]u64 {
        var closest_point: [3]u64 = undefined;
        for (0..3) |i| {
            const min = self.offset[i];
            const max = self.offset[i] + self.width;

            closest_point[i] = @max(min, @min(max, point[i]));
        }
        return closest_point;
    }

    pub fn sqDistanceTo(self: BranchNode, point: [3]u64) u64 {
        const closest_point = self.closestPointTo(point);

        var sqDist: u64 = 0;
        for (0..3) |i| {
            const dist = @max(closest_point[i], point[i]) - @min(closest_point[i], point[i]);
            sqDist += dist * dist;
        }
        return sqDist;
    }
};

pub fn Node(T: type) type {
    return union(enum) {
        const Self = @This();

        pub const Leaf = struct {
            point: [3]u64,
            data: T,
        };

        leaf: Leaf,
        branch: BranchNode,

        pub fn sqDistanceTo(self: Self, point: [3]u64) u64 {
            var closest_point: [3]u64 = undefined;
            switch (self) {
                .leaf => |leaf| closest_point = leaf.point,
                .branch => |branch| closest_point = branch.closestPointTo(point),
            }

            var sqDist: u64 = 0;
            for (0..3) |i| {
                const dist = @max(closest_point[i], point[i]) - @min(closest_point[i], point[i]);
                sqDist += dist * dist;
            }
            return sqDist;
        }
    };
}

pub fn Octree(T: type) type {
    return struct {
        const Self = @This();

        // Root is first element
        nodes: ArrayList(Node(T)),
        count: usize,

        pub fn init(allocator: Allocator, max_width: u64) error{OutOfMemory, Overflow}!Self {
            var nodes: ArrayList(Node(T)) = .empty;
            errdefer nodes.deinit(allocator);

            const width = try std.math.ceilPowerOfTwo(u64, max_width);

            try nodes.append(allocator, Node(T){ .branch = BranchNode {
                .branches = [_]?usize{null} ** 8,
                .width = width,
                .offset = [_]u64{0, 0, 0}
            }});


            return .{
                .nodes = nodes,
                .count = 0,
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.nodes.deinit(allocator);
        }

        /// Returns true if and only if the needle is contained in the octree.
        pub fn contains(self: *Self, needle: [3]u64) bool {
            if (self.count == 0) return false;

            var node: Node(T) = self.nodes.items[0];
            while (true) {
                switch (node) {
                    .leaf => |leaf| return std.mem.eql(u64, &leaf.point, &needle),
                    .branch => |branch| {
                        if (branch.branches[branch.indexOfBranchWithPoint(needle)]) |node_idx| {
                            node = self.nodes.items[node_idx];
                        } else {
                            return false;
                        }
                    }
                }
            }
        }

        /// Insert a new point into the octree. If the point already exists
        /// the tree will be unchanged.
        pub fn insert(self: *Self, allocator: Allocator, point: [3]u64, data: T) !void {
            var node_idx: usize = 0;

            while (true) {
                const node = &self.nodes.items[node_idx];

                std.debug.assert(node.* == .branch);
                const branch = &node.branch;

                const child_branch_idx = branch.indexOfBranchWithPoint(point);
                if (branch.branches[child_branch_idx]) |child_node_idx| {
                    const child_node = self.nodes.items[child_node_idx];
                    switch (child_node) {
                        .branch => node_idx = child_node_idx,
                        .leaf => |leaf| {
                            // Edge case when found leaf is same as point, nothing needs to be done
                            if (std.mem.eql(u64, &leaf.point, &point)) return;

                            // This leaf needs to be replaced by a new branch

                            var new_branch = Node(T) { .branch = createSubBranch(branch.*, child_branch_idx) };
                            // The new branch needs to point to existing leaf
                            new_branch.branch.branches[new_branch.branch.indexOfBranchWithPoint(leaf.point)] = self.nodes.items.len;

                            self.nodes.items[child_node_idx] = new_branch;

                            // We need a new leaf node to represent the leaf that was previously here
                            const new_leaf = Node(T) { .leaf = leaf };
                            try self.nodes.append(allocator, new_leaf);

                            node_idx = child_node_idx;
                        },
                    }
                } else {
                    // There's nothing at this child branch, so we can insert a new leaf here and finish
                    const new_leaf = Node(T) { .leaf = .{ .point = point, .data = data } };
                    branch.branches[child_branch_idx] = self.nodes.items.len;
                    // Append may move node / branch so we should do it after modifying branches
                    try self.nodes.append(allocator, new_leaf);
                    self.count += 1;
                    return;
                }
            }
        }

        /// Create a sub branch with a width and offset appropriate for the given branch_idx
        fn createSubBranch(parent: BranchNode, branch_idx: usize) BranchNode {
            var offset = parent.offset;
            for (0..3) |i| {
                if ((branch_idx >> @intCast(i)) & 1 == 1) {
                    offset[i] += parent.width / 2;
                }
            }

            return BranchNode{
                .branches = .{null} ** 8,
                .width = parent.width / 2,
                .offset = offset,
            };
        }

        pub const NNIterator = struct {
            tree: *const Octree(T),
            target: [3]u64,
            heap: MinHeap(HeapItem, HeapItem.lt),

            const HeapItem = struct {
                idx: usize,
                sq_dist: u64,

                pub fn lt(lhs: HeapItem, rhs: HeapItem) bool {
                    return lhs.sq_dist < rhs.sq_dist;
                }
            };

            pub fn init(tree: *const Octree(T), allocator: Allocator, target: [3]u64) !NNIterator {
                const tracy_zone = ztracy.ZoneN(@src(), "NNIterator init");
                defer tracy_zone.End();

                var heap = try MinHeap(HeapItem, HeapItem.lt)
                    .initCapacity(allocator, tree.nodes.items.len / 10);
                errdefer heap.deinit(allocator);

                const root = tree.nodes.items[0];
                std.debug.assert(root == .branch);

                try heap.insert(allocator, .{
                    .idx = 0, 
                    .sq_dist = root.branch.sqDistanceTo(target),
                });

                return .{
                    .tree = tree,
                    .target = target,
                    .heap = heap,
                };
            }

            pub fn deinit(self: *NNIterator, allocator: Allocator) void {
                self.heap.deinit(allocator);
            }

            pub fn next(it: *NNIterator, allocator: Allocator) !?Node(T).Leaf {
                while (it.heap.pop()) |heap_item| {
                    const tracy_zone = ztracy.ZoneN(@src(), "NNIterator next process heap item");
                    defer tracy_zone.End();

                    const node = &it.tree.nodes.items[heap_item.idx];
                    switch (node.*) {
                        .leaf => |leaf| return leaf,
                        .branch => |branch| {
                            for (branch.branches) |child_node_idx_opt| {
                                if (child_node_idx_opt == null) continue;

                                const child_node_idx = child_node_idx_opt.?;
                                const child_node = it.tree.nodes.items[child_node_idx];
                                const dist = child_node.sqDistanceTo(it.target);
                                try it.heap.insert(allocator, .{
                                    .idx = child_node_idx,
                                    .sq_dist = dist,
                                });
                            }
                        },
                    }
                } 

                return null;
            }
        };

        pub fn iterator(self: *const Self, allocator: Allocator, target: [3]u64) !NNIterator {
            return try NNIterator.init(self, allocator, target);
        }
    };
}


test "root width" {
    {
        var octree = try Octree(void).init(testing.allocator, 1023);
        defer octree.deinit(testing.allocator);

        try testing.expectEqual(1024, octree.nodes.items[0].branch.width);
    }
    {
        var octree = try Octree(void).init(testing.allocator, 1024);
        defer octree.deinit(testing.allocator);

        try testing.expectEqual(1024, octree.nodes.items[0].branch.width);
    }
}

test "indexOfBranchWithPoint no offset" {
    const branch = BranchNode{
        .offset = [3]u64{0, 0, 0},
        .width = 64,
        .branches = [_]?usize{null} ** 8,
    };
    // 0..32 and 32..64

    try testing.expectEqual(0, branch.indexOfBranchWithPoint([3]u64{0, 0, 0}));
    try testing.expectEqual(0, branch.indexOfBranchWithPoint([3]u64{31, 31, 31}));

    try testing.expectEqual(1, branch.indexOfBranchWithPoint([3]u64{32, 0, 0}));
    try testing.expectEqual(1, branch.indexOfBranchWithPoint([3]u64{63, 31, 31}));

    try testing.expectEqual(2, branch.indexOfBranchWithPoint([3]u64{0, 32, 0}));
    try testing.expectEqual(2, branch.indexOfBranchWithPoint([3]u64{31, 63, 31}));

    try testing.expectEqual(3, branch.indexOfBranchWithPoint([3]u64{32, 32, 0}));
    try testing.expectEqual(3, branch.indexOfBranchWithPoint([3]u64{63, 63, 31}));

    try testing.expectEqual(4, branch.indexOfBranchWithPoint([3]u64{0, 0, 32}));
    try testing.expectEqual(4, branch.indexOfBranchWithPoint([3]u64{31, 31, 63}));

    try testing.expectEqual(5, branch.indexOfBranchWithPoint([3]u64{32, 0, 32}));
    try testing.expectEqual(5, branch.indexOfBranchWithPoint([3]u64{63, 31, 63}));

    try testing.expectEqual(6, branch.indexOfBranchWithPoint([3]u64{0, 32, 32}));
    try testing.expectEqual(6, branch.indexOfBranchWithPoint([3]u64{31, 63, 63}));

    try testing.expectEqual(7, branch.indexOfBranchWithPoint([3]u64{32, 32, 32}));
    try testing.expectEqual(7, branch.indexOfBranchWithPoint([3]u64{63, 63, 63}));
}

fn addPoints(p1: [3]u64, p2: [3]u64) [3]u64 {
    return .{
        p1[0] + p2[0],
        p1[1] + p2[1],
        p1[2] + p2[2],
    };
}

test "indexOfBranchWithPoint with offset" {
    const offset: [3]u64 = .{13, 45, 72};
    const branch = BranchNode{
        .offset = offset,
        .width = 64,
        .branches = [_]?usize{null} ** 8,
    };
    // 0..32 and 32..64

    try testing.expectEqual(0, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{0, 0, 0})));
    try testing.expectEqual(0, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{31, 31, 31})));

    try testing.expectEqual(1, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{32, 0, 0})));
    try testing.expectEqual(1, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{63, 31, 31})));

    try testing.expectEqual(2, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{0, 32, 0})));
    try testing.expectEqual(2, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{31, 63, 31})));

    try testing.expectEqual(3, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{32, 32, 0})));
    try testing.expectEqual(3, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{63, 63, 31})));

    try testing.expectEqual(4, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{0, 0, 32})));
    try testing.expectEqual(4, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{31, 31, 63})));

    try testing.expectEqual(5, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{32, 0, 32})));
    try testing.expectEqual(5, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{63, 31, 63})));

    try testing.expectEqual(6, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{0, 32, 32})));
    try testing.expectEqual(6, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{31, 63, 63})));

    try testing.expectEqual(7, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{32, 32, 32})));
    try testing.expectEqual(7, branch.indexOfBranchWithPoint(addPoints(offset, [3]u64{63, 63, 63})));
}

test "contains when empty" {
    var octree = try Octree(void).init(testing.allocator, 16);
    defer octree.deinit(testing.allocator);

    try testing.expect(!octree.contains(.{0, 0, 0}));
}

test "insert" {
    var octree = try Octree(void).init(testing.allocator, 16);
    defer octree.deinit(testing.allocator);

    try octree.insert(testing.allocator, .{0, 0, 0}, {});
    try octree.insert(testing.allocator, .{15, 15, 15}, {});
    try octree.insert(testing.allocator, .{0, 1, 0}, {});

    try testing.expectEqual(3, octree.count);
    try testing.expect(octree.contains(.{0, 0, 0}));
    try testing.expect(octree.contains(.{15, 15, 15}));
    try testing.expect(octree.contains(.{0, 1, 0}));
}

test "insert repeat" {
    var octree = try Octree(void).init(testing.allocator, 16);
    defer octree.deinit(testing.allocator);

    try octree.insert(testing.allocator, .{0, 0, 0}, {});
    try octree.insert(testing.allocator, .{0, 0, 0}, {});

    try testing.expect(octree.contains(.{0, 0, 0}));
}

test "nearest neighbour iterator" {
    var octree = try Octree(u8).init(testing.allocator, 16);
    defer octree.deinit(testing.allocator);

    try octree.insert(testing.allocator, .{0, 0, 0}, 0);
    try octree.insert(testing.allocator, .{1, 0, 0}, 1);
    try octree.insert(testing.allocator, .{2, 0, 0}, 2);
    try octree.insert(testing.allocator, .{3, 0, 0}, 3);
    try octree.insert(testing.allocator, .{4, 0, 0}, 4);
    try octree.insert(testing.allocator, .{5, 0, 0}, 5);

    var iter = try octree.iterator(testing.allocator, .{10, 0, 0});
    defer iter.deinit(testing.allocator);

    try testing.expectEqual(Node(u8).Leaf{.point = .{5, 0, 0}, .data = 5 }, try iter.next(testing.allocator));
    try testing.expectEqual(Node(u8).Leaf{.point = .{4, 0, 0}, .data = 4 }, try iter.next(testing.allocator));
    try testing.expectEqual(Node(u8).Leaf{.point = .{3, 0, 0}, .data = 3 }, try iter.next(testing.allocator));
    try testing.expectEqual(Node(u8).Leaf{.point = .{2, 0, 0}, .data = 2 }, try iter.next(testing.allocator));
    try testing.expectEqual(Node(u8).Leaf{.point = .{1, 0, 0}, .data = 1 }, try iter.next(testing.allocator));
    try testing.expectEqual(Node(u8).Leaf{.point = .{0, 0, 0}, .data = 0 }, try iter.next(testing.allocator));
    try testing.expectEqual(null, iter.next(testing.allocator));
}
