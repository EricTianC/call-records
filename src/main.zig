const std = @import("std");
const pdata = @import("pdata.zig");

const datafile = "gsm.dat";

pub fn main() !void {
    // 打开文件
    const file_handle = try std.fs.cwd().openFile(datafile, .{});
    const size = try file_handle.getEndPos();

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    const file_bytes = try allocator.alloc(u8, size);
    defer allocator.free(file_bytes);

    _ = try file_handle.readAll(file_bytes);
    file_handle.close();

    const file = std.mem.bytesAsSlice(pdata.RecordEntry, file_bytes);
    std.debug.print("loaded {s}: {} Bytes\n", .{ datafile, size });
    std.debug.print("first entry: {}", .{file[0]});
}
