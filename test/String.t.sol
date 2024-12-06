// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract StringTest is Test {
    // Additional string tests
    function test_decodeMediumString() public pure {
        // String with 24 bytes (just above the threshold for one-byte length encoding)
        bytes memory cbor = hex"7818484848484848484848484848484848484848484848484848"; // 24 times 'H'
        uint32 i;
        string memory value;
        (i, value) = cbor.String(0);
        require(bytes(value).length == 24, "failed to decode 24-byte string");
    }

    // Test string handling
    function test_decodeEmptyString() public pure {
        bytes memory cbor = hex"60"; // zero-length string in CBOR
        uint32 i;
        string memory value;
        (i, value) = cbor.String(0);
        assertEq(bytes(value).length, 0);
    }

    function test_decodeShortString() public pure {
        // String with 23 bytes (just below the threshold for an extended header)
        bytes memory cbor = hex"77414141414141414141414141414141414141414141414141";
        uint32 i;
        string memory value;
        (i, value) = cbor.String(0);
        assertEq(bytes(value).length, 23);
    }

    function test_decodeLongString() public pure {
        // String with 24 bytes (just at the threshold for an extended header)
        bytes memory cbor = hex"7741414141414141414141414141414141414141414141414141";
        uint32 i;
        string memory value;
        (i, value) = cbor.String(0);
        assertEq(bytes(value).length, 23);
    }

    function testFail_invalidString() public pure {
        bytes memory cbor = hex"61"; // Incomplete string
        uint32 i;
        string memory value;
        (i, value) = cbor.String(i); // Will revert due to incomplete data
    }

    function test_String32_short() public pure {
        // 1 character "a"
        bytes memory cbor = hex"6161";
        uint32 i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.String32(0);
        cbor.requireComplete(i);
        assertEq(len, 1);
        assertEq(value, bytes32("a"));
    }

    function testFail_String32_long() public pure {
        // 33 characters "thisisquitealongstringisuppose..."
        bytes memory cbor = hex"78217468697369737175697465616C6F6E67737472696E6769737570706F73652E2E2E";
        uint32 i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.String32(0);
        cbor.requireComplete(i);
        assertEq(len, 33);
        assertEq(value, bytes32("thisisquitealongstringisuppose.."));
    }

    function testFail_String32_parameter() public pure {
        bytes memory cbor = hex"6161";
        uint32 i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.String32(0, 33);
    }

    function test_skipString() public pure {
        bytes memory cbor = hex"6161";
        uint32 i = cbor.skipString(0);
        cbor.requireComplete(i);
    }

    function testFail_skipString() public pure {
        bytes memory cbor = hex"50";
        uint32 i = cbor.skipString(0);
        cbor.requireComplete(i);
    }

    function test_String1() public pure {
        bytes memory cbor = hex"6161";
        uint32 i;
        bytes1 value;
        (i, value) = cbor.String1(0);
        cbor.requireComplete(i);
        assertEq(value, bytes1("a"));
    }

    function testFail_String1() public pure {
        bytes memory cbor = hex"60";
        uint32 i;
        bytes1 value;
        (i, value) = cbor.String1(0);
        cbor.requireComplete(i);
    }
}
