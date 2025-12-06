const std = @import("std");
const Allocator = std.mem.Allocator;
const DayResult = @import("../framework.zig").DayResult;

const InputStage = enum {
    FreshRange,
    Ingredients,
};

const Range = struct { u64, u64 };

const Marker = struct {
    val: u64,
    start: bool,
};

fn markerLessThan(ctx: void, first: Marker, second: Marker) bool {
    _ = ctx;
    return first.val < second.val;
}

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    var part1: u32 = 0;

    var stage: InputStage = .FreshRange;

    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(allocator);

    var markers: std.ArrayList(Marker) = .empty;
    defer markers.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            std.debug.assert(stage == .FreshRange);
            stage = .Ingredients;
            continue;
        }

        switch (stage) {
            .FreshRange => {
                var id_iter = std.mem.splitScalar(u8, line, '-');
                const id_low_str = id_iter.next() orelse return error.IdNotFound;
                const id_high_str = id_iter.next() orelse return error.IdNotFound;

                const id_low = try std.fmt.parseInt(u64, id_low_str, 10);
                const id_high = try std.fmt.parseInt(u64, id_high_str, 10);

                try ranges.append(allocator, .{ id_low, id_high });
                try markers.append(allocator, .{ .val = id_low, .start = true });
                // End of marker should be exclusive
                try markers.append(allocator, .{ .val = id_high + 1, .start = false });
            },
            .Ingredients => {
                const id = try std.fmt.parseInt(u64, line, 10);

                for (ranges.items) |range| {
                    const low, const high = range;
                    if (low <= id and id <= high) {
                        part1 += 1;
                        break;
                    }
                }
            },
        }
    }

    var part2: u64 = 0;
    std.mem.sortUnstable(Marker, markers.items, {}, markerLessThan);

    var depth: u32 = 0;
    var start: u64 = 0;
    for (markers.items) |marker| {
        if (marker.start) {
            if (depth == 0) start = marker.val;
            depth += 1;
        } else {
            depth -= 1;
            if (depth == 0) part2 += marker.val - start;
        }
    }

    return DayResult.both_parts(part1_buf, part2_buf, part1, part2);
}
