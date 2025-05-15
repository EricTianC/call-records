const std = @import("std");

pub const RecordEntry = struct {
    number: [11]u8,
    kind: [2]u8,
    period: [4]u8,
    location: [4]u8,
    newline: [2]u8,
};

// pub const RecordEntry = packed struct {
//     number: u88, // [11]u8
//     type: u16, // [2]u8
//     period: u32, // [4]u8
//     location: u32, // [4]u8
//     newline: u16, // [2]u8
// };

// pub fn loadFromFile(filename: []u8) !void {
//     const file = try std.fs.cwd().openFile(filename, .{});
//     defer file.close();

//     const size = file.getEndPos() catch |err| {
//         if (err == std.fs.Error.FileNotFound) {
//             return error.FileNotFound;
//         }
//         return err;
//     };
// }
