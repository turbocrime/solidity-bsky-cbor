// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract ArrayTest is Test {
    // Test array handling
    function test_decodeEmptyArray() public pure {
        bytes memory cbor = hex"80"; // Empty array in CBOR
        uint32 i;
        uint len;
        (i, len) = cbor.Array(i);
        assertEq(len, 0);
    }

    function test_decodeLargeArray() public pure {
        // Array with 23 elements (just below the threshold for extended header)
        bytes memory cbor = hex"97010101010101010101010101010101010101010101010101";
        uint32 i;
        uint len;
        (i, len) = cbor.Array(i);
        assertEq(len, 23);
    }

    // Test nested structures
    function test_decodeNestedArray() public pure {
        // [[1, 2], [3, 4]]
        bytes memory cbor = hex"82820102820304";
        uint32 i;
        uint outerLen;
        uint innerLen;
        uint8 value;

        (i, outerLen) = cbor.Array(0);
        assertEq(outerLen, 2);

        (i, innerLen) = cbor.Array(i);
        assertEq(innerLen, 2);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 1);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 2);

        (i, innerLen) = cbor.Array(i);
        assertEq(innerLen, 2);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 3);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 4);
    }

    function test_decodeSingleElementArray() public pure {
        bytes memory cbor = hex"8118ff"; // [0xff]
        uint32 i;
        uint len;
        uint8 value;

        (i, len) = cbor.Array(0);
        assertEq(len, 1);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 0xff);
    }

    function test_decodeMixedArray() public pure {
        // [1, "a", [2]]
        bytes memory cbor = hex"830161618102";

        uint32 i;
        uint len;
        uint8 value;
        string memory strValue;
        uint innerLen;

        (i, len) = cbor.Array(i);
        assertEq(len, 3);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 1);

        (i, strValue) = cbor.String(i);
        assertEq(bytes1(bytes(strValue)), "a");

        (i, innerLen) = cbor.Array(i);
        assertEq(innerLen, 1);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 2);
    }
}
