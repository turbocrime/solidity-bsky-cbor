// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";

library TreeNodeCbor {
    using CBORDecoder for bytes;

    struct TreeNode {
        CidCbor.Cid left;
        TreeNodeEntry[] entries;
    }

    struct TreeNodeEntry {
        string key;
        CidCbor.Cid value;
        CidCbor.Cid tree;
    }

    struct TreeNodeE {
        uint8 p; // prefixlen
        bytes k; // keysuffix
        CidCbor.Cid v; // value
        CidCbor.Cid t; // tree
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
        CidCbor.Cid v;
        CidCbor.Cid t;

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

    function buildEntryKeys(TreeNodeE[] memory e) internal pure returns (TreeNodeEntry[] memory) {
        TreeNodeEntry[] memory entries = new TreeNodeEntry[](e.length);
        bytes memory previousKey = new bytes(0);
        for (uint i = 0; i < e.length; i++) {
            uint8 p = e[i].p;
            bytes memory k = e[i].k;
            bytes memory key = new bytes(p + k.length);
            // Calculate number of words needed
            uint pWords = (p + 31) / 32; // ceil(p/32)
            uint kWords = (k.length + 31) / 32; // ceil(k.length/32)
            // init loop variable
            uint j;

            assembly {
                for { j := 0 } lt(j, pWords) { j := add(j, 1) } {
                    mstore(add(key, add(0x20, mul(j, 32))), mload(add(previousKey, add(0x20, mul(j, 32)))))
                }

                for { j := 0 } lt(j, kWords) { j := add(j, 1) } {
                    mstore(add(add(key, 0x20), add(p, mul(j, 32))), mload(add(k, add(0x20, mul(j, 32)))))
                }
            }
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
