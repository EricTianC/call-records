const std = @import("std");
const pdata = @import("pdata.zig");

const datafile = "gsm.dat";

pub fn main() !void {
    // 打开文件
    const file_handle = try std.fs.cwd().openFile(datafile, .{});
    const size = try file_handle.getEndPos();

    // var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    // const allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_bytes = try allocator.alloc(u8, size);
    defer allocator.free(file_bytes);

    _ = try file_handle.readAll(file_bytes);
    file_handle.close();

    const file: []pdata.RecordEntry = std.mem.bytesAsSlice(pdata.RecordEntry, file_bytes);
    // std.debug.print("loaded {s}: {} Bytes\n", .{ datafile, size });
    // std.debug.print("first entry: {}\n", .{file[0]});

    var map = std.StringHashMap(u64).init(allocator);
    defer map.deinit();

    // try map.ensureTotalCapacity(@intCast(file.len));
    try map.ensureTotalCapacity(10_0000);

    // comptime {
    //     const senderCode: [2]u8 = .{ '0', '0' };
    //     const receiverCode: [2]u8 = .{ '0', '1' };
    // }
    var flag_all_prefix139 = true;

    for (file) |*entry| {
        // const keyP = file[i].number; // HashMap 不拥有 key，坑
        const keyP = &entry.number;
        if (keyP[0] != '1' or keyP[1] != '3' or keyP[2] != '9') {
            flag_all_prefix139 = false;
        }

        const period = entry.period;

        const seconds = try std.fmt.parseInt(u64, &period, 10);
        const minutes: u64 = if (seconds == 0) 0 else @divFloor(seconds - 1, 60) + 1;
        const kind = entry.kind;

        const target = try map.getOrPut(keyP);
        if (target.found_existing) {
            // 计算费用
            if (kind[1] == '0') {
                target.value_ptr.* += 40 * minutes;
            } else {
                target.value_ptr.* += 20 * minutes;
            }
        } else {
            // 计算费用
            if (kind[1] == '0') {
                target.value_ptr.* = 40 * minutes;
            } else {
                target.value_ptr.* = 20 * minutes;
            }
        }
    }
    // std.debug.print("all numbers start with 139: {}\n", .{flag_all_prefix139});

    // 将所有费用存储到 bills.txt 中
    const bills_file = try std.fs.cwd().createFile("bills.txt", .{});
    defer bills_file.close();

    const bills_writer = bills_file.writer();
    var bills_writer_buffered = std.io.BufferedWriter(20 * 10_0000, @TypeOf(bills_writer)){ .unbuffered_writer = bills_writer };

    var buffered_writer = bills_writer_buffered.writer();

    var iterator = map.iterator();

    while (iterator.next()) |entry| {
        const keyP = entry.key_ptr;
        const value = entry.value_ptr;

        // 将 key 和 value 写入 bills.txt
        try buffered_writer.print("{s}: {d}\n", .{ keyP.*, value.* });
    }
    try bills_writer_buffered.flush();

    // std.debug.print("bills written to bills.txt\n", .{});
}
