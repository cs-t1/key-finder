//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

// Holds the 
const WindowContextBuffer = struct {
    buf: [256]u8,
    is_full: bool = false,
    // NOTE: whatchout to keep this at the exact size to prevent overflows
    next_index: u8 = 0,

    pub fn new() @This() {
        return WindowContextBuffer {
            .buf = undefined,
        };
    }

    pub fn input(self: *@This(), element: u8) void {
        self.buf[self.next_index] = element;
        self.next_index +%= 1;
        if (self.next_index == 0) 
            self.is_full = true;
    }

    pub fn output(self: *@This()) u8 {
        return self.buf[self.next_index -% 1];
    }

    pub fn full(self: *@This()) bool {
        return self.is_full;
    }

};


const WindowContext = struct {
    buffer: WindowContextBuffer,
    // `u16` instead of `u8` because we can reach 256 inside a window
    // TODO! make the window length a parameter and derive all the integer sizes.
    counter: [u16]256,
    unique_bytes: u16,
    is_full: bool,
    nb_bytes: usize,

    pub fn new() @This() {
        return WindowContext {
            .counter = [_]u16{0} ** 256,
            .unique_bytes = 0,
            .is_full = false,
            .nb_bytes = 0,
        };
    }

    pub fn next_byte_partial(self: *@This(), byte: u8) void {
        self.buffer.input(byte);
        self.counter[byte] += 1;
        if (self.counter[byte] == 1) {
            self.unique_bytes +%= 1;
        }
    }

    pub fn next_byte_full(self: *@This(), byte: u8) void {
        const output_byte = self.buffer.output();
        self.counter[output_byte] -= 1;
        if (self.counter[output_byte] == 0) {
            // NOTE: can overflow
            self.unique_bytes -%= 1;
        }

        self.buffer.input(byte);
        // NOTE: will never overflow
        self.counter[byte] += 1; 
        if (self.counter[byte] == 1) {
            self.unique_bytes +%= 1;
        }
    }

    pub fn next_byte(self: *@This(), byte: u8) void {
        if (!self.is_full) {
            @branchHint(.cold);
            self.next_byte_partial(byte);
            self.nb_bytes += 1;
            if (self.nb_bytes == 256) {
                @branchHint(.cold);
                self.is_full = true;
            }
        } else {
            @branchHint(.hot);
            self.next_byte_full(byte);
        }
    }
};



pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
