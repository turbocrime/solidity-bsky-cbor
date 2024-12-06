// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract NIntTest is Test {
    // Test basic integer types
    function test_decodeShortNInt8() public pure {
        bytes memory cbor = hex"37"; // max minor literal uint8 for negative
        uint32 i;
        int16 value;
        (i, value) = cbor.NInt8(i);
        assertEq(value, -24); // -1 - 23
    }

    function test_decodeLongNInt8() public pure {
        bytes memory cbor = hex"3818"; // minimum header extension uint8 for negative
        uint32 i;
        int16 value;
        (i, value) = cbor.NInt8(i);
        assertEq(value, -25); // -1 - 24
    }

    function testFail_invalidNInt8() public pure {
        bytes memory cbor = hex"3817"; // extended header too small
        uint32 i;
        int16 value;
        (i, value) = cbor.NInt8(i);
        assertEq(value, -24);
    }

    function test_decodeNInt8() public pure {
        bytes memory cbor = hex"38ff"; // max uint8 for negative
        uint32 i;
        int16 value;
        (i, value) = cbor.NInt8(0);
        assertEq(value, -256); // -1 - 255
    }

    function testFail_notNInt8() public pure {
        bytes memory cbor = hex"39ffff"; // uint16 value
        uint32 i;
        int16 value;
        (i, value) = cbor.NInt8(0); // Should fail as value exceeds int8
    }

    function test_decodeNInt16() public pure {
        bytes memory cbor = hex"39ffff"; // max uint16 for negative
        uint32 i;
        int24 value;
        (i, value) = cbor.NInt16(0);
        assertEq(value, -65536); // -1 - 65535
    }

    function test_decodeNInt32() public pure {
        bytes memory cbor = hex"3affffffff"; // max uint32 for negative
        uint32 i;
        int40 value;
        (i, value) = cbor.NInt32(0);
        assertEq(value, -4294967296); // -1 - 4294967295
    }

    function test_decodeNInt64() public pure {
        bytes memory cbor = hex"3bffffffffffffffff"; // max uint64 for negative
        uint32 i;
        int72 value;
        (i, value) = cbor.NInt64(0);
        assertEq(value, -18446744073709551616); // -1 - 18446744073709551615
    }

    function test_decodeSmallNInts() public pure {
        bytes memory cbor = hex"20"; // minor literal -1
        uint32 i;
        int16 value;
        (i, value) = cbor.NInt8(0);
        assertEq(value, -1);

        cbor = hex"21"; // minor literal -2
        (i, value) = cbor.NInt8(0);
        assertEq(value, -2);
    }

    function testFail_outOfBoundsNInt16() public pure {
        bytes memory cbor = hex"3a00010000"; // uint32 value
        uint32 i;
        int24 value;
        (i, value) = cbor.NInt16(0); // Should fail as value exceeds int16
    }

    function testFail_badInt() public pure {
        bytes memory cbor = hex"f4";
        cbor.Int(0);
    }
}
