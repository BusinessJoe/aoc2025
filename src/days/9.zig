const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const ztracy = @import("ztracy");

const DayResult = @import("../framework.zig").DayResult;

const Pair = struct {
    x: u32,
    y: u32,

    pub fn parse(str: []const u8) !Pair {
        var tokens = std.mem.splitScalar(u8, str, ',');

        const str_x = tokens.next() orelse return error.ExpectedToken; 
        const str_y = tokens.next() orelse return error.ExpectedToken; 

        const x = try std.fmt.parseInt(u32, str_x, 10);
        const y = try std.fmt.parseInt(u32, str_y, 10);

        return Pair{
            .x = x * 2,
            .y = y * 2,
        };
    }
};

const LineDir = enum {
    vert,
    hori,
};

const Line = struct {
    dir: LineDir,
    perp_dist: u32,
    /// Inclusive
    start: u32,
    /// Inclusive
    end: u32,

    pub fn lt(context: void, lhs: Line, rhs: Line) bool {
        _ = context;
        return lhs.perp_dist < rhs.perp_dist;
    }

    pub fn fromPair(point1: Pair, point2: Pair) Line {
        var line: Line = undefined;
        if (point1.x == point2.x) {
            line = Line{
                .dir = .vert,
                .perp_dist = point1.x,
                .start = @min(point1.y, point2.y),
                .end = @max(point1.y, point2.y),
            };
        } else {
            std.debug.assert(point1.y == point2.y);
            line = Line{
                .dir = .hori,
                .perp_dist = point1.y,
                .start = @min(point1.x, point2.x),
                .end = @max(point1.x, point2.x),
            };
        }

        return line;
    }
};

const Shape = struct {
    lines_vert: ArrayList(Line),
    lines_hori: ArrayList(Line),

    pub fn init(allocator: Allocator, points: []Pair) !Shape {
        var lines_vert: ArrayList(Line) = .empty;
        errdefer lines_vert.deinit(allocator);

        var lines_hori: ArrayList(Line) = .empty;
        errdefer lines_hori.deinit(allocator);

        for (points, 0..) |point1, i| {
            const point2_idx = if (i == points.len - 1) 0 else i + 1;
            const point2 = points[point2_idx];

            if (point1.x == point2.x) {
                const line = Line{
                    .dir = .vert,
                    .perp_dist = point1.x,
                    .start = @min(point1.y, point2.y),
                    .end = @max(point1.y, point2.y),
                };
                try lines_vert.append(allocator, line);
            } else {
                std.debug.assert(point1.y == point2.y);
                const line = Line{
                    .dir = .hori,
                    .perp_dist = point1.y,
                    .start = @min(point1.x, point2.x),
                    .end = @max(point1.x, point2.x),
                };
                try lines_hori.append(allocator, line);
            }
        }

        std.sort.pdq(Line, lines_hori.items, {}, Line.lt);
        std.sort.pdq(Line, lines_vert.items, {}, Line.lt);

        return Shape{
            .lines_hori = lines_hori,
            .lines_vert = lines_vert,
        };
    }

    pub fn deinit(self: *Shape, allocator: Allocator) void {
        self.lines_hori.deinit(allocator);
        self.lines_vert.deinit(allocator);
    }

    fn containsLineHori(self: Shape, line: Line) bool {
        std.debug.assert(line.dir == .hori);
        return self.containsLine(line, self.lines_vert.items);
    }

    fn containsLineVert(self: Shape, line: Line) bool {
        std.debug.assert(line.dir == .vert);
        return self.containsLine(line, self.lines_hori.items);
    }

    fn containsLine(self: Shape, needle: Line, sorted_lines: []Line) bool {
        _ = self;

        for (sorted_lines) |line| {
            if (line.start < needle.perp_dist and needle.perp_dist < line.end
                and needle.start < line.perp_dist and line.perp_dist < needle.end) {
                std.debug.print("{any} intersects with {any}\n", .{needle, line});
                return false;
            }
        }
        return true;
    }

    fn containsArea(self: Shape, point1: Pair, point2: Pair) bool {
        if (point1.y != point2.y and !self.containsLineVert(
                Line.fromPair(point1, Pair{.x = point1.x, .y = point2.y}))) {
            return false;
        }
        if (point1.x != point2.x and !self.containsLineHori(
                Line.fromPair(point1, Pair{.x = point2.x, .y = point1.y}))) {
            return false;
        }
        if (point1.x != point2.x and !self.containsLineHori(
                Line.fromPair(point2, Pair{.x = point1.x, .y = point2.y}))) {
            return false;
        }
        if (point1.y != point2.y and !self.containsLineVert(
                Line.fromPair(point2, Pair{.x = point2.x, .y = point1.y}))) {
            return false;
        }

        return true;
    }
};

fn absDiff(a: u32, b: u32) u32 {
    return if (a > b) a - b else b - a;
}

fn calcArea(pair1: Pair, pair2: Pair) u64 {
    const width = @as(u64, @intCast(absDiff(pair1.x, pair2.x))) + 2;
    const height = @as(u64, @intCast(absDiff(pair1.y, pair2.y))) + 2;
    return width * height;
}

pub fn solution(allocator: Allocator, input: []const u8, part1_buf: []u8, part2_buf: []u8) !DayResult {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var pairs: ArrayList(Pair) = .empty;
    defer pairs.deinit(allocator);

    while (lines.next()) |line| {
        const pair = try Pair.parse(line);
        try pairs.append(allocator, pair);
    }

    var shape = try Shape.init(allocator, pairs.items);
    defer shape.deinit(allocator);

    var max_area: u64 = 0;

    // Part 2 requires that the area be interior to the overall shape
    var max_area_inter: u64 = 0;

    for (pairs.items, 0..) |pair1, i| {
        for (pairs.items[i + 1..]) |pair2| {
            max_area = @max(max_area, calcArea(pair1, pair2));

            std.debug.print("== {any} {any}\n", .{pair1, pair2});
            if (shape.containsArea(pair1, pair2)) {
                std.debug.print("contains\n", .{});
                max_area_inter = @max(max_area_inter, calcArea(pair1, pair2));
            }
        }
    }

    return DayResult.both_parts(part1_buf, part2_buf, max_area / 4, max_area_inter / 4);
}
