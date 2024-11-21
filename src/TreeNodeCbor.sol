// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";
import "./Compare.sol";

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
        CidCbor.Cid memory v;
        CidCbor.Cid memory t;

        for (uint i = 0; i < mapLen; i++) {
            string memory mapKey;
            (mapKey, byteIdx) = cborData.readString(byteIdx);
            if (Compare.stringsMatch(mapKey, "p")) {
                (p, byteIdx) = cborData.readUInt8(byteIdx);
            } else if (Compare.stringsMatch(mapKey, "k")) {
                (k, byteIdx) = cborData.readBytes(byteIdx);
            } else if (Compare.stringsMatch(mapKey, "t")) {
                (t, byteIdx) = CidCbor.readCid(cborData, byteIdx);
            } else if (Compare.stringsMatch(mapKey, "v")) {
                (v, byteIdx) = CidCbor.readCid(cborData, byteIdx);
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
            string memory mapKey;
            (mapKey, byteIdx) = cborData.readString(byteIdx);
            if (Compare.stringsMatch(mapKey, "l")) {
                (node.left, byteIdx) = CidCbor.readCid(cborData, byteIdx);
            } else if (Compare.stringsMatch(mapKey, "e")) {
                TreeNodeE[] memory e;
                (e, byteIdx) = readNodeE(cborData, byteIdx);
                node.entries = buildEntryKeys(e);
            }
        }
        return (node, byteIdx);
    }
}
