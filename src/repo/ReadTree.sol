// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../tags/ReadCid.sol";

using ReadCbor for bytes;
using ReadCid for bytes;

using MST for Tree global;

struct Tree {
    MST.Node[] nodes;
    CidSha256[] cids;
}

library MST {
    using {pop, cat} for CidSha256[];

    struct Node {
        CidSha256 left;
        Entry[] entries;
    }

    struct Entry {
        string key;
        CidSha256 value;
        CidSha256 tree;
    }

    function has(Tree memory tree, CidSha256 cid) internal pure returns (bool, uint) {
        require(!cid.isNull(), "null cid is never in tree");
        return hasCid(tree, cid, 0);
    }

    function verifyInclusion(Tree memory tree, CidSha256 rootCid, string memory targetKey)
        internal
        pure
        returns (CidSha256)
    {
        CidSha256 currentCid;
        Node memory currentNode;
        uint currentIndex;
        CidSha256 targetCid;
        bool hasCurrent = false;

        // TODO: queue indicies for efficiency?
        CidSha256[] memory queue = new CidSha256[](1);
        queue[0] = rootCid;

        while (queue.length > 0) {
            currentCid = queue[0];
            // TODO: possibly accelerate searches with hasCid starting index
            (hasCurrent, currentIndex) = hasCid(tree, currentCid, 0);
            if (!hasCurrent) {
                queue = queue.pop();
                continue;
            }
            currentNode = tree.nodes[currentIndex];

            CidSha256[] memory rightWalk = new CidSha256[](currentNode.entries.length);

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
            queue = queue.cat(rightWalk);
        }

        require(!targetCid.isNull(), "target not included in tree");
        return targetCid;
    }

    function compareKeys(string memory key1, string memory key2) private pure returns (bool) {
        return keccak256(abi.encode(key1)) == keccak256(abi.encode(key2));
    }

    function hasCid(Tree memory tree, CidSha256 cid, uint startIdx) private pure returns (bool found, uint foundIdx) {
        assembly ("memory-safe") {
            if cid {
                let cids := mload(add(tree, 0x20)) // get tree.cids array pointer
                let ptr := add(cids, 0x20) // pointer to first element
                for { let i := startIdx } lt(i, mload(cids)) { i := add(i, 1) } {
                    if eq(
                        cid, // compare cid
                        mload(add(ptr, shl(5, i))) // use shift left by 5 (equivalent to * 32) for offset
                    ) {
                        found := 1
                        foundIdx := i
                        break
                    }
                }
            }
        }
    }

    function cat(CidSha256[] memory arr1, CidSha256[] memory arr2) private pure returns (CidSha256[] memory arrNew) {
        arrNew = new CidSha256[](arr1.length + arr2.length);

        assembly ("memory-safe") {
            // Get the data pointers
            let ptr1 := add(arr1, 0x20)
            let ptr2 := add(arr2, 0x20)
            let ptrNew := add(arrNew, 0x20)

            // Copy arr1
            let words := mul(mload(arr1), 0x20) // arr1.length * 32 bytes
            for { let i := 0 } lt(i, words) { i := add(i, 0x20) } { mstore(add(ptrNew, i), mload(add(ptr1, i))) }

            // Copy arr2
            ptrNew := add(ptrNew, words) // Start after size of arr1
            words := mul(mload(arr2), 0x20) // arr2.length * 32 bytes
            for { let i := 0 } lt(i, words) { i := add(i, 0x20) } { mstore(add(ptrNew, i), mload(add(ptr2, i))) }
        }
    }

    // TODO: assembly, consider popping from the end for speed.
    // would simply decrementing the length cause memory corruption?
    function pop(CidSha256[] memory arr) private pure returns (CidSha256[] memory) {
        CidSha256[] memory newArr = new CidSha256[](arr.length - 1);
        for (uint i = 1; i < arr.length; i++) {
            newArr[i - 1] = arr[i];
        }
        return newArr;
    }
}

library ReadTree {
    using {readNode, readE} for bytes;

    function readTree(bytes[] memory nodeCbors) internal pure returns (Tree memory tree) {
        tree.nodes = new MST.Node[]((nodeCbors.length));
        tree.cids = new CidSha256[]((nodeCbors.length));

        for (uint i = 0; i < nodeCbors.length; i++) {
            tree.cids[i] = CidSha256.wrap(uint256(sha256(nodeCbors[i])));
            tree.nodes[i] = nodeCbors[i].readNode();

            // expect unique cids
            for (uint j = 0; j < i; j++) {
                require(tree.cids[i] != tree.cids[j], "node cids must be unique");
            }
        }

        return tree;
    }

    // TODO: remove NodeE struct, combine readE/readEi/buildEntryKeys
    struct NodeE {
        uint8 p; // prefixlen
        bytes k; // keysuffix
        CidSha256 v; // value
        CidSha256 t; // tree
    }

    function readEi(bytes memory cborData, uint byteIdx) private pure returns (uint, NodeE memory) {
        uint mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);

        require(mapLen == 4, "expected 4 fields in node entry");

        uint8 p;
        bytes memory k;
        CidSha256 v;
        CidSha256 t;

        for (uint i = 0; i < mapLen; i++) {
            bytes1 mapKey;
            (byteIdx, mapKey) = cborData.String1(byteIdx);
            if (mapKey == "p") {
                (byteIdx, p) = cborData.UInt8(byteIdx);
            } else if (mapKey == "k") {
                (byteIdx, k) = cborData.Bytes(byteIdx);
            } else if (mapKey == "t") {
                (byteIdx, t) = cborData.NullableCid(byteIdx);
            } else if (mapKey == "v") {
                (byteIdx, v) = cborData.NullableCid(byteIdx);
            } else {
                revert("unexpected node entry field");
            }
        }

        return (byteIdx, NodeE(p, k, v, t));
    }

    function keyCat(bytes memory prefix, uint8 slice, bytes memory append) private pure returns (bytes memory ret) {
        require(slice <= prefix.length, "prefix slice dimension out of bounds");
        ret = new bytes(slice + append.length);

        assembly {
            let j := 0
            let prefixWords := div(add(slice, 31), 32)
            let appendWords := div(add(mload(append), 31), 32)
            for { j := 0 } lt(j, prefixWords) { j := add(j, 1) } {
                mstore(add(ret, add(0x20, mul(j, 32))), mload(add(prefix, add(0x20, mul(j, 32)))))
            }
            for { j := 0 } lt(j, appendWords) { j := add(j, 1) } {
                mstore(add(ret, add(0x20, add(slice, mul(j, 32)))), mload(add(append, add(0x20, mul(j, 32)))))
            }
        }

        return ret;
    }

    function buildEntryKeys(NodeE[] memory e) private pure returns (MST.Entry[] memory) {
        MST.Entry[] memory entries = new MST.Entry[](e.length);
        bytes memory previousKey = new bytes(0);
        for (uint i = 0; i < e.length; i++) {
            bytes memory key = keyCat(previousKey, e[i].p, e[i].k);
            entries[i] = MST.Entry(string(key), e[i].v, e[i].t);
            previousKey = key;
        }
        return entries;
    }

    function readNode(bytes memory cborData) private pure returns (MST.Node memory node) {
        (uint byteIdx, uint mapLen) = cborData.Map(0);
        require(mapLen == 2, "expected 2 fields in node");
        bytes1 mapKey;
        for (uint i = 0; i < mapLen; i++) {
            (byteIdx, mapKey) = cborData.String1(byteIdx);
            if (mapKey == "l") {
                (byteIdx, node.left) = cborData.NullableCid(byteIdx);
            } else if (mapKey == "e") {
                NodeE[] memory e; // TODO: inline readE?
                (byteIdx, e) = cborData.readE(byteIdx);
                node.entries = buildEntryKeys(e);
            } else {
                revert("unexpected node field");
            }
        }
        require(byteIdx == cborData.length, "expected to read entire node");
        return node;
    }

    function readE(bytes memory cborData, uint byteIdx) private pure returns (uint, NodeE[] memory) {
        uint arrayLen;
        (byteIdx, arrayLen) = cborData.Array(byteIdx);

        NodeE[] memory e = new NodeE[](arrayLen);
        for (uint i = 0; i < arrayLen; i++) {
            (byteIdx, e[i]) = readEi(cborData, byteIdx);
        }

        return (byteIdx, e);
    }
}
