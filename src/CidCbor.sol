// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CborDecode.sol";
import "./Compare.sol";

library CidCbor {
    using CBORDecoder for bytes;

    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant TAG_CID = 42;

    uint8 private constant MULTIBASE_FORMAT = 0x00;
    uint8 private constant CID_V1 = 0x01;
    uint8 private constant MULTICODEC_DAG_CBOR = 0x71;
    uint8 private constant MULTIHASH_SHA_256 = 0x12;
    uint8 private constant MULTIHASH_SIZE_32 = 0x20;

    struct Cid {
        bytes4 prefix;
        bytes32 sha;
        bool nullish;
    }

    function cidMatches(Cid memory one, Cid memory other) internal pure returns (bool) {
        require(!(one.nullish && other.nullish), "two nullish cids should not be compared");
        return Compare.bytesMatch(
            abi.encodePacked(one.prefix, one.sha, one.nullish), abi.encodePacked(other.prefix, other.sha, other.nullish)
        );
    }

    function expectCidTag(bytes memory cborData, uint byteIdx) internal pure returns (uint) {
        uint8 maj;
        uint value;
        (maj, value, byteIdx) = cborData.parseCborHeader(byteIdx);
        require(maj == MAJOR_TYPE_TAG, "expected major type tag");
        require(value == TAG_CID, "expected tag for CID");
        return byteIdx;
    }

    function readCid(bytes memory cborData, uint byteIdx, bool expectTag)
        internal
        pure
        returns (Cid memory ret, uint)
    {
        if (expectTag) {
            (byteIdx) = expectCidTag(cborData, byteIdx);
        }

        if (cborData.isNullNext(byteIdx)) {
            ret.nullish = true;
            return (ret, byteIdx + 1);
        }

        bytes memory cidBytes;
        (cidBytes, byteIdx) = cborData.readBytes(byteIdx);

        if (cidBytes.length == 0) {
            ret.nullish = true;
            return (ret, byteIdx);
        }

        // multibase format
        require(uint8(cidBytes[0]) == MULTIBASE_FORMAT, "expected multibase item");

        // cid prefix
        require(uint8(cidBytes[1]) == CID_V1, "expected CID v1");
        require(uint8(cidBytes[2]) == MULTICODEC_DAG_CBOR, "expected CID multicodec DAG-CBOR");
        require(uint8(cidBytes[3]) == MULTIHASH_SHA_256, "expected CID multihash sha-256");
        require(uint8(cidBytes[4]) == MULTIHASH_SIZE_32, "expected CID content size 32 bytes");

        ret.prefix = bytes4(abi.encodePacked(cidBytes[1], cidBytes[2], cidBytes[3], cidBytes[4]));

        // cid data length plus prefix length
        require(cidBytes.length == 1 + 4 + MULTIHASH_SIZE_32, "expected cid data to be 37 bytes");

        // TODO: ;_;
        bytes memory shaBytes = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            shaBytes[i] = cidBytes[5 + i];
        }
        ret.sha = bytes32(shaBytes);

        return (ret, byteIdx);
    }
}
