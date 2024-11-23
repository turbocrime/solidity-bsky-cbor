// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";

library TreeNodeCbor {
    using CBORDecoder for bytes;

    struct TreeNode {
        CidCbor.CidIndex left;
        TreeNodeEntry[] entries;
    }

    struct TreeNodeEntry {
        string key;
        CidCbor.CidIndex value;
        CidCbor.CidIndex tree;
    }

    struct TreeNodeE {
        uint8 p; // prefixlen
        bytes k; // keysuffix
        CidCbor.CidIndex v; // value
        CidCbor.CidIndex t; // tree
    }

    function readNodeE(bytes memory cborData, uint byteIdx) internal pure returns (TreeNodeE[] memory ret, uint) {
        uint arrayLen;
        (arrayLen, byteIdx) = cborData.readFixedArray(byteIdx);

        ret = new TreeNodeE[](arrayLen);
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
        CidCbor.CidIndex v;
        CidCbor.CidIndex t;

        for (uint i = 0; i < mapLen; i++) {
            bytes1 mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes1(byteIdx);
            if (mapKey == "p") {
                (p, byteIdx) = cborData.readUInt8(byteIdx);
            } else if (mapKey == "k") {
                (k, byteIdx) = cborData.readBytes(byteIdx);
            } else if (mapKey == "t") {
                (t, byteIdx) = CidCbor.readNullableCidIndex(cborData, byteIdx);
            } else if (mapKey == "v") {
                (v, byteIdx) = CidCbor.readNullableCidIndex(cborData, byteIdx);
            }
        }

        return (TreeNodeE(p, k, v, t), byteIdx);
    }

    function buildEntryKeys(TreeNodeE[] memory e) internal pure returns (TreeNodeEntry[] memory) {
        return buildEntryKeys_assembly(e);
    }

    function buildEntryKeys_assembly(TreeNodeE[] memory e) internal pure returns (TreeNodeEntry[] memory) {
        TreeNodeEntry[] memory entries = new TreeNodeEntry[](e.length);
        bytes memory previousKey = new bytes(0);
        for (uint i = 0; i < e.length; i++) {
            uint8 p = e[i].p;
            bytes memory k = e[i].k;
            bytes memory key = new bytes(p + k.length);
            //console.log("i=%s", i);
            //console.log("before assembly p=%s k.length=%s key.length=%s", p, k.length, key.length);
            // Calculate number of words needed
            uint pWords = (p + 31) / 32; // ceil(p/32)
            uint kWords = (k.length + 31) / 32; // ceil(k.length/32)
            uint j;

            assembly {
                for { j := 0 } lt(j, pWords) { j := add(j, 1) } {
                    mstore(add(key, add(0x20, mul(j, 32))), mload(add(previousKey, add(0x20, mul(j, 32)))))
                }

                for { j := 0 } lt(j, kWords) { j := add(j, 1) } {
                    mstore(add(add(key, 0x20), add(p, mul(j, 32))), mload(add(k, add(0x20, mul(j, 32)))))
                }
            }
            //console.log("after assembly key=%s key.length=%s", string(key), key.length);
            entries[i] = TreeNodeEntry(string(key), e[i].v, e[i].t);
            previousKey = key;
        }
        return entries;
    }

    function buildEntryKeys_loop(TreeNodeE[] memory e) internal pure returns (TreeNodeEntry[] memory) {
        TreeNodeEntry[] memory entries = new TreeNodeEntry[](e.length);
        bytes memory previousKey = new bytes(0);
        for (uint i = 0; i < e.length; i++) {
            uint8 p = e[i].p;
            bytes memory k = e[i].k;
            bytes memory key = new bytes(p + k.length);
            for (uint j = 0; j < p; j++) {
                key[j] = previousKey[j];
            }
            for (uint j = p; j < p + k.length; j++) {
                key[j] = k[j - p];
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
                (node.left, byteIdx) = CidCbor.readNullableCidIndex(cborData, byteIdx);
            } else if (mapKey == "e") {
                TreeNodeE[] memory e;
                (e, byteIdx) = readNodeE(cborData, byteIdx);
                node.entries = buildEntryKeys(e);
            }
        }
        return (node, byteIdx);
    }
}
