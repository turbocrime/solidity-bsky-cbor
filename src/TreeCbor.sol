// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import "./CborDecode.sol";
import "./CidCbor.sol";
import "./TreeNodeCbor.sol";
import "./CommitCbor.sol";

struct Tree {
    TreeNode[] nodes;
    Cid[] cids;
}

using {TreeCbor.verifyInclusion, TreeCbor.has, TreeCbor.get} for Tree global;

library TreeCbor {
    using CborDecode for bytes;

    function readTree(bytes[] memory cborData) internal pure returns (Tree memory) {
        return uniqueCids(readNodes(cborData));
    }

    function has(Tree memory tree, Cid cid) internal pure returns (bool, uint) {
        require(!cid.isNull(), "null cid is never in tree");
        return hasCid(tree, cid, 0);
    }

    function get(Tree memory tree, Cid cid) internal pure returns (TreeNode memory) {
        require(!cid.isNull(), "null cid is never in tree");
        return getCid(tree, cid, 0);
    }

    function readNodes(bytes[] memory cborData) private pure returns (Tree memory) {
        require(cborData.length > 0, "Tree must contain nodes");
        TreeNode[] memory nodes = new TreeNode[](cborData.length);
        Cid[] memory cids = new Cid[](cborData.length);

        for (uint i = 0; i < cborData.length; i++) {
            cids[i] = Cid.wrap(uint256(sha256(cborData[i])));
            uint byteIdx;
            (nodes[i], byteIdx) = TreeNodeCbor.readTreeNode(cborData[i], 0);
            require(byteIdx == cborData[i].length, "expected to read all bytes");
        }

        return Tree(nodes, cids);
    }

    function uniqueCids(Tree memory tree) private pure returns (Tree memory) {
        for (uint i = 0; i < tree.cids.length; i++) {
            for (uint j = i + 1; j < tree.nodes.length; j++) {
                require(tree.cids[i] != tree.cids[j], "node cids must be unique");
            }
        }
        return tree;
    }

    function hasCid(Tree memory tree, Cid cid, uint startIdx) private pure returns (bool, uint) {
        if (cid.isNull()) {
            return (false, 0);
        }
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (tree.cids[i] == cid) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getCid(Tree memory tree, Cid cid, uint startIdx) private pure returns (TreeNode memory) {
        (bool present, uint idx) = hasCid(tree, cid, startIdx);
        require(present, "cid not found in tree");
        return tree.nodes[idx];
    }

    function memPop(Cid[] memory arr) private pure returns (Cid[] memory) {
        Cid[] memory newArr = new Cid[](arr.length - 1);
        for (uint i = 1; i < arr.length; i++) {
            newArr[i - 1] = arr[i];
        }
        return newArr;
    }

    function memCat(Cid[] memory arr1, Cid[] memory arr2) private pure returns (Cid[] memory) {
        Cid[] memory newArr = new Cid[](arr1.length + arr2.length);
        for (uint i = 0; i < arr1.length; i++) {
            newArr[i] = arr1[i];
        }
        for (uint i = 0; i < arr2.length; i++) {
            newArr[arr1.length + i] = arr2[i];
        }
        return newArr;
    }

    function compareKeys(string memory key1, string memory key2) private pure returns (bool) {
        return keccak256(abi.encode(key1)) == keccak256(abi.encode(key2));
    }

    function verifyInclusion(Tree memory tree, Cid rootCid, string memory targetKey) internal pure returns (Cid) {
        Cid[] memory rightWalk;
        Cid currentCid;
        TreeNode memory currentNode;
        uint currentIndex;
        Cid targetCid;
        bool hasCurrent = false;

        Cid[] memory queue = new Cid[](1);
        queue[0] = rootCid;

        while (queue.length > 0) {
            currentCid = queue[0];
            // TODO: possibly accelerate searches with hasCid starting index
            (hasCurrent, currentIndex) = hasCid(tree, currentCid, 0);
            if (!hasCurrent) {
                queue = memPop(queue);
                continue;
            }
            currentNode = tree.nodes[currentIndex];

            rightWalk = new Cid[](currentNode.entries.length);

            for (uint i = 0; i < currentNode.entries.length; i++) {
                rightWalk[i] = currentNode.entries[i].tree;
                if (compareKeys(currentNode.entries[i].key, targetKey)) {
                    require(targetCid.isNull(), "duplicate entry");
                    targetCid = currentNode.entries[i].value;
                }
            }

            // this pushes left walk to the front of the queue. there's no order
            // motivation, it's just faster than pop and append.
            queue[0] = currentNode.left;
            queue = memCat(queue, rightWalk);
        }

        require(!targetCid.isNull(), "target not included in tree");
        return targetCid;
    }
}
