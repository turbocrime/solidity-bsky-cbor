// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/tags/ReadBignum.sol";
import "../src/ReadCbor.sol";

contract ReadBignum_Test is Test {
    using ReadCbor for bytes;
    using ReadBigNum for bytes;

    function test_UInt256_single() public pure {
        // 0x42 tagged with 0x02, followed by bytes(1) with value 0xFF
        bytes memory data = hex"c241ff";
        (uint pos, uint256 value) = data.UInt256(0);
        assertEq(value, 0xFF);
        assertEq(pos, data.length);
    }

    function test_UInt256_multi() public pure {
        // 0x42 tagged with 0x02, followed by bytes(4) with value 0x12345678
        bytes memory data = hex"c24412345678";
        (uint pos, uint256 value) = data.UInt256(0);
        assertEq(value, 0x12345678);
        assertEq(pos, data.length);
    }

    function test_UInt256_max() public pure {
        // 0x42 tagged with 0x02, followed by bytes(32) with max value
        bytes memory data = hex"c25820ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        (uint pos, uint256 value) = data.UInt256(0);
        assertEq(value, type(uint256).max);
        assertEq(pos, data.length);
    }

    function testFail_UInt256_large() public pure {
        // 0x42 tagged with 0x02, followed by bytes(33)
        bytes memory data = hex"c25821ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        (uint pos, uint256 value) = data.UInt256(0);
        assertEq(value, value, "unreachable");
        assertEq(pos, data.length);
    }

    function test_UInt256_middle() public pure {
        // Some preceding data, then our number, then trailing data
        bytes memory data = hex"82c24312345663666F6F";

        (uint pos, uint256 value) = data.UInt256(1); // Skip array header
        assertEq(value, 0x123456);
        assertEq(pos, 6); // Should point to the start of "foo"
    }

    function test_NInt256_single() public pure {
        // 0x42 tagged with 0x03, followed by bytes(1) with value 0xFF
        bytes memory data = hex"c341ff";
        (uint pos, int256 value) = data.NInt256(0);
        assertEq(value, -1 - 0xFF);
        assertEq(pos, data.length);
    }

    function test_NInt256_multi() public pure {
        // 0x42 tagged with 0x03, followed by bytes(4) with value 0x12345678
        bytes memory data = hex"c34412345678";
        (uint pos, int256 value) = data.NInt256(0);
        assertEq(value, -1 - 0x12345678);
        assertEq(pos, data.length);
    }

    function test_NInt256_max() public pure {
        bytes memory data = abi.encodePacked(hex"c35820", bytes32(ReadBigNum.NegativeBigNum_MAX));
        (uint pos, int256 value) = data.NInt256(0);
        assertEq(value, type(int256).min);
        assertEq(pos, data.length);
    }

    function testFail_NInt256_overflow() public pure {
        bytes memory data = abi.encodePacked(hex"c35820", bytes32(ReadBigNum.NegativeBigNum_MAX + 1));
        (uint pos, int256 value) = data.NInt256(0);
        // unreachable, but would pass (and fail this test) if the read failed to check
        assertGt(value, 0);
        assertEq(pos, data.length);
    }

    function testFail_NInt256_maxu256() public pure {
        bytes memory data = abi.encodePacked(hex"c35820", bytes32(type(uint256).max));
        (uint pos, int256 value) = data.NInt256(0);
        // unreachable, but would pass (and fail this test) if the read failed to check
        assertGt(value, 0);
        assertEq(pos, data.length);
    }

    function testFail_NInt256_large() public pure {
        // 0x42 tagged with 0x03, followed by bytes(33)
        bytes memory data = hex"c35821ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        (uint pos, int256 value) = data.NInt256(0);
        // unreachable, but would pass (and fail this test) if the read failed to check
        assertGt(value, 0);
        assertEq(pos, data.length);
    }

    function test_NInt256_middle() public pure {
        // Some preceding data, then our number, then trailing data
        bytes memory data = hex"82c34312345663666F6F";

        (uint pos, int256 value) = data.NInt256(1); // Skip array header
        assertEq(value, -1 - 0x123456);
        assertEq(pos, 6); // Should point to the start of "foo"
    }
}
