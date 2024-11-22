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
            bytes8 mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes8(byteIdx);
            if ((mapKey == "did")) {
                (ret.did, byteIdx) = cborData.readString(byteIdx);
                require(bytes(ret.did).length == 32, "did string must be 32 bytes");
            } else if ((mapKey == "version")) {
                (ret.version, byteIdx) = cborData.readUInt8(byteIdx);
                require(ret.version == COMMIT_VERSION, "unexpected commit version");
            } else if ((mapKey == "data")) {
                (ret.data, byteIdx) = CidCbor.readCidIndex(cborData, byteIdx);
            } else if ((mapKey == "rev")) {
                (ret.rev, byteIdx) = cborData.readString(byteIdx);
            } else if ((mapKey == "prev")) {
                (ret.prev, byteIdx) = CidCbor.readNullableCidIndex(cborData, byteIdx);
            } else {
                revert("unexpected commit key");
            }
        }

        return (ret, byteIdx);
    }
}
