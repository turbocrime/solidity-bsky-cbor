// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CborDecode.sol";

library CidCbor {
    using CBORDecoder for bytes;

    uint8 private constant TAG_CID = 42;

    uint8 private constant MULTIBASE_FORMAT = 0x00;
    uint8 private constant CID_V1 = 0x01;
    uint8 private constant MULTICODEC_DAG_CBOR = 0x71;
    uint8 private constant MULTIHASH_SHA_256 = 0x12;
    uint8 private constant MULTIHASH_SIZE_32 = 0x20;

    /**
     * we will only encounter Cid v1 dag-cbor sha256, so the entire hash is 32
     * bytes and will fit in a uint256
     */
    type Cid is uint256;

    function expectTagCid(bytes memory cborData, uint byteIdx) internal pure returns (uint) {
        uint8 head = uint8(cborData[byteIdx]);
        uint8 tagValue = uint8(cborData[byteIdx + 1]);
        require(head == MajorTag << shiftMajor | MinorExtend1, "expected tag head with 1-byte extension");
        require(tagValue == TAG_CID, "expected tag 42 for CID");
        return byteIdx + 2;
    }

    function expect37Bytes(bytes memory cborData, uint byteIdx) internal pure returns (uint) {
        require(
            uint8(cborData[byteIdx]) == MajorBytes << shiftMajor | MinorExtend1,
            "expected byte head with 1-byte extension"
        );
        require(uint8(cborData[byteIdx + 1]) == 37, "expected 37 bytes for CID");
        byteIdx += 2;
        return byteIdx;
    }

    function readNullableCid(bytes memory cborData, uint byteIdx) internal pure returns (Cid, uint) {
        if (cborData.isNullNext(byteIdx)) {
            return (Cid.wrap(0), byteIdx + 1);
        }
        return readCid(cborData, byteIdx);
    }

    function readCid(bytes memory cborData, uint byteIdx) internal pure returns (Cid, uint) {
        bytes9 cidHead;
        assembly ("memory-safe") {
            cidHead := mload(add(cborData, add(0x20, byteIdx)))
        }

        // all cids encountered will contain this 9-byte header
        // D8 2A cbor tag(42) cid
        // 58 25 cbor bytes(37) total length
        // 00 multibase format
        // 01 CID version
        // 71 multicodec DAG-CBOR
        // 12 multihash sha-256
        // 20 hash size 32 bytes
        require(cidHead == hex"D82A58250001711220", "expected CIDv1 dag-cbor sha256 header sequence");
        byteIdx += 9;
        uint256 cidHash;
        assembly ("memory-safe") {
            cidHash := mload(add(cborData, add(0x20, byteIdx)))
        }
        return (Cid.wrap(cidHash), byteIdx + 32);
    }
}
