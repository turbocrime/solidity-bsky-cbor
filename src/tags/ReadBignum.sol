// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../ReadCbor.sol";

library ReadBignum {
    using ReadCbor for bytes;

    uint8 internal constant TagUnsignedBignum = 0x02;
    uint8 internal constant TagNegativeBignum = 0x03;

    function UInt256(bytes memory cbor, uint32 i) internal pure returns (uint32, uint256) {
        uint8 len;
        i = cbor.Tag(i, TagUnsignedBignum);
        (i, len) = cbor.header8(i, MajorBytes);
        require(len <= 32, "bignum too large");

        uint256 bn;
        assembly ("memory-safe") {
            bn :=
                shr(
                    // Shift length within word
                    mul(sub(32, len), 8),
                    // Load bytes
                    mload(add(add(cbor, 32), i))
                )
        }

        return (i + len, bn);
    }

    function NInt256(bytes memory cbor, uint32 i) internal pure returns (uint32, int256) {
        uint8 len;
        i = cbor.Tag(i, TagNegativeBignum);
        (i, len) = cbor.header8(i, MajorBytes);
        require(len <= 32, "bignum too large");

        uint256 bn;
        assembly ("memory-safe") {
            bn :=
                shr(
                    // Shift length within word
                    mul(sub(32, len), 8),
                    // Load bytes
                    mload(add(add(cbor, 32), i))
                )
        }

        require(bn < uint256(type(int256).min), "two's complement int256 will overflow");
        return (cbor.requireRange(i + len), int256(-1 - int256(bn)));
    }

    function Int256(bytes memory cbor, uint32 i) internal pure returns (uint32, int256) {
        uint64 tag;
        (, tag) = cbor.Tag(i);
        if (tag == TagUnsignedBignum) {
            uint256 ubn;
            (i, ubn) = UInt256(cbor, i);
            require(ubn <= uint256(type(int256).max), "two's complement int256 will overflow");
            return (i, int256(ubn));
        } else if (tag == TagNegativeBignum) {
            return NInt256(cbor, i);
        } else {
            revert("expected bignum tag");
        }
    }

    function Integer(bytes memory cbor, uint32 i) internal pure returns (uint32, int256) {
        return cbor.isTag(i) ? Int256(cbor, i) : cbor.Int(i);
    }
}
