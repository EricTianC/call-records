//! 暂时放弃
//! 红黑树，参考 https://oi-wiki.org/ds/rbtree/
//!
//! An RBTree-based map implementation
//!   https://en.wikipedia.org/wiki/Red–black_tree
//!
//!   A red–black tree (RBTree) is a kind of self-balancing binary search tree.
//!   Each node stores an extra field representing "color" (RED or BLACK), used
//!   to ensure that the tree remains balanced during insertions and deletions.
//!
//!   In addition to the requirements imposed on a binary search tree the following
//!   must be satisfied by a red–black tree:
//!
//!    1. Every node is either RED or BLACK.
//!    2. All NIL nodes (`nullptr` in this implementation) are considered BLACK.
//!    3. A RED node does not have a RED child.
//!    4. Every path from a given node to any of its descendant NIL nodes goes
//!   through the same number of BLACK nodes.
//!
//!   @tparam Key the type of keys maintained by this map
//!   @tparam Value the type of mapped values
//!   @tparam Compare the compare function
//!  /
const std = @import("std");
const assert = @import("std").debug.assert;

/// 红黑树结点，由于用作查找用途，data 字段采用 const 指针
/// 采取 https://oi-wiki.org/ds/rbtree/ 中的实现, 但修改 value 为 const 指针
/// 额，key 也改成 const 指针吧
pub fn RBTreeMap(comptime K: type, comptime V: type, comptime compare_function: fn (*const K, *const K) bool) type {
    return struct {
        allocator: std.mem.Allocator,
        root: ?*Node = null,
        count: usize = 0,

        const compare = compare_function;
        // using Ptr = std::shared_ptr<Node>;
        // 即等效 zig 代码, const Ptr = *const Node;
        const Node = struct {
            left: ?*Node = null,
            right: ?*Node = null,
            parent: ?*Node = null,
            color: enum {
                Red,
                Black,
            } = .Red,
            key: *const K,
            value: *const V,

            const Provider = fn () *Node;
            const Comsumer = fn (*Node) void;

            const Direction = enum {
                Left,
                Root,
                Right,
            };

            inline fn isLeaf(self: *Node) bool {
                return self.left == null and self.right == null;
            }

            inline fn isRoot(self: *Node) bool {
                return self.parent == null;
            }

            inline fn isRed(self: *Node) bool {
                return self.color == .Red;
            }

            inline fn isBlack(self: *Node) bool {
                return self.color == .Black;
            }

            inline fn direction(self: *Node) Direction {
                if (self.parent != null) {
                    if (self == self.parent.?.left) {
                        return .Left;
                    } else if (self == self.parent.?.right) {
                        return .Right;
                    }
                } else {
                    return .Root;
                }
            }

            inline fn sibling(self: *Node) **Node {
                assert(!self.isRoot());
                if (self.direction() == .Left) {
                    return &self.parent.?.right;
                } else {
                    return &self.parent.?.left;
                }
            }

            inline fn hasSibling(self: *Node) bool {
                return !self.isRoot() and self.sibling() != null;
            }

            inline fn uncle(self: *Node) **Node {
                assert(self.parent != null);
                return self.parent.?.sibling();
            }

            inline fn hasUncle(self: *Node) bool {
                return !self.isRoot() and self.parent.?.hasSibling();
            }

            inline fn grandParent(self: *Node) **Node {
                assert(self.parent != null);
                return self.parent.?.parent;
            }

            inline fn hasGrandParent(self: *Node) bool {
                return !self.isRoot() and self.parent.?.parent != null;
            }

            inline fn release(self: *Node) void {
                self.parent = null;
                if (self.left != null) {
                    self.left.?.release();
                }
                if (self.right != null) {
                    self.right.?.release();
                }
            }
        };



        pub fn init() RBTreeMap(K, V, compare_function) {
            return RBTreeMap(K, V, compare_function){};
        }

        inline fn size(self: *RBTreeMap(K, V, compare_function)) usize {
            return self.count;
        }

        inline fn isEmpty(self: *RBTreeMap(K, V, compare_function)) bool {
            return self.count == 0;
        }

        void clear(self: *RBTreeMap(K, V, compare_function)) void {
            if (self.root != null) {
                self.root.?.release();
                self.root = null;
            }
            self.count = 0;
        }

        /// Returns the value to which the specified key is mapped; If this map
        /// contains no mapping for the key, a {@code NoSuchMappingException} will
        /// be thrown.
        /// @param key
        /// @return RBTreeMap<Key, Value>::Value
        /// @throws error.InvalidKey
        pub fn get(key: K) !const *V {
            if (self.root == null) {
                return error.InvalidKey;
            } else {
                const node : *Node = self.getNode(self.root, key);
                if (node == null) {
                    return error.InvalidKey;
                } else {
                    return &node.value;
                }
            }
        }

        pub fn contains(key: K) bool {
            return self.getNode(self.root, key) != null;
        }

        fn maintainRelationship(node: *const Node) void {
            if (node.left != null) {
                node.left.?.parent = node;
            }
            if (node.right != null) {
                node.right.?.parent = node;
            }
        }

        ///     |                       |
        ///     N                       S
        ///    / \     l-rotate(N)     / \
        ///   L   S    ==========>    N   R
        ///      / \                 / \
        ///     M   R               L   M
        fn rotateLeft(
            self: *RBTreeMap(K, V, compare_function),
            node: ?*Node,
        ) void {
            assert(node != null and node.?.right != null);

            const parent = node.?.parent;
            const direction = node.?.direction();

            const successor = node.?.right;
            node.?.right = successor.?.left;
            successor.?.left = node;

            maintainRelationship(node);
            maintainRelationship(successor);

            switch (direction) {
                .Root => {
                    self.root = successor;
                },
                .Left => {
                    parent.?.left = successor;
                },
                .Right => {
                    parent.?.right = successor;
                },
            }

            successor.?.parent = parent;
        }
    };
}

fn less(a: *const u8, b: *const u8) bool {
    return a < b;
}

test "init u8 rbtreemap" {
    const tree = RBTreeMap(
        u8,
        u8,
        less,
    ).init();
    std.debug.print("tree: {any}\n", .{tree});
}
