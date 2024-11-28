// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";

library TreeNodeCbor {
    using CBORDecoder for bytes;

    struct TreeNode {
        Cid left;
        TreeNodeEntry[] entries;
    }

    struct TreeNodeEntry {
        string key;
        Cid value;
        Cid tree;
    }

    struct TreeNodeE {
        uint8 p; // prefixlen
        bytes k; // keysuffix
        Cid v; // value
        Cid t; // tree
    }

    function readNodeE(bytes memory cborData, uint byteIdx) internal pure returns (TreeNodeE[] memory, uint) {
        uint arrayLen;
        (arrayLen, byteIdx) = cborData.readFixedArray(byteIdx);

        TreeNodeE[] memory ret = new TreeNodeE[](arrayLen);
        for (uint i = 0; i < arrayLen; i++) {
            (ret[i], byteIdx) = readE(cborData, byteIdx);
        }

        return (ret, byteIdx);
    }

    function readE(bytes memory cborData, uint byteIdx) internal pure returns (TreeNodeE memory, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);

        require(mapLen == 4, "expected 4 fields in node entry");

        uint8 p;
        bytes memory k;
        Cid v;
        Cid t;

        for (uint i = 0; i < mapLen; i++) {
            bytes1 mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes1(byteIdx);
            if (mapKey == "p") {
                (p, byteIdx) = cborData.readUInt8(byteIdx);
            } else if (mapKey == "k") {
                (k, byteIdx) = cborData.readBytes(byteIdx);
            } else if (mapKey == "t") {
                (t, byteIdx) = CidCbor.readNullableCid(cborData, byteIdx);
            } else if (mapKey == "v") {
                (v, byteIdx) = CidCbor.readNullableCid(cborData, byteIdx);
            } else {
                revert("unexpected node entry field");
            }
        }

        return (TreeNodeE(p, k, v, t), byteIdx);
    }

    function sliceCat(bytes memory prefix, uint8 slice, bytes memory append) internal pure returns (bytes memory cat) {
        require(slice <= prefix.length, "prefix slice dimension out of bounds");
        cat = new bytes(slice + append.length);

        assembly {
            let j := 0
            let prefixWords := div(add(slice, 31), 32)
            let appendWords := div(add(mload(append), 31), 32)
            for { j := 0 } lt(j, prefixWords) { j := add(j, 1) } {
                mstore(add(cat, add(0x20, mul(j, 32))), mload(add(prefix, add(0x20, mul(j, 32)))))
            }
            for { j := 0 } lt(j, appendWords) { j := add(j, 1) } {
                mstore(add(cat, add(0x20, add(slice, mul(j, 32)))), mload(add(append, add(0x20, mul(j, 32)))))
            }
        }

        return cat;
    }

    function buildEntryKeys(TreeNodeE[] memory e) internal pure returns (TreeNodeEntry[] memory) {
        TreeNodeEntry[] memory entries = new TreeNodeEntry[](e.length);
        bytes memory previousKey = new bytes(0);
        for (uint i = 0; i < e.length; i++) {
            bytes memory key = sliceCat(previousKey, e[i].p, e[i].k);
            entries[i] = TreeNodeEntry(string(key), e[i].v, e[i].t);
            previousKey = key;
        }
        return entries;
    }

    function readTreeNode(bytes memory cborData, uint byteIdx) internal pure returns (TreeNode memory node, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);
        require(mapLen == 2, "expected 2 fields in node");
        for (uint i = 0; i < mapLen; i++) {
            bytes1 mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes1(byteIdx);
            if (mapKey == "l") {
                (node.left, byteIdx) = CidCbor.readNullableCid(cborData, byteIdx);
            } else if (mapKey == "e") {
                TreeNodeE[] memory e;
                (e, byteIdx) = readNodeE(cborData, byteIdx);
                node.entries = buildEntryKeys(e);
            } else {
                revert("unexpected node field");
            }
        }
        return (node, byteIdx);
    }
}
