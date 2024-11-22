// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";
import "./Compare.sol";

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
            string memory mapKey;
            (mapKey, byteIdx) = cborData.readString(byteIdx);
            if (Compare.stringsMatch(mapKey, "did")) {
                (ret.did, byteIdx) = cborData.readString(byteIdx);
                require(bytes(ret.did).length == 32, "did string must be 32 bytes");
            } else if (Compare.stringsMatch(mapKey, "version")) {
                (ret.version, byteIdx) = cborData.readUInt8(byteIdx);
                require(ret.version == COMMIT_VERSION, "unexpected commit version");
            } else if (Compare.stringsMatch(mapKey, "data")) {
                console.log("data", byteIdx);
                (ret.data, byteIdx) = CidCbor.readCidIndex(cborData, byteIdx);
            } else if (Compare.stringsMatch(mapKey, "rev")) {
                (ret.rev, byteIdx) = cborData.readString(byteIdx);
            } else if (Compare.stringsMatch(mapKey, "prev")) {
                console.log("prev", byteIdx);
                (ret.prev, byteIdx) = CidCbor.readNullableCidIndex(cborData, byteIdx);
            }
        }

        return (ret, byteIdx);
    }
}
