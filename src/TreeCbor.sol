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
        returns (TreeNodeCbor.TreeNode memory, uint)
    {
        bytes32 indexBytes = CidCbor.CidBytes32.unwrap(indexCid);
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (CidCbor.CidBytes32.unwrap(tree.cids[i]) == indexBytes) {
                return (tree.nodes[i], i);
            }
        }
        revert("couldn't get cid, not found");
    }

    function hasCid(Tree memory tree, CidCbor.CidBytes32 indexCid, uint startIdx) internal pure returns (bool, uint) {
        bytes32 indexBytes = CidCbor.CidBytes32.unwrap(indexCid);
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (CidCbor.CidBytes32.unwrap(tree.cids[i]) == indexBytes) {
                return (true, i);
            }
        }
        return (false, 0);
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

    function verifyInclusion(
        TreeCbor.Tree memory tree,
        bytes[] memory treeCbor,
        CidCbor.CidBytes32 entryCid,
        bytes memory targetRecord,
        string memory targetKey
    ) internal pure returns (bool) {
        CidCbor.CidBytes32 targetCid = CidCbor.CidBytes32.wrap(sha256(targetRecord));
        CidCbor.CidBytes32[] memory queue = new CidCbor.CidBytes32[](1);
        queue[0] = entryCid;

        CidCbor.CidBytes32 leftWalk;
        CidCbor.CidBytes32[] memory rightWalk;
        CidCbor.CidBytes32 currentCid;
        TreeNodeCbor.TreeNode memory currentNode;
        uint currentIndex;

        bool found = false;
        bool hasCurrent = false;

        CidCbor.CidBytes32[] memory newQueue;

        while (queue.length > 0) {
            currentCid = queue[0];
            (hasCurrent, currentIndex) = TreeCbor.hasCid(tree, currentCid, currentIndex);
            if (!hasCurrent) {
                newQueue = new CidCbor.CidBytes32[](queue.length - 1);
                for (uint i = 0; i < newQueue.length; i++) {
                    newQueue[i] = queue[i + 1];
                }
                queue = newQueue;
                continue;
            }
            (currentNode, currentIndex) = TreeCbor.getCid(tree, currentCid, currentIndex);

            leftWalk = CidCbor.readCidBytes32(treeCbor[currentIndex], currentNode.left);
            rightWalk = new CidCbor.CidBytes32[](currentNode.entries.length);

            for (uint i = 0; i < currentNode.entries.length; i++) {
                rightWalk[i] = CidCbor.readCidBytes32(treeCbor[currentIndex], currentNode.entries[i].tree);
                if (keccak256(abi.encode(targetKey)) == keccak256(abi.encode(currentNode.entries[i].key))) {
                    CidCbor.CidBytes32 valueCid =
                        CidCbor.readCidBytes32(treeCbor[currentIndex], currentNode.entries[i].value);
                    if (CidCbor.CidBytes32.unwrap(valueCid) == CidCbor.CidBytes32.unwrap(targetCid)) {
                        require(!found, "duplicate entry");
                        found = true;
                    }
                }
            }

            newQueue = new CidCbor.CidBytes32[](queue.length + rightWalk.length);
            newQueue[0] = leftWalk;
            for (uint i = 1; i < queue.length; i++) {
                newQueue[i] = queue[i];
            }
            for (uint i = 0; i < rightWalk.length; i++) {
                newQueue[queue.length + i] = rightWalk[i];
            }
            queue = newQueue;
        }

        return found;
    }
}
