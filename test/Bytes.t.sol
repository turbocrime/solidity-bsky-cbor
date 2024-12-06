// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract BytesTest is Test {
    // Additional bytes tests
    function test_decodeMediumBytes() public pure {
        // Bytes with 24 bytes (just above the threshold for one-byte length encoding)
        bytes memory cbor = hex"5818000102030405060708090a0b0c0d0e0f101112131415161718"; // 24 bytes of incrementing values
        uint32 i;
        bytes memory value;
        (i, value) = cbor.Bytes(0);
        require(value.length == 24, "failed to decode 24-byte bytes");
    }

    function test_decodeEmptyBytes() public pure {
        bytes memory cbor = hex"40"; // zero-length bytes in CBOR
        uint32 i;
        bytes memory value;
        (i, value) = cbor.Bytes(0);
        cbor.requireComplete(i);
        assertEq(value.length, 0);
    }

    function test_decodeShortBytes() public pure {
        // Bytes with 23 bytes (just below the threshold for an extended header)
        bytes memory cbor = hex"57000102030405060708090a0b0c0d0e0f1011121314151617";
        uint32 i;
        bytes memory value;
        (i, value) = cbor.Bytes(0);
        assertEq(value.length, 23);
    }

    function test_decodeLongBytes() public pure {
        // Bytes with 24 bytes (just at the threshold for an extended header)
        bytes memory cbor = hex"5818000102030405060708090a0b0c0d0e0f101112131415161718";
        uint32 i;
        bytes memory value;
        (i, value) = cbor.Bytes(0);
        assertEq(value.length, 24);
    }

    function testFail_invalidBytes() public pure {
        bytes memory cbor = hex"41"; // Incomplete bytes
        uint32 i;
        bytes memory value;
        (i, value) = cbor.Bytes(i); // Will revert due to incomplete data
    }

    function test_Bytes32_short() public pure {
        // 1 byte of data
        bytes memory cbor = hex"4100";
        uint32 i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.Bytes32(0);
        cbor.requireComplete(i);
        assertEq(len, 1);
        assertEq(value, bytes32(hex"00"));
    }

    function testFail_Bytes32_long() public pure {
        // 33 bytes of data
        bytes memory cbor = hex"5821000102030405060708090a0b0c0d0e0f101112131415161718192021";
        uint32 i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.Bytes32(0);
        cbor.requireComplete(i);
        assertEq(len, 33);
        assertEq(value, bytes32(hex"000102030405060708090a0b0c0d0e0f101112131415161718192021"));
    }

    function testFail_Bytes32_parameter() public pure {
        bytes memory cbor = hex"4100";
        uint32 i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.Bytes32(0, 33);
    }

    function test_skipBytes() public pure {
        bytes memory cbor = hex"4100";
        uint32 i = cbor.skipBytes(0);
        cbor.requireComplete(i);
    }

    function testFail_skipBytes() public pure {
        bytes memory cbor = hex"30";
        uint32 i = cbor.skipBytes(0);
        cbor.requireComplete(i);
    }
}
