// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";

library CommitCbor {
    using CBORDecoder for bytes;

    uint8 private constant COMMIT_VERSION = 3;

    struct Commit {
        string did;
        uint8 version;
        CidCbor.CidIndex data;
        string rev;
        CidCbor.CidIndex prev;
    }

    function readCommit(bytes memory cborData, uint byteIdx) internal pure returns (Commit memory ret, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);

        require(mapLen == 5, "expected 5 fields in commit");

        for (uint i = 0; i < mapLen; i++) {
            bytes7 mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes7(byteIdx);
            if (bytes7(mapKey) == "version") {
                (ret.version, byteIdx) = cborData.readUInt8(byteIdx);
                require(ret.version == COMMIT_VERSION, "commit version number must be 3");
            } else if (bytes5(mapKey) == "data") {
                (ret.data, byteIdx) = CidCbor.readCidIndex(cborData, byteIdx);
            } else if (bytes5(mapKey) == "prev") {
                // TODO: skip this field?
                (ret.prev, byteIdx) = CidCbor.readNullableCidIndex(cborData, byteIdx);
            } else if (bytes4(mapKey) == "did") {
                (ret.did, byteIdx) = cborData.readString(byteIdx);
                // TODO: other did formats?
                require(bytes(ret.did).length == 32, "commit did string must be 32 bytes");
            } else if (bytes4(mapKey) == "rev") {
                // monotonic commit timestamp
                (ret.rev, byteIdx) = cborData.readString(byteIdx);
            } else {
                revert("unexpected commit field");
            }
        }

        return (ret, byteIdx);
    }
}
