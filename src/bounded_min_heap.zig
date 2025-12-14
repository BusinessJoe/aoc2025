const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn BoundedMinHeap(comptime T: type, lessThanFn: fn (T, T) bool) type {
    return struct {
        const Self = @This();

        buffer: []T,
        count: usize,

        pub fn initCapacity(
            allocator: Allocator, 
            capacity: usize, 
        ) error{OutOfMemory}!Self {
            const buffer: []T = try allocator.alloc(T, capacity);
            errdefer allocator.free(buffer);

            return .{
                .buffer = buffer,
                .count = 0,
            };
        }

        pub fn deinit(self: Self, allocator: Allocator) void {
            allocator.free(self.buffer);
        }

        pub fn peek(self: Self) ?T {
            if (self.count == 0) return null;
            return self.buffer[0];
        }

        pub fn insert(self: *Self, item: T) error{OutOfSpace}!void {
            if (self.count >= self.buffer.len) return error.OutOfSpace;

            self.buffer[self.count] = item;

            self.count += 1;

            self.siftUp(self.count - 1);
        }

        pub fn pop(self: *Self) ?T {
            if (self.count == 0) return null;

            const min_item = self.buffer[0];

            self.buffer[0] = self.buffer[self.count - 1];

            self.count -= 1;

            self.siftDown(0);

            return min_item;
        }

        fn siftUp(self: *Self, index: usize) void {
            var child_index = index;
            while (child_index > 0 
                and lessThanFn(self.buffer[child_index], self.buffer[parentIndex(child_index)])) {
                const tmp = self.buffer[child_index];
                self.buffer[child_index] = self.buffer[parentIndex(child_index)];
                self.buffer[parentIndex(child_index)] = tmp;
                child_index = parentIndex(child_index);
            }
        }

        fn siftDown(self: *Self, index: usize) void {
            var parent_index = index;

            while (true) {
                const left_child_index = leftChildIndex(parent_index);
                const right_child_index = rightChildIndex(parent_index);

                var to_swap_index_opt: ?usize = null;

                if (left_child_index < self.count and lessThanFn(self.buffer[left_child_index], self.buffer[parent_index])) {
                    to_swap_index_opt = left_child_index;
                }

                if (right_child_index < self.count and lessThanFn(self.buffer[right_child_index], self.buffer[parent_index])) {
                    if (to_swap_index_opt == null or lessThanFn(self.buffer[right_child_index], self.buffer[to_swap_index_opt.?])) {
                        to_swap_index_opt = right_child_index;
                    } 
                }

                if (to_swap_index_opt) |to_swap_index| {
                    // Swap
                    const tmp = self.buffer[parent_index];
                    self.buffer[parent_index] = self.buffer[to_swap_index];
                    self.buffer[to_swap_index] = tmp;

                    parent_index = to_swap_index;
                } else {
                    break;
                }
            }
        }

        fn leftChildIndex(parent_index: usize) usize {
            return 2 * parent_index + 1;
        }

        fn rightChildIndex(parent_index: usize) usize {
            return 2 * parent_index + 2;
        }

        fn parentIndex(child_index: usize) usize {
            return (child_index - 1) / 2;
        }
    };
}


fn i32LessThan(lhs: i32, rhs: i32) bool {
    return lhs < rhs;
}

test "insert past capacity" {
    const allocator = testing.allocator;

    var heap = try BoundedMinHeap(i32, i32LessThan).initCapacity(allocator, 3);
    defer heap.deinit(allocator);

    try heap.insert(0);
    try heap.insert(0);
    try heap.insert(0);

    try testing.expectError(error.OutOfSpace, heap.insert(0));
}

test "peek after inserts" {
    const allocator = testing.allocator;

    var heap = try BoundedMinHeap(i32, i32LessThan).initCapacity(allocator, 3);
    defer heap.deinit(allocator);

    try heap.insert(0);
    try testing.expectEqual(0, heap.peek());

    try heap.insert(1);
    try testing.expectEqual(0, heap.peek());

    try heap.insert(-1);
    try testing.expectEqual(-1, heap.peek());
}

test "peek while empty" {
    const allocator = testing.allocator;

    var heap = try BoundedMinHeap(i32, i32LessThan).initCapacity(allocator, 3);
    defer heap.deinit(allocator);

    try testing.expectEqual(null, heap.peek());
}

test "pop while empty" {
    const allocator = testing.allocator;

    var heap = try BoundedMinHeap(i32, i32LessThan).initCapacity(allocator, 3);
    defer heap.deinit(allocator);

    try testing.expectEqual(null, heap.pop());
}

test "insert and pop" {
    const allocator = testing.allocator;

    var heap = try BoundedMinHeap(i32, i32LessThan).initCapacity(allocator, 3);
    defer heap.deinit(allocator);

    try heap.insert(0);
    try testing.expectEqual(0, heap.pop());

    try heap.insert(0);
    try heap.insert(1);
    try heap.insert(-1);

    try testing.expectEqual(-1, heap.pop());
    try testing.expectEqual(0, heap.pop());
    try testing.expectEqual(1, heap.pop());

    try testing.expectEqual(0, heap.count);
}

const Ctx = struct { 
    allocator: Allocator,
};

fn fuzzLessThanFnWithCtx(ctx: void, lhs: u32, rhs: u32) bool {
    _ = ctx;
    return lhs < rhs;
}

fn fuzzLessThanFn(lhs: u32, rhs: u32) bool {
    return lhs < rhs;
}

fn testHeapSort(ctx: Ctx, input: []const u32) !void {
    const allocator = ctx.allocator;
    
    var heap = try BoundedMinHeap(u32, fuzzLessThanFn).initCapacity(allocator, input.len);
    defer heap.deinit(allocator);

    for (input) |item| {
        try heap.insert(item);
    }

    const heap_sorted = try allocator.alloc(u32, input.len);
    defer allocator.free(heap_sorted);

    for (heap_sorted) |*item| {
        item.* = heap.pop().?;
    }

    const std_sorted = try allocator.dupe(u32, input);
    defer allocator.free(std_sorted);

    std.mem.sort(u32, std_sorted, {}, fuzzLessThanFnWithCtx);

    try testing.expectEqualSlices(u32, std_sorted, heap_sorted);
}

test "fuzz heap sort" {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    for (0..1000) |_| {
        const input: []u32 = try testing.allocator.alloc(u32, 10);
        defer testing.allocator.free(input);
        for (input) |*item| {
            item.* = rand.int(u32);
        }

        try testHeapSort(Ctx{.allocator = testing.allocator}, input);
    }
}
