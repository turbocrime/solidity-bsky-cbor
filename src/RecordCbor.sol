// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";

library RecordCbor {
    using CBORDecoder for bytes;

    struct Record {
        string text;
        string dollarType;
    }

    function readRecord(bytes memory cborData, uint byteIdx) internal pure returns (Record memory ret, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);

        require(mapLen == 4, "expected 4 fields in record");

        for (uint i = 0; i < mapLen; i++) {
            bytes9 mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes9(byteIdx);
            if (bytes5(mapKey) == "text") {
                (ret.text, byteIdx) = cborData.readString(byteIdx);
            } else if (bytes6(mapKey) == "$type") {
                (ret.dollarType, byteIdx) = cborData.readString(byteIdx);
            } else if (bytes6(mapKey) == "langs") {
                uint langsLength;
                (langsLength, byteIdx) = cborData.readFixedArray(byteIdx);
                for (uint j = 0; j < langsLength; j++) {
                    // langs string unused.
                    byteIdx = cborData.skipString(byteIdx);
                }
            } else if (bytes9(mapKey) == "createdAt") {
                // createdAt string unused.
                // this field is arbitrary user-defined data. the useful and
                // verifiable timestamp is the signed commit repo revision field
                byteIdx = cborData.skipString(byteIdx);
            } else {
                revert("unexpected record key");
            }
        }

        return (ret, byteIdx);
    }
}
