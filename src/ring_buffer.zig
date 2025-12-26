pub fn RingBuffer(T: type) type {
    return struct {
        const Self = @This();

        buf: []T,
        start: usize,
        end: usize,

        pub fn init(buf: []T) Self {
            return .{
                .buf = buf,
                .start = 0,
                .end = 0,
            };
        }

        pub fn isEmpty(self: Self) bool {
            return self.start == self.end;
        }

        pub fn isFull(self: Self) bool {
            return !self.isEmpty() 
                and (self.start % self.buf.len == self.end % self.buf.len);
        }

        pub fn clear(self: *Self) void {
            self.start = 0;
            self.end = 0;
        }

        /// Add an item to the end of the ring buffer.
        /// Will replace the first item if the ring buffer is full.
        pub fn pushBack(self: *Self, item: T) void {
            const item_idx = self.end % self.buf.len;

            self.buf[item_idx] = item;

            if (self.isFull()) {
                self.incStart();
            }
            self.incEnd();
        }

        pub fn popFront(self: *Self) ?T {
            if (self.isEmpty()) return null;

            const item_idx = self.start % self.buf.len;

            self.incStart();

            return self.buf[item_idx];
        }

        fn incStart(self: *Self) void {
            self.start += 1;
            self.start %= 2 * self.buf.len;
        }

        fn incEnd(self: *Self) void {
            self.end += 1;
            self.end %= 2 * self.buf.len;
        }
    };
}
