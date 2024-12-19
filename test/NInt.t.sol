// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract NIntTest is Test {
    // Test basic integer types
    function test_NInt8_short() public {
        bytes memory cbor = hex"37"; // max minor literal uint8 for negative
        uint i;
        int16 value;

        vm.startSnapshotGas("NInt8_short");
        (i, value) = cbor.NInt8(i);
        vm.stopSnapshotGas();
        assert(value == -24); // -1 - 23
    }

    function test_NInt8_long() public {
        bytes memory cbor = hex"3818"; // minimum header extension uint8 for negative
        uint i;
        int16 value;

        vm.startSnapshotGas("NInt8_long");
        (i, value) = cbor.NInt8(i);
        vm.stopSnapshotGas();
        assert(value == -25); // -1 - 24
    }

    function testFail_NInt8_invalid() public pure {
        bytes memory cbor = hex"3817"; // extended header too small
        uint i;
        int16 value;
        (i, value) = cbor.NInt8(i);
        assert(value == -24);
    }

    function test_NInt8_max() public {
        bytes memory cbor = hex"38ff"; // max uint8 for negative
        uint i;
        int16 value;

        vm.startSnapshotGas("NInt8_max");
        (i, value) = cbor.NInt8(0);
        vm.stopSnapshotGas();
        assert(value == -256); // -1 - 255
    }

    function testFail_NInt8_too_long() public pure {
        bytes memory cbor = hex"39ffff"; // uint16 value
        uint i;
        int16 value;
        (i, value) = cbor.NInt8(0); // Should fail as value exceeds int8
    }

    function test_NInt16() public {
        bytes memory cbor = hex"39ffff"; // max uint16 for negative
        uint i;
        int24 value;

        vm.startSnapshotGas("NInt16");
        (i, value) = cbor.NInt16(0);
        vm.stopSnapshotGas();
        assert(value == -65536); // -1 - 65535
    }

    function test_NInt32() public {
        bytes memory cbor = hex"3affffffff"; // max uint32 for negative
        uint i;
        int40 value;

        vm.startSnapshotGas("NInt32");
        (i, value) = cbor.NInt32(0);
        vm.stopSnapshotGas();
        assert(value == -4294967296); // -1 - 4294967295
    }

    function test_NInt64() public {
        bytes memory cbor = hex"3bffffffffffffffff"; // max uint64 for negative
        uint i;
        int72 value;

        vm.startSnapshotGas("NInt64");
        (i, value) = cbor.NInt64(0);
        vm.stopSnapshotGas();
        assert(value == -18446744073709551616); // -1 - 18446744073709551615
    }

    function test_NInt8_0() public {
        bytes memory cbor = hex"20"; // 0 minor literal
        uint i;
        int16 value;

        vm.startSnapshotGas("NInt8_0");
        (i, value) = cbor.NInt8(0);
        vm.stopSnapshotGas();
        assert(value == -1);
    }

    function test_NInt8_1() public {
        bytes memory cbor = hex"21"; // 1 minor literal
        uint i;
        int16 value;

        vm.startSnapshotGas("NInt8_1");
        (i, value) = cbor.NInt8(0);
        vm.stopSnapshotGas();
        assert(value == -2);
    }

    function testFail_NInt16_too_long() public pure {
        bytes memory cbor = hex"3a00010000"; // uint32 value
        cbor.NInt16(0); // Should fail as value exceeds int16
    }

    function testFail_NInt16_invalid() public pure {
        bytes memory cbor = hex"f4";
        cbor.NInt16(0);
    }

    function test_NInt() public {
        bytes memory cbor = hex"3bffff";
        uint i;
        int72 value;

        vm.startSnapshotGas("NInt");
        (i, value) = cbor.NInt(0);
        vm.stopSnapshotGas();
    }
}
