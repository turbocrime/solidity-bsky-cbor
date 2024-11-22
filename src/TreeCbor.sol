// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CborDecode.sol";
import "./CidCbor.sol";
import "./TreeNodeCbor.sol";
import "./RecordCbor.sol";

library TreeCbor {
    using CBORDecoder for bytes;

    uint8 private constant CID_V1 = 0x01;
    uint8 private constant MULTICODEC_DAG_CBOR = 0x71;
    uint8 private constant MULTIHASH_SHA_256 = 0x12;
    uint8 private constant MULTIHASH_SIZE_32 = 0x20;

    struct Tree {
        CidCbor.Cid root;
        TreeNodeCbor.TreeNode[] nodes;
        RecordCbor.Record[] records;
        CidCbor.Cid[] cids;
        bool[] nodeOrRecord;
    }

    function itemIsNode(bytes memory cborData) internal pure returns (bool) {
        (uint len, uint byteIdx) = cborData.readFixedMap(0);

        string memory itemName;
        (itemName, byteIdx) = cborData.readString(byteIdx);
        return len == 2;
    }

    function readTree(bytes[] memory cborData, CidCbor.Cid memory root) internal pure returns (Tree memory) {
        TreeNodeCbor.TreeNode[] memory nodes = new TreeNodeCbor.TreeNode[](cborData.length);
        RecordCbor.Record[] memory records = new RecordCbor.Record[](cborData.length);
        CidCbor.Cid[] memory cids = new CidCbor.Cid[](cborData.length);
        bool[] memory nodeOrRecord = new bool[](cborData.length);

        for (uint i = 0; i < cborData.length; i++) {
            cids[i] = CidCbor.Cid(
                bytes4(abi.encodePacked(CID_V1, MULTICODEC_DAG_CBOR, MULTIHASH_SHA_256, MULTIHASH_SIZE_32)),
                sha256(cborData[i]),
                false
            );
            uint byteIdx;
            if (itemIsNode(cborData[i])) {
                (nodes[i], byteIdx) = TreeNodeCbor.readTreeNode(cborData[i], 0);
                nodeOrRecord[i] = true;
            } else {
                (records[i], byteIdx) = RecordCbor.readRecord(cborData[i], 0);
                nodeOrRecord[i] = false;
            }
            require(byteIdx == cborData[i].length, "expected to read all bytes");
        }

        return requireUniqueCidsAndRoot(Tree(root, nodes, records, cids, nodeOrRecord));
    }

    function nodeByCid(Tree memory tree, CidCbor.Cid memory indexCid)
        internal
        pure
        returns (TreeNodeCbor.TreeNode memory, uint index)
    {
        return nodeByCid(tree, indexCid, 0);
    }

    function nodeByCid(Tree memory tree, CidCbor.Cid memory indexCid, uint startIdx)
        internal
        pure
        returns (TreeNodeCbor.TreeNode memory, uint index)
    {
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (CidCbor.cidMatches(tree.cids[i], indexCid)) {
                require(tree.nodeOrRecord[i], "expected node");
                return (tree.nodes[i], i);
            }
        }
        revert("node not found");
    }

    function recordByCid(Tree memory tree, CidCbor.Cid memory indexCid)
        internal
        pure
        returns (RecordCbor.Record memory, uint index)
    {
        return recordByCid(tree, indexCid, 0);
    }

    function recordByCid(Tree memory tree, CidCbor.Cid memory indexCid, uint startIdx)
        internal
        pure
        returns (RecordCbor.Record memory, uint index)
    {
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (CidCbor.cidMatches(tree.cids[i], indexCid)) {
                require(!tree.nodeOrRecord[i], "expected record");
                return (tree.records[i], i);
            }
        }
        revert("record not found");
    }

    function requireUniqueCidsAndRoot(Tree memory tree) internal pure returns (Tree memory) {
        bool rootIncluded;
        for (uint i = 0; i < tree.cids.length; i++) {
            if (!rootIncluded) {
                rootIncluded = CidCbor.cidMatches(tree.cids[i], tree.root);
            }
            for (uint j = i + 1; j < tree.nodes.length; j++) {
                require(!CidCbor.cidMatches(tree.cids[i], tree.cids[j]), "node cids must be unique");
            }
        }
        require(rootIncluded, "root cid must be included");
        return tree;
    }
}
