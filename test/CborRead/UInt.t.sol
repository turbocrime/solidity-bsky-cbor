// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../../src/CborRead.sol";

using CborRead for bytes;

/// @author turbocrime
contract UInt8Test is Test {
    // Test basic integer types
    function test_decodeShortUInt8() public pure {
        bytes memory cbor = hex"17"; // max minor literal uint8
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(i);
        assertEq(value, 0x17);
    }

    function test_decodeLongUInt8() public pure {
        bytes memory cbor = hex"1818"; // minimum header extension uint8
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(i);
        assertEq(value, 0x18);
    }

    function testFail_invalidUInt8() public pure {
        bytes memory cbor = hex"1817"; // extended header too small
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(i);
        assertEq(value, 0x17);
    }

    function test_decodeUInt8() public pure {
        bytes memory cbor = hex"18ff"; // max uint8
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(0);
        assertEq(value, 0xff);
    }

    function testFail_notUInt8() public pure {
        bytes memory cbor = hex"19ffff"; // uint16 value
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(0); // Should fail as value exceeds uint8
    }

    function test_decodeUInt16() public pure {
        bytes memory cbor = hex"19ffff"; // max uint16
        uint i;
        uint16 value;
        (i, value) = cbor.UInt16(0);
        assertEq(value, 0xffff);
    }

    function test_decodeUInt32() public pure {
        bytes memory cbor = hex"1affffffff"; // max uint32
        uint i;
        uint32 value;
        (i, value) = cbor.UInt32(0);
        assertEq(value, 0xffff_ffff);
    }

    function test_decodeUInt64() public pure {
        bytes memory cbor = hex"1bffffffffffffffff"; // max uint64
        uint i;
        uint64 value;
        (i, value) = cbor.UInt64(0);
        assertEq(value, 0xffff_ffff_ffff_ffff);
    }
    // Additional integer tests

    function test_decodeSmallInts() public pure {
        bytes memory cbor = hex"00"; // minor literal zero
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(0);
        assertEq(value, 0);

        cbor = hex"01"; // minor literal 1
        (i, value) = cbor.UInt8(0);
        assertEq(value, 1);
    }

    function testFail_outOfBoundsUInt16() public pure {
        bytes memory cbor = hex"1a00010000"; // uint32 value
        uint i;
        uint16 value;
        (i, value) = cbor.UInt16(0); // Should fail as value exceeds uint16
    }
}
