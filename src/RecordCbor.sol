// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CidCbor.sol";
import "./Compare.sol";

library RecordCbor {
    using CBORDecoder for bytes;

    struct Record {
        string text;
        string dollarType;
        string[] langs;
        string createdAt;
    }

    function readRecord(bytes memory cborData, uint byteIdx) internal pure returns (Record memory, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);

        require(mapLen == 4, "expected 4 fields in record");

        string memory text;
        string memory dollarType;
        string[] memory langs;
        string memory createdAt;

        for (uint i = 0; i < mapLen; i++) {
            string memory mapKey;
            (mapKey, byteIdx) = cborData.readString(byteIdx);
            if (Compare.stringsMatch(mapKey, "text")) {
                (text, byteIdx) = cborData.readString(byteIdx);
            } else if (Compare.stringsMatch(mapKey, "$type")) {
                (dollarType, byteIdx) = cborData.readString(byteIdx);
            } else if (Compare.stringsMatch(mapKey, "langs")) {
                uint arrayLength;
                (arrayLength, byteIdx) = cborData.readFixedArray(byteIdx);
                langs = new string[](arrayLength);
                for (uint j = 0; j < arrayLength; j++) {
                    (langs[j], byteIdx) = cborData.readString(byteIdx);
                }
            } else if (Compare.stringsMatch(mapKey, "createdAt")) {
                (createdAt, byteIdx) = cborData.readString(byteIdx);
            }
        }

        return (Record(text, dollarType, langs, createdAt), byteIdx);
    }
}
