const std = @import("std");
const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const aoc2025 = @import("aoc2025");
const Solution= aoc2025.Solution;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) {
            std.debug.print("Memory leaked\n", .{});
        } else {
            std.debug.print("All memory freed :)\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // Set up stdout
    const stdout_buf = try allocator.alloc(u8, 1024);
    defer allocator.free(stdout_buf);
    var stdout = std.fs.File.writer(std.fs.File.stdout(), stdout_buf).interface;

    // Directory with input files
    var input_dir = try std.fs.cwd().openDir("inputs/real/", .{});
    defer input_dir.close();

    // All solutions
    const runners = [_]SolutionRunner{
        solution_runner(u32, u32, aoc2025.solution_1),
        solution_runner(u64, u64, aoc2025.solution_2),
    };

    for (runners, 1..) |runner, day_n| {
        const solution_info = try runner(allocator, input_dir, @as(u32, @intCast(day_n)));
        defer solution_info.deinit(allocator);

        try stdout.print("Day {d}, {d} ms:\n  Part 1: {s}\n  Part 2: {s}\n", .{day_n, solution_info.duration_ns / 1000, solution_info.part1, solution_info.part2});
        try stdout.flush();
    }
}

const SolutionInfo = struct {
    duration_ns: u64,
    part1: []u8,
    part2: []u8,

    pub fn deinit(self: SolutionInfo, allocator: Allocator) void {
        allocator.free(self.part1);
        allocator.free(self.part2);
    }
};

const SolutionRunner = *const fn(allocator: Allocator, input_dir: std.fs.Dir, day_n: u32) anyerror!SolutionInfo;

pub fn solution_runner(
    comptime T: type, 
    comptime U: type, 
    solution: fn(Allocator, []const u8) anyerror!Solution(T, U)
) SolutionRunner {
    const Runner = struct {
        pub fn run(allocator: Allocator, input_dir: std.fs.Dir, day_n: u32) !SolutionInfo {
            const filename = try std.fmt.allocPrint(allocator, "{d}", .{day_n});
            defer allocator.free(filename);
            
            const file = try input_dir.openFile(filename, .{});
            defer file.close();

            const file_size: u64 = try file.getEndPos();
            const file_buf: []u8 = try allocator.alloc(u8, file_size);
            defer allocator.free(file_buf);

            var file_reader: std.fs.File.Reader = file.reader(file_buf);
            const file_ioreader: *std.Io.Reader = &file_reader.interface;

            try file_ioreader.readSliceAll(file_buf);
            const trimmed_file_buf = std.mem.trimEnd(u8, file_buf, &[_]u8{'\n'});

            const start_time = try Instant.now();
            const sol = try solution(allocator, trimmed_file_buf);
            const end_time = try Instant.now();
            const duration_ns = end_time.since(start_time);

            const part1: []u8 = try std.fmt.allocPrint(allocator, "{any}", .{sol.part1});
            const part2: []u8 = try std.fmt.allocPrint(allocator, "{any}", .{sol.part2});

            return SolutionInfo {
                .duration_ns = duration_ns,
                .part1 = part1,
                .part2 = part2,
            };
        }
    };
    return Runner.run;
}
