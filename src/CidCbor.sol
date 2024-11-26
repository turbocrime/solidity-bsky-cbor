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
     * will only encounter Cid v1 dag-cbor sha256, so we can refer to cid within
     * a larger bytestring by index of its sha256 hash segment. the caller is
     * responsible for indexing the correct bytestring when retrieving the hash.
     * due to cbor and cid formats, the hash segment will never index at 0, so
     * so 0 is used to indicate a null value.
     */
    type CidIndex is uint;

    /**
     * we will only encounter Cid v1 dag-cbor sha256, so the hash is bytes32
     */
    type CidBytes32 is bytes32;

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

    function readCidBytes32(bytes memory cborData, CidIndex idx) internal pure returns (CidBytes32) {
        uint cidIdx = CidIndex.unwrap(idx);
        require(cidIdx != 0, "Can't read a CID hash at index 0");

        bytes32 cidBytes;
        assembly ("memory-safe") {
            cidBytes := mload(add(cborData, add(0x20, cidIdx)))
        }
        return CidBytes32.wrap(cidBytes);
    }

    function readNullableCidIndex(bytes memory cborData, uint byteIdx) internal pure returns (CidIndex, uint) {
        if (cborData.isNullNext(byteIdx)) {
            return (CidIndex.wrap(0), byteIdx + 1);
        }

        return readCidIndex(cborData, byteIdx);
    }

    function readCidIndex(bytes memory cborData, uint byteIdx) internal pure returns (CidIndex, uint) {
        return readCidIndex_assembly(cborData, byteIdx);
    }

    function readCidIndex_assembly(bytes memory cborData, uint byteIdx) internal pure returns (CidIndex, uint) {
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
        require(cidHead == hex"D82A58250001711220", "expected CIDv1 dag-cbor sha256 head");
        byteIdx += 9;
        return (CidIndex.wrap(byteIdx), byteIdx + 32);
    }

    function readCidIndex_access(bytes memory cborData, uint byteIdx) internal pure returns (CidIndex, uint) {
        byteIdx = expectTagCid(cborData, byteIdx);
        byteIdx = expect37Bytes(cborData, byteIdx);

        // uint8 conversion is faster than assembly? lol
        require(uint8(cborData[byteIdx]) == MULTIBASE_FORMAT, "expected multibase item");
        // cid format always
        require(uint8(cborData[byteIdx + 1]) == CID_V1, "expected CID v1");
        require(uint8(cborData[byteIdx + 2]) == MULTICODEC_DAG_CBOR, "expected CID multicodec DAG-CBOR");
        require(uint8(cborData[byteIdx + 3]) == MULTIHASH_SHA_256, "expected CID multihash sha-256");
        require(uint8(cborData[byteIdx + 4]) == MULTIHASH_SIZE_32, "expected CID content size 32 bytes");

        return (CidIndex.wrap(byteIdx + 5), byteIdx + 37);
    }
}
