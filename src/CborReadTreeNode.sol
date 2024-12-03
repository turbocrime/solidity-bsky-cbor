// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "./CborReadCid.sol";

using CborRead for bytes;
using CborReadCid for bytes;

struct TreeNode {
    CidSha256 left;
    TreeNodeEntry[] entries;
}

struct TreeNodeEntry {
    string key;
    CidSha256 value;
    CidSha256 tree;
}

library CborReadTreeNode {
    struct TreeNodeE {
        uint8 p; // prefixlen
        bytes k; // keysuffix
        CidSha256 v; // value
        CidSha256 t; // tree
    }

    function readEArray(bytes memory cborData, uint byteIdx) internal pure returns (uint, TreeNodeE[] memory) {
        uint arrayLen;
        (byteIdx, arrayLen) = cborData.Array(byteIdx);

        TreeNodeE[] memory ret = new TreeNodeE[](arrayLen);
        for (uint i = 0; i < arrayLen; i++) {
            (byteIdx, ret[i]) = readE(cborData, byteIdx);
        }

        return (byteIdx, ret);
    }

    function readE(bytes memory cborData, uint byteIdx) internal pure returns (uint, TreeNodeE memory) {
        uint mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);

        require(mapLen == 4, "expected 4 fields in node entry");

        uint8 p;
        bytes memory k;
        CidSha256 v;
        CidSha256 t;

        for (uint i = 0; i < mapLen; i++) {
            bytes32 mapKey;
            (byteIdx, mapKey,) = cborData.String32(byteIdx, 1);
            if (bytes1(mapKey) == "p") {
                (byteIdx, p) = cborData.UInt8(byteIdx);
            } else if (bytes1(mapKey) == "k") {
                (byteIdx, k) = cborData.Bytes(byteIdx);
            } else if (bytes1(mapKey) == "t") {
                (byteIdx, t) = cborData.NullableCid(byteIdx);
            } else if (bytes1(mapKey) == "v") {
                (byteIdx, v) = cborData.NullableCid(byteIdx);
            } else {
                revert("unexpected node entry field");
            }
        }

        return (byteIdx, TreeNodeE(p, k, v, t));
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

    function readTreeNode(bytes memory cborData, uint byteIdx) internal pure returns (uint, TreeNode memory node) {
        uint mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);
        require(mapLen == 2, "expected 2 fields in node");
        bytes32 mapKey;
        for (uint i = 0; i < mapLen; i++) {
            (byteIdx, mapKey,) = cborData.String32(byteIdx, 1);
            if (bytes1(mapKey) == "l") {
                (byteIdx, node.left) = cborData.NullableCid(byteIdx);
            } else if (bytes1(mapKey) == "e") {
                TreeNodeE[] memory e;
                (byteIdx, e) = readEArray(cborData, byteIdx);
                node.entries = buildEntryKeys(e);
            } else {
                revert("unexpected node field");
            }
        }
        return (byteIdx, node);
    }
}
