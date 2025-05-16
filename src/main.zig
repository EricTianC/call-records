//! 力图实现实验 8 的理论最优：（以下为原题）
//! 数据文件是某移动电话公司的用户通话记录，约10万用户一天的通话记录，共大约100万条记录，文件中记录为定长，包含如下数据域：
//! 数据域内容    长度              说明
//! 手机号码      Char(11)
//! 通话类型      Char(2)          00-主叫，01-被叫
//! 通话时长      Char(4)          单位：秒，右对齐左补零
//! 呼叫发生小区  Char(4)
//! 换行符        Char(2)          \r\n

const std = @import("std");

pub const RecordEntry = struct {
    number: [11]u8,
    kind: [2]u8,
    period: [4]u8,
    location: [4]u8,
    newline: [2]u8,
};

const datafile = "gsm.dat";

pub fn main() !void {
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();
    var timer = try std.time.Timer.start();

    const memory_buffer = try std.heap.page_allocator.alloc(u8, 27_000_000);
    defer std.heap.page_allocator.free(memory_buffer);
    // var memory_buffer: [27_000_000]u8 = undefined; // 栈不够大导致的 qwq
    var fba = std.heap.FixedBufferAllocator.init(memory_buffer);
    const allocator = fba.allocator();

    // 载入数据
    const file_handler = try std.fs.cwd().openFile(datafile, .{});
    const size = try file_handler.getEndPos();
    const file_bytes = try allocator.alloc(u8, size);
    _ = try file_handler.readAll(file_bytes);
    file_handler.close();
    const file: []RecordEntry = std.mem.bytesAsSlice(RecordEntry, file_bytes);

    var map = std.AutoHashMap(u64, u64).init(allocator); // TODO: 使用自定义的最小完美哈希 HashMap
    defer map.deinit();
    try map.ensureTotalCapacity(10_0000);

    for (file) |*entry| {
        const number: u64 = std.mem.bytesToValue(u64, entry.number[3..]);
        const minute = periodToMinute(&(entry.period));

        const target = try map.getOrPut(number);
        if (target.found_existing) {
            if (entry.kind[1] == '0') {
                target.value_ptr.* += 40 * minute;
            } else {
                target.value_ptr.* += 20 * minute;
            }
        } else {
            if (entry.kind[1] == '0') {
                target.value_ptr.* = 40 * minute;
            } else {
                target.value_ptr.* = 20 * minute;
            }
        }
    }

    const bills_file_handler = try std.fs.cwd().createFile("bills.txt", .{});
    defer bills_file_handler.close();

    const bills_writer = bills_file_handler.writer();

    // var buffer: []u8 = allocator.alloc(u8, map.count() * (11 + 2 + 5 + 2)); // number + ": " + bill + "\r\n"
    // defer allocator.free(buffer);

    // TODO: Optimize here, 但 writer.print 是 comptime 的，应该不会有太大的性能损失（有暂时也没办法了）

    var buffered_out = std.io.BufferedWriter(
        10_0000 * (11 + 2 + 4 + 1),
        @TypeOf(bills_writer),
    ){ .unbuffered_writer = bills_writer };

    const buffered_writer = buffered_out.writer();

    var iter = map.iterator();
    while (iter.next()) |entry| {
        try buffered_writer.print("139{s}: {}\n", .{
            std.mem.toBytes(entry.key_ptr.*),
            entry.value_ptr.*,
        });
    }
    try buffered_out.flush();

    const elapsed = timer.read();
    std.debug.print("used {}.{} ms", .{ @divFloor(elapsed, 1000_000), elapsed % 1000_000 });
}

inline fn parseDecChar(d: u8) u64 {
    switch (d) {
        inline '0' => return 0,
        inline '1' => return 1,
        inline '2' => return 2,
        inline '3' => return 3,
        inline '4' => return 4,
        inline '5' => return 5,
        inline '6' => return 6,
        inline '7' => return 7,
        inline '8' => return 8,
        inline '9' => return 9,
        else => unreachable,
    }
}

fn periodToMinute(period: *const [4]u8) u64 {
    var seconds: u64 = 0;
    inline for (period) |d| {
        seconds = seconds * 10 + parseDecChar(d);
    }
    return if (seconds == 0) 0 else @divFloor(seconds - 1, 60) + 1;
}
