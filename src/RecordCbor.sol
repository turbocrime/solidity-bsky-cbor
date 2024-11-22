// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";

library RecordCbor {
    using CBORDecoder for bytes;

    struct Record {
        string text;
        string dollarType;
    }

    function readRecord(bytes memory cborData, uint byteIdx) internal pure returns (Record memory, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);

        require(mapLen == 4, "expected 4 fields in record");

        string memory text;
        string memory dollarType;

        for (uint i = 0; i < mapLen; i++) {
            bytes memory mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes(byteIdx);
            if (bytes5(mapKey) == "text") {
                (text, byteIdx) = cborData.readString(byteIdx);
            } else if (bytes6(mapKey) == "$type") {
                (dollarType, byteIdx) = cborData.readString(byteIdx);
            } else if (bytes6(mapKey) == "langs") {
                uint langsLength;
                (langsLength, byteIdx) = cborData.readFixedArray(byteIdx);
                for (uint j = 0; j < langsLength; j++) {
                    byteIdx = cborData.skipString(byteIdx);
                }
            } else if (bytes10(mapKey) == "createdAt") {
                byteIdx = cborData.skipString(byteIdx);
            } else {
                revert("unexpected record key");
            }
        }

        return (Record(text, dollarType), byteIdx);
    }
}
