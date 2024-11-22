// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CborDecode.sol";

library CidCbor {
    using CBORDecoder for bytes;

    uint8 private constant MAJOR_BYTE_STRING = 2;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant TAG_CID = 42;

    uint8 private constant EXPECTED_CID_LENGTH = 37;

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

    function expectCidTag(bytes memory cborData, uint byteIdx) internal pure returns (uint) {
        uint8 maj;
        uint value;
        (maj, value, byteIdx) = cborData.parseCborHeader(byteIdx);
        require(maj == MAJOR_TYPE_TAG, "expected tag major");
        require(value == TAG_CID, "expected tag 42 for CID");
        return byteIdx;
    }

    function readCidBytes32(bytes memory cborData, CidIndex idx) internal pure returns (CidBytes32) {
        uint cidIdx = CidIndex.unwrap(idx);
        require(cidIdx != 0, "Can't read a CID hash at index 0");
        bytes memory cidBytes = new bytes(MULTIHASH_SIZE_32);
        for (uint i = 0; i < MULTIHASH_SIZE_32; i++) {
            cidBytes[i] = cborData[cidIdx + i];
        }
        return CidBytes32.wrap(bytes32(cidBytes));
    }

    function readNullableCidIndex(bytes memory cborData, uint byteIdx) internal pure returns (CidIndex, uint) {
        if (cborData.isNullNext(byteIdx)) {
            return (CidIndex.wrap(0), byteIdx + 1);
        }

        return readCidIndex(cborData, byteIdx);
    }

    function readCidIndex(bytes memory cborData, uint byteIdx) internal pure returns (CidIndex, uint) {
        (byteIdx) = expectCidTag(cborData, byteIdx);
        (uint8 maj, uint len, uint bytesStart) = cborData.parseCborHeader(byteIdx);

        require(maj == MAJOR_BYTE_STRING, "expected byte string");
        require(len == EXPECTED_CID_LENGTH, "expected bytes length 37 for CID");

        // multibase format
        require(uint8(cborData[bytesStart]) == MULTIBASE_FORMAT, "expected multibase item");
        // cid format
        require(uint8(cborData[bytesStart + 1]) == CID_V1, "expected CID v1");
        require(uint8(cborData[bytesStart + 2]) == MULTICODEC_DAG_CBOR, "expected CID multicodec DAG-CBOR");
        require(uint8(cborData[bytesStart + 3]) == MULTIHASH_SHA_256, "expected CID multihash sha-256");
        require(uint8(cborData[bytesStart + 4]) == MULTIHASH_SIZE_32, "expected CID content size 32 bytes");

        return (CidIndex.wrap(bytesStart + 5), bytesStart + len);
    }
}
