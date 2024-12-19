// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract UIntTest is Test {
    // Test basic integer types
    function test_UInt8_short() public pure {
        bytes memory cbor = hex"17"; // max minor literal uint8
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(i);
        assert(value == 0x17);
    }

    function test_UInt8_extended() public pure {
        bytes memory cbor = hex"1818"; // minimum header extension uint8
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(i);
        assert(value == 0x18);
    }

    function testFail_UInt8_invalid() public pure {
        bytes memory cbor = hex"1817"; // extended header too small
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(i);
        assert(value == 0x17);
    }

    function test_UInt8_max() public pure {
        bytes memory cbor = hex"18ff"; // max uint8
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(0);
        assert(value == 0xff);
    }

    function testFail_UInt8_too_long() public pure {
        bytes memory cbor = hex"19ffff"; // uint16 value
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(0); // Should fail as value exceeds uint8
    }

    function test_UInt16_max() public pure {
        bytes memory cbor = hex"19ffff"; // max uint16
        uint i;
        uint16 value;
        (i, value) = cbor.UInt16(0);
        assert(value == 0xffff);
    }

    function test_UInt32_max() public pure {
        bytes memory cbor = hex"1affffffff"; // max uint32
        uint i;
        uint32 value;
        (i, value) = cbor.UInt32(0);
        assert(value == 0xffff_ffff);
    }

    function test_UInt64_max() public pure {
        bytes memory cbor = hex"1bffffffffffffffff"; // max uint64
        uint i;
        uint64 value;
        (i, value) = cbor.UInt64(0);
        assert(value == 0xffff_ffff_ffff_ffff);
    }
    // Additional integer tests

    function test_UInt8_0() public pure {
        bytes memory cbor = hex"00"; // minor literal zero
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(0);
        assert(value == 0);
    }

    function test_UInt8_1() public pure {
        bytes memory cbor = hex"01"; // minor literal 1
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(0);
        assert(value == 1);
    }

    function test_UInt() public pure {
        bytes memory cbor = hex"19ffff"; // max uint16
        uint i;
        uint value;
        (i, value) = cbor.UInt(0);
        assert(value == 0xffff);
    }

    function testFail_UInt16_too_long() public pure {
        bytes memory cbor = hex"1a00010000"; // uint32 value
        uint i;
        uint16 value;
        (i, value) = cbor.UInt16(0); // Should fail as value exceeds uint16
    }
}
