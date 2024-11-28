// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CborDecode.sol";
import "./CidCbor.sol";
import "./TreeNodeCbor.sol";

library TreeCbor {
    using CBORDecoder for bytes;

    struct Tree {
        TreeNodeCbor.TreeNode[] nodes;
        Cid[] cids;
    }

    function _readTree(bytes[] memory cborData) internal pure returns (Tree memory) {
        require(cborData.length > 0, "Tree must contain nodes");
        TreeNodeCbor.TreeNode[] memory nodes = new TreeNodeCbor.TreeNode[](cborData.length);
        Cid[] memory cids = new Cid[](cborData.length);

        for (uint i = 0; i < cborData.length; i++) {
            cids[i] = Cid.wrap(uint256(sha256(cborData[i])));
            uint byteIdx;
            (nodes[i], byteIdx) = TreeNodeCbor.readTreeNode(cborData[i], 0);
            require(byteIdx == cborData[i].length, "expected to read all bytes");
        }

        return Tree(nodes, cids);
    }

    function readTree(bytes[] memory cborData) internal pure returns (Tree memory) {
        return validTree(_readTree(cborData));
    }

    function hasCid(Tree memory tree, Cid cid) internal pure returns (bool, uint) {
        return _hasCid(tree, cid, 0);
    }

    function _hasCid(Tree memory tree, Cid cid, uint startIdx) internal pure returns (bool, uint) {
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (tree.cids[i] == cid) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function validTree(Tree memory tree) internal pure returns (Tree memory) {
        for (uint i = 0; i < tree.cids.length; i++) {
            for (uint j = i + 1; j < tree.nodes.length; j++) {
                require(tree.cids[i] != tree.cids[j], "node cids must be unique");
            }
        }
        return tree;
    }

    function memPop(Cid[] memory arr) internal pure returns (Cid[] memory) {
        Cid[] memory newArr = new Cid[](arr.length - 1);
        for (uint i = 1; i < arr.length; i++) {
            newArr[i - 1] = arr[i];
        }
        return newArr;
    }

    function memCat(Cid[] memory arr1, Cid[] memory arr2) internal pure returns (Cid[] memory) {
        Cid[] memory newArr = new Cid[](arr1.length + arr2.length);
        for (uint i = 0; i < arr1.length; i++) {
            newArr[i] = arr1[i];
        }
        for (uint i = 0; i < arr2.length; i++) {
            newArr[arr1.length + i] = arr2[i];
        }
        return newArr;
    }

    function verifyInclusion(
        TreeCbor.Tree memory tree,
        Cid entryCid,
        bytes memory targetRecord,
        string memory targetKey
    ) internal pure returns (bool) {
        Cid[] memory rightWalk;
        Cid currentCid;
        TreeNodeCbor.TreeNode memory currentNode;
        uint currentIndex;
        bool found = false;
        bool hasCurrent = false;

        Cid targetCid = Cid.wrap(uint256(sha256(targetRecord)));
        Cid[] memory queue = new Cid[](1);
        queue[0] = entryCid;

        while (queue.length > 0) {
            currentCid = queue[0];
            (hasCurrent, currentIndex) = TreeCbor.hasCid(tree, currentCid);
            if (!hasCurrent) {
                queue = memPop(queue);
                continue;
            }
            currentNode = tree.nodes[currentIndex];

            rightWalk = new Cid[](currentNode.entries.length);

            for (uint i = 0; i < currentNode.entries.length; i++) {
                rightWalk[i] = currentNode.entries[i].tree;
                if (keccak256(abi.encode(currentNode.entries[i].key)) == keccak256(abi.encode(targetKey))) {
                    require(currentNode.entries[i].value == targetCid, "cid mismatch");
                    require(!found, "duplicate entry");
                    found = true;
                }
            }

            // this pushes left walk to the front of the queue. there's no order
            // motivation, it's just faster than pop and append.
            queue[0] = currentNode.left;
            queue = memCat(queue, rightWalk);
        }

        return found;
    }
}
