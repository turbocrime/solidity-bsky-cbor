// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CborDecode.sol";
import "./CidCbor.sol";
import "./TreeNodeCbor.sol";

library TreeCbor {
    using CBORDecoder for bytes;

    struct Tree {
        TreeNodeCbor.TreeNode[] nodes;
        CidCbor.CidBytes32[] cids;
    }

    function _readTree(bytes[] memory cborData) internal pure returns (Tree memory) {
        require(cborData.length > 0, "Tree must contain nodes");
        TreeNodeCbor.TreeNode[] memory nodes = new TreeNodeCbor.TreeNode[](cborData.length);
        CidCbor.CidBytes32[] memory cids = new CidCbor.CidBytes32[](cborData.length);

        for (uint i = 0; i < cborData.length; i++) {
            cids[i] = CidCbor.CidBytes32.wrap(sha256(cborData[i]));
            uint byteIdx;
            (nodes[i], byteIdx) = TreeNodeCbor.readTreeNode(cborData[i], 0);
            require(byteIdx == cborData[i].length, "expected to read all bytes");
        }

        return Tree(nodes, cids);
    }

    function readTree(bytes[] memory cborData) internal pure returns (Tree memory) {
        return validTree(_readTree(cborData));
    }

    function getCid(Tree memory tree, CidCbor.CidBytes32 indexCid)
        internal
        pure
        returns (TreeNodeCbor.TreeNode memory, uint index)
    {
        return getCid(tree, indexCid, 0);
    }

    function getCid(Tree memory tree, CidCbor.CidBytes32 indexCid, uint startIdx)
        internal
        pure
        returns (TreeNodeCbor.TreeNode memory, uint index)
    {
        bytes32 indexBytes = CidCbor.CidBytes32.unwrap(indexCid);
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (CidCbor.CidBytes32.unwrap(tree.cids[i]) == indexBytes) {
                return (tree.nodes[i], i);
            }
        }
        revert("node not found");
    }

    function validTree(Tree memory tree) internal pure returns (Tree memory) {
        for (uint i = 0; i < tree.cids.length; i++) {
            bytes32 thisCid = CidCbor.CidBytes32.unwrap(tree.cids[i]);
            for (uint j = i + 1; j < tree.nodes.length; j++) {
                bytes32 otherCid = CidCbor.CidBytes32.unwrap(tree.cids[j]);
                require(thisCid != otherCid, "node cids must be unique");
            }
        }
        return tree;
    }
}
