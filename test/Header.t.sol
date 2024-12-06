// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract HeaderTest is Test {
    function test_header() public pure {
        bytes memory cbor = hex"69616361622031333132";
        (uint32 i, uint64 arg, uint8 major) = cbor.header(0);
        assertEq(i, 1);
        assertEq(arg, 9);
        assertEq(major, MajorText);
    }

    function testFail_parseArg_unsupportedMinor(uint8 minor) public pure {
        vm.assume(minor < 32);
        vm.assume(minor > MinorExtendU64);
        bytes memory cbor = abi.encodePacked((uint8(MajorUnsigned) << shiftMajor | minor));
        (uint32 i, uint64 arg, uint8 major) = cbor.header(0);
        assertEq(i, 1);
        assertGt(arg, 0);
        assertEq(major, MajorUnsigned);
    }

    function testFail_header_expectMajor() public pure {
        bytes memory cbor = hex"00";
        cbor.header(0, 1);
    }

    function testFail_header_expectMinor_failmajor() public pure {
        bytes memory cbor = hex"00";
        cbor.header(0, 1, 0);
    }

    function testFail_header_badext() public pure {
        bytes memory cbor = abi.encodePacked((uint8(MajorUnsigned) << shiftMajor | MinorExtendU8), uint8(0x00));
        cbor.header(0);
    }

    function testFail_header8_expectMajor() public pure {
        bytes memory cbor = hex"00";
        cbor.header8(0, 1);
    }

    function testFail_header32_badu8() public pure {
        bytes memory cbor = abi.encodePacked((uint8(MajorUnsigned) << shiftMajor | MinorExtendU8), uint8(0x00));
        (uint32 i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        cbor.requireComplete(i);
        assertEq(arg, 0x00);
    }

    function test_header32_u16() public pure {
        bytes memory cbor = abi.encodePacked((uint8(MajorUnsigned) << shiftMajor | MinorExtendU16), uint16(0xFFFF));
        (uint32 i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        cbor.requireComplete(i);
        assertEq(arg, 0xFFFF);
    }

    function test_header32_u32() public pure {
        bytes memory cbor = abi.encodePacked((uint8(MajorUnsigned) << shiftMajor | MinorExtendU32), uint32(0xFFFF1234));
        (uint32 i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        cbor.requireComplete(i);
        assertEq(arg, 0xFFFF1234);
    }

    function testFail_header32_u64() public pure {
        bytes memory cbor =
            abi.encodePacked((uint8(MajorUnsigned) << shiftMajor | MinorExtendU64), uint64(0xFFFF12345678));
        (uint32 i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        cbor.requireComplete(i);
        assertEq(arg, 0xFFFF12345678);
    }
}
