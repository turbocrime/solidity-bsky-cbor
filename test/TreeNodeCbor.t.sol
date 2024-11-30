// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";
import "../src/TreeNodeCbor.sol";
import "../src/CidCbor.sol";

contract TreeNodeCborTest is Test {
    bytes private constant treeNodeBytes =
        hex"a2616585a4616b58236170702e62736b792e67726170682e666f6c6c6f772f336b77767534737665647332346170006174d82a58250001711220b000383f1466f65b0a02da763f46cf0e4510d832f6c609a9df56db73b81259376176d82a582500017112205cd7382608fb47afda979840cf0024b3d2d2e9e43448713909e998b6a1849490a4616b486679656a776332346170181b6174d82a58250001711220b295211bc0bfc8a6c8404f4877e96c37b25272c85e4942a29b178d26803f13996176d82a5825000171122017428f68c9c19f59b08b4b2d71ce96e04cdaf6139b94baf0a2c5ee51aa74493fa4616b486d77686f6e3232346170181b6174d82a58250001711220752be9d63155323fc5ce8753bdb5832fc7f5ad762c4e37944a6de84bbb9516876176d82a582500017112200fe8a27c597fcc6059888660b321e473bdaa94b45d0a702f3bd05e013ff17564a4616b486e337667376332346170181b6174d82a58250001711220ff7f6bd81b38a383101aec250c290ec6cd33555baf1e644f4b6d9b60a2e1fb856176d82a58250001711220a9f192fea504ecf8ae900d2a4f9f37551865132ae50bf680ac1687636afee7e1a4616b486f797875373232346170181b6174d82a582500017112204afcab072750efa8755714ca8477b35e871b71856a329c9973c4b94b7a4c98986176d82a58250001711220c46c805c774dcd3eaf4f90cef5e63f1f2a53f9c6bdb14b7397e736678b54dc97616cd82a582500017112206e7335ed248edae3ed49d47b88a5fcad2985e15f416f8ae23a49dfc1231aeb91";

    Cid private constant expectLeftCid =
        Cid.wrap(uint256(bytes32(hex"6e7335ed248edae3ed49d47b88a5fcad2985e15f416f8ae23a49dfc1231aeb91")));

    TreeNodeCbor.TreeNodeE[] private e;

    function setUp() public {
        (e,) = TreeNodeCbor.readEArray(treeNodeBytes, 3);
    }

    function test_readTreeNode_only() public pure {
        TreeNodeCbor.readTreeNode(treeNodeBytes, 0);
    }

    function test_readTreeNode_valid() public pure {
        (TreeNode memory node, uint byteIdx) = TreeNodeCbor.readTreeNode(treeNodeBytes, 0);

        require(byteIdx == treeNodeBytes.length, "expected to read all bytes");
        require(node.entries.length == 5, "expected 5 entries");
        require(node.left == expectLeftCid, "expected left sha");
        for (uint i = 0; i < node.entries.length; i++) {
            console.log("node entry %s", i);
            console.log("key", node.entries[i].key);
            console.log("value", Cid.unwrap(node.entries[i].value));
            console.log("tree", Cid.unwrap(node.entries[i].tree));
        }
    }

    function test_readNodeE_only() public pure {
        TreeNodeCbor.readEArray(treeNodeBytes, 3);
    }

    function test_buildEntryKeys_only() public view {
        TreeNodeCbor.buildEntryKeys(e);
    }
}
