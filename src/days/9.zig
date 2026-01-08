const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const ztracy = @import("ztracy");

const DayResult = @import("../framework.zig").DayResult;

const Bias = enum {
    low,
    high,

    pub fn val(self: Bias) u32 {
        if (self == .low) return 0;
        return 1;
    }
};

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
            .x = x,
            .y = y,
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
    bias_x: []Bias,
    bias_y: []Bias,

    pub fn init(allocator: Allocator, points: []Pair) !Shape {
        var lines_vert: ArrayList(Line) = .empty;
        errdefer lines_vert.deinit(allocator);

        var lines_hori: ArrayList(Line) = .empty;
        errdefer lines_hori.deinit(allocator);

        var bias_x = try allocator.alloc(Bias, points.len);
        errdefer allocator.free(bias_x);

        var bias_y = try allocator.alloc(Bias, points.len);
        errdefer allocator.free(bias_y);

        for (points, 0..) |point1, i| {
            const point0_idx = if (i == 0) points.len - 1 else i - 1;
            const point0 = points[point0_idx];

            const point2_idx = if (i == points.len - 1) 0 else i + 1;
            const point2 = points[point2_idx];

            const dir1: LineDir = if (point0.x == point1.x) .vert else .hori;
            const dir2: LineDir = if (point1.x == point2.x) .vert else .hori;

            bias_x[i] = .low;
            bias_y[i] = .low;
            if (dir1 == .vert and dir2 == .hori) {
                if (point0.y < point1.y) bias_x[i] = .high;
                if (point1.x > point2.x) bias_y[i] = .high;
            } else if (dir1 == .hori and dir2 == .vert) {
                if (point0.x > point1.x) bias_y[i] = .high;
                if (point1.y < point2.y) bias_x[i] = .high;
            } else {
                return error.InvalidCoords;
            }
        }

        for (points, 0..) |point1, i| {
            const point2_idx = if (i == points.len - 1) 0 else i + 1;
            const point2 = points[point2_idx];

            const x1 = 2 * point1.x + bias_x[i].val();
            const y1 = 2 * point1.y + bias_y[i].val();
            const x2 = 2 * point2.x + bias_x[point2_idx].val();
            const y2 = 2 * point2.y + bias_y[point2_idx].val();

            if (x1 == x2) {
                const line = Line{
                    .dir = .vert,
                    .perp_dist = x1,
                    .start = @min(y1, y2),
                    .end = @max(y1, y2),
                };
                try lines_vert.append(allocator, line);
            } else {
                std.debug.assert(y1 == y2);
                const line = Line{
                    .dir = .hori,
                    .perp_dist = y1,
                    .start = @min(x1, x2),
                    .end = @max(x1, x2),
                };
                try lines_hori.append(allocator, line);
            }
        }

        std.sort.pdq(Line, lines_hori.items, {}, Line.lt);
        std.sort.pdq(Line, lines_vert.items, {}, Line.lt);

        return Shape{
            .lines_hori = lines_hori,
            .lines_vert = lines_vert,
            .bias_x = bias_x,
            .bias_y = bias_y,
        };
    }

    pub fn deinit(self: *Shape, allocator: Allocator) void {
        self.lines_hori.deinit(allocator);
        self.lines_vert.deinit(allocator);
        allocator.free(self.bias_x);
        allocator.free(self.bias_y);
    }

    fn noIntersectionsHori(self: Shape, line: Line) bool {
        if (line.end - line.start <= 1) return true;

        std.debug.assert(line.dir == .hori);
        return noIntersections(line, self.lines_vert.items);
    }

    fn noIntersectionsVert(self: Shape, line: Line) bool {
        if (line.end - line.start <= 1) return true;

        std.debug.assert(line.dir == .vert);
        return noIntersections(line, self.lines_hori.items);
    }

    fn noIntersections(needle: Line, sorted_lines: []Line) bool {

        for (sorted_lines) |line| {
            if (line.perp_dist <= needle.start) continue;
            if (line.perp_dist >= needle.end) continue;

            if (line.start <= needle.perp_dist and needle.perp_dist <= line.end) return false;
        }
        return true;
    }

    fn containsPoint(self: Shape, point: Pair) bool {
        var hit_count: u32 = 0;

        for (self.lines_vert.items) |line| {
            // Exclude lines to the right of the point
            if (line.perp_dist > point.x) continue;

            if (line.start <= point.y and point.y <= line.end) {
                hit_count += 1;
            }
        }

        return hit_count % 2 == 1;
    }

    fn containsArea(self: Shape, point1Unbiased: Pair, point1Idx: usize, point2Unbiased: Pair, point2Idx: usize) bool {
        
        const x1 = 2 * (point1Unbiased.x - self.bias_x[point1Idx].val()) + 1;
        const y1 = 2 * (point1Unbiased.y - self.bias_y[point1Idx].val()) + 1;
        const x2 = 2 * (point2Unbiased.x - self.bias_x[point2Idx].val()) + 1;
        const y2 = 2 * (point2Unbiased.y - self.bias_y[point2Idx].val()) + 1;

        const point1 = Pair{.x = x1, .y = y1};
        const point2 = Pair{.x = x2, .y = y2};
        const point3 = Pair{.x = x1, .y = y2};
        const point4 = Pair{.x = x2, .y = y1};

        if (!self.containsPoint(point1)) {
            return false;
        }
        if (!self.containsPoint(point2)) {
            return false;
        }
        if (!self.containsPoint(point3)) {
            return false;
        }
        if (!self.containsPoint(point4)) {
            return false;
        }

        if (!self.noIntersectionsVert(Line.fromPair(point1, point3))) {
            return false;
        }
        if (!self.noIntersectionsHori(Line.fromPair(point1, point4))) {
            return false;
        }
        if (!self.noIntersectionsHori(Line.fromPair(point2, point3))) {
            return false;
        }
        if (!self.noIntersectionsVert(Line.fromPair(point2, point4))) {
            return false;
        }

        return true;
    }
};

fn absDiff(a: u32, b: u32) u32 {
    return if (a > b) a - b else b - a;
}

fn calcArea(pair1: Pair, pair2: Pair) u64 {
    const width = @as(u64, @intCast(absDiff(pair1.x, pair2.x))) + 1;
    const height = @as(u64, @intCast(absDiff(pair1.y, pair2.y))) + 1;
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

    for (pairs.items, 0..) |pair1, p1Idx| {
        for (pairs.items[p1Idx + 1..], p1Idx + 1..) |pair2, p2Idx| {
            max_area = @max(max_area, calcArea(pair1, pair2));

            const valid = shape.containsArea(pair1, p1Idx, pair2, p2Idx);
            if (valid) {
                max_area_inter = @max(max_area_inter, calcArea(pair1, pair2));
            }
        }
    }

    return DayResult.both_parts(part1_buf, part2_buf, max_area, max_area_inter);
}
