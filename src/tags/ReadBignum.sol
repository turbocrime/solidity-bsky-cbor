// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import "../ReadCbor.sol";

library ReadBigNum {
    using ReadCbor for bytes;

    uint256 internal constant UnsignedBigNum_MAX = type(uint256).max;
    uint256 internal constant NegativeBigNum_MAX = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint8 private constant TagUnsignedBigNum = 0x02;
    uint8 private constant TagNegativeBigNum = 0x03;

    function UInt256(bytes memory cbor, uint i) internal pure returns (uint, uint256) {
        uint8 len;
        i = cbor.Tag(i, TagUnsignedBigNum);
        (i, len) = cbor.headerExpectByteArg(i, MajorBytes);
        require(len <= 32, "bignum too large");

        uint256 bn = sliceBigNum(cbor, i, len);

        // require(bn <= UnsignedBigNum_MAX, "solidity uint256 will overflow");

        return (i + len, bn);
    }

    function NInt256(bytes memory cbor, uint i) internal pure returns (uint, int256) {
        uint8 len;
        i = cbor.Tag(i, TagNegativeBigNum);
        (i, len) = cbor.headerExpectByteArg(i, MajorBytes);
        require(len <= 32, "bignum too large");

        uint256 bn = sliceBigNum(cbor, i, len);

        require(bn <= NegativeBigNum_MAX, "solidity int256 will overflow");

        return (cbor.requireRange(i + len), int256(-1 - int256(bn)));
    }

    function sliceBigNum(bytes memory cbor, uint i, uint8 len) private pure returns (uint256 bn) {
        assembly ("memory-safe") {
            bn :=
                shr(
                    // Shift length
                    mul(sub(32, len), 8),
                    // Load bytes
                    mload(add(add(cbor, 32), i))
                )
        }
    }
}
