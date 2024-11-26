// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CborDecode.sol";
import "./CidCbor.sol";
import "./TreeNodeCbor.sol";

library TreeCbor {
    using CBORDecoder for bytes;

    struct Tree {
        TreeNodeCbor.TreeNode[] nodes;
        CidCbor.Cid[] cids;
    }

    function _readTree(bytes[] memory cborData) internal pure returns (Tree memory) {
        require(cborData.length > 0, "Tree must contain nodes");
        TreeNodeCbor.TreeNode[] memory nodes = new TreeNodeCbor.TreeNode[](cborData.length);
        CidCbor.Cid[] memory cids = new CidCbor.Cid[](cborData.length);

        for (uint i = 0; i < cborData.length; i++) {
            cids[i] = CidCbor.Cid.wrap(uint256(sha256(cborData[i])));
            uint byteIdx;
            (nodes[i], byteIdx) = TreeNodeCbor.readTreeNode(cborData[i], 0);
            require(byteIdx == cborData[i].length, "expected to read all bytes");
        }

        return Tree(nodes, cids);
    }

    function readTree(bytes[] memory cborData) internal pure returns (Tree memory) {
        return validTree(_readTree(cborData));
    }

    function hasCid(Tree memory tree, CidCbor.Cid cid) internal pure returns (bool, uint) {
        return _hasCid(tree, cid, 0);
    }

    function _hasCid(Tree memory tree, CidCbor.Cid cid, uint startIdx) internal pure returns (bool, uint) {
        uint256 index = CidCbor.Cid.unwrap(cid);
        for (uint i = startIdx; i < tree.cids.length; i++) {
            if (CidCbor.Cid.unwrap(tree.cids[i]) == index) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function validTree(Tree memory tree) internal pure returns (Tree memory) {
        for (uint i = 0; i < tree.cids.length; i++) {
            uint256 thisCid = CidCbor.Cid.unwrap(tree.cids[i]);
            for (uint j = i + 1; j < tree.nodes.length; j++) {
                uint256 otherCid = CidCbor.Cid.unwrap(tree.cids[j]);
                require(thisCid != otherCid, "node cids must be unique");
            }
        }
        return tree;
    }

    function memPop(CidCbor.Cid[] memory arr) internal pure returns (CidCbor.Cid[] memory) {
        CidCbor.Cid[] memory newArr = new CidCbor.Cid[](arr.length - 1);
        for (uint i = 1; i < arr.length; i++) {
            newArr[i - 1] = arr[i];
        }
        return newArr;
    }

    function memCat(CidCbor.Cid[] memory arr1, CidCbor.Cid[] memory arr2)
        internal
        pure
        returns (CidCbor.Cid[] memory)
    {
        CidCbor.Cid[] memory newArr = new CidCbor.Cid[](arr1.length + arr2.length);
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
        CidCbor.Cid entryCid,
        bytes memory targetRecord,
        string memory targetKey
    ) internal pure returns (bool) {
        CidCbor.Cid[] memory rightWalk;
        CidCbor.Cid currentCid;
        TreeNodeCbor.TreeNode memory currentNode;
        uint currentIndex;
        bool found = false;
        bool hasCurrent = false;

        CidCbor.Cid targetCid = CidCbor.Cid.wrap(uint256(sha256(targetRecord)));
        CidCbor.Cid[] memory queue = new CidCbor.Cid[](1);
        queue[0] = entryCid;

        while (queue.length > 0) {
            currentCid = queue[0];
            (hasCurrent, currentIndex) = TreeCbor.hasCid(tree, currentCid);
            if (!hasCurrent) {
                queue = memPop(queue);
                continue;
            }
            currentNode = tree.nodes[currentIndex];

            rightWalk = new CidCbor.Cid[](currentNode.entries.length);

            for (uint i = 0; i < currentNode.entries.length; i++) {
                rightWalk[i] = currentNode.entries[i].tree;
                // TODO: match on key lol
                if (CidCbor.Cid.unwrap(currentNode.entries[i].value) == CidCbor.Cid.unwrap(targetCid)) {
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
