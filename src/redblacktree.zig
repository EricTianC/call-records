/// 红黑树结点，由于用作查找用途，data 字段采用 const 指针
pub fn RBTreeNode(comptime T: type) type {
    return struct {
        left: ?*RBTreeNode(T),
        right: ?*RBTreeNode(T),
        parent: ?*RBTreeNode(T),
        color: bool, // true = red, false = black
        data: *const T,
    };
}

pub fn RBTree(comptime T: type) type {
    return ?*RBTreeNode(T);
}

test "RBTree 与 RBTreeNode 相容性" {
    const std = @import("std");
    const data: u8 = 0x00;

    const empty_tree: RBTree(u8) = null;
    var example_node: RBTreeNode(u8) = .{
        .left = null,
        .right = null,
        .parent = null,
        .color = false,
        .data = &data,
    };
    std.debug.print("empty_tree: {?}\n", .{empty_tree});
    std.debug.print("example_node: {}\n", .{example_node});

    const casted_tree: RBTree(u8) = &example_node;
    std.debug.print("casted_tree: {?}\n", .{casted_tree});
}
