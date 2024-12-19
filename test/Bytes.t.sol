// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract BytesTest is Test {
    function test_Bytes_empty() public {
        bytes memory cbor = hex"40"; // zero-length bytes in CBOR
        uint i;
        bytes memory value;

        vm.startSnapshotGas("Bytes_empty");
        (i, value) = cbor.Bytes(0);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
        assert(value.length == 0);
    }

    function test_Bytes_short() public {
        bytes memory cbor = hex"57000102030405060708090a0b0c0d0e0f1011121314151617";
        uint i;
        bytes memory value;

        vm.startSnapshotGas("Bytes_short");
        (i, value) = cbor.Bytes(0);
        vm.stopSnapshotGas();

        assert(value.length == 23);
    }

    function test_Bytes_extended() public {
        bytes memory cbor = hex"5818000102030405060708090a0b0c0d0e0f101112131415161718";
        uint i;
        bytes memory value;

        vm.startSnapshotGas("Bytes_extended");
        (i, value) = cbor.Bytes(0);
        vm.stopSnapshotGas();

        assert(value.length == 24);
    }

    function test_Bytes32_short() public {
        bytes memory cbor = hex"4100";
        uint i;
        bytes32 value;
        uint8 len;

        vm.startSnapshotGas("Bytes32_short");
        (i, value, len) = cbor.Bytes32(0);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
        assert(len == 1);
        assert(value == bytes32(hex"00"));
    }

    function testFail_Bytes32_too_long() public pure {
        // 33 bytes of data
        bytes memory cbor = hex"5821000102030405060708090a0b0c0d0e0f101112131415161718192021";
        uint i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.Bytes32(0);
        assert(i == cbor.length);
        assert(len == 33);
        assert(value == bytes32(hex"000102030405060708090a0b0c0d0e0f101112131415161718192021"));
    }

    function testFail_Bytes32_parameter() public pure {
        bytes memory cbor = hex"4100";
        uint i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.Bytes32(0, 33);
    }

    function test_skipBytes() public {
        bytes memory cbor = hex"4100";

        vm.startSnapshotGas("skipBytes");
        uint i = cbor.skipBytes(0);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
    }

    function testFail_skipBytes() public pure {
        bytes memory cbor = hex"30";
        uint i = cbor.skipBytes(0);
        assert(i == cbor.length);
    }
}
