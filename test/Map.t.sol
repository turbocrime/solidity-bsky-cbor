// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract MapTest is Test {
    function test_Map_empty() public {
        bytes memory cbor = hex"a0"; // Empty map in CBOR
        uint i;
        uint len;

        vm.startSnapshotGas("Map_empty");
        (i, len) = cbor.Map(0);
        vm.stopSnapshotGas();

        assert(len == 0);
    }

    function test_Map_single() public {
        bytes memory cbor = hex"a161618102"; // {"a": [2]}
        uint i;
        uint len;
        string memory key;
        uint arrayLen;
        uint8 value;

        vm.startSnapshotGas("Map_single");

        (i, len) = cbor.Map(i);
        assert(len == 1);

        (i, key) = cbor.String(i);
        assert(bytes1(bytes(key)) == "a");

        (i, arrayLen) = cbor.Array(i);
        assert(arrayLen == 1);
        (i, value) = cbor.UInt8(i);
        assert(value == 2);

        vm.stopSnapshotGas();
    }

    function test_Map_nested() public {
        // {"a": {"b": 1, "c": 2}, "d": 3}
        bytes memory cbor = hex"a26161a2616201616302616403";
        uint i;
        uint outerLen;
        uint innerLen;
        bytes32 key;
        uint8 value;

        vm.startSnapshotGas("Map_nested");

        (i, outerLen) = cbor.Map(0);
        assert(outerLen == 2);

        uint32 kLen;
        (i, key, kLen) = cbor.String32(i, 1);
        assert(kLen == 1);
        assert(bytes1(key) == "a");

        (i, innerLen) = cbor.Map(i);
        assert(innerLen == 2);

        (i, key, kLen) = cbor.String32(i, 1);
        assert(kLen == 1);
        assert(bytes1(key) == "b");
        (i, value) = cbor.UInt8(i);
        assert(value == 1);

        (i, key, kLen) = cbor.String32(i, 1);
        assert(kLen == 1);
        assert(bytes1(key) == "c");
        (i, value) = cbor.UInt8(i);
        assert(value == 2);

        (i, key, kLen) = cbor.String32(i, 1);
        assert(kLen == 1);
        assert(bytes1(key) == "d");
        (i, value) = cbor.UInt8(i);
        assert(value == 3);

        (i, outerLen) = cbor.Map(0);
        assert(outerLen == 2);

        (i, key,) = cbor.String32(i, 1);
        assert(key == "a");

        (i, innerLen) = cbor.Map(i);
        assert(innerLen == 2);

        (i, key,) = cbor.String32(i, 1);
        assert(key == "b");
        (i, value) = cbor.UInt8(i);
        assert(value == 1);

        (i, key,) = cbor.String32(i, 1);
        assert(key == "c");
        (i, value) = cbor.UInt8(i);
        assert(value == 2);

        (i, key,) = cbor.String32(i, 1);
        assert(key == "d");
        (i, value) = cbor.UInt8(i);
        assert(value == 3);

        vm.stopSnapshotGas();
    }

    function test_Map_nested2() public {
        // {"a": {"b": {"c": [1, 2, 3]}}}
        bytes memory cbor = hex"a16161a16162a1616383010203";
        uint i;
        uint len;
        bytes32 key;
        uint arrayLen;
        uint8 value;

        vm.startSnapshotGas("Map_nested2");

        (i, len) = cbor.Map(0);
        assert(len == 1);

        (i, key,) = cbor.String32(i, 1);
        assert(bytes1(key) == "a");

        (i, len) = cbor.Map(i);
        assert(len == 1);

        (i, key,) = cbor.String32(i, 1);
        assert(bytes1(key) == "b");

        (i, len) = cbor.Map(i);
        assert(len == 1);

        (i, key,) = cbor.String32(i, 1);
        assert(bytes1(key) == "c");

        (i, arrayLen) = cbor.Array(i);
        assert(arrayLen == 3);

        (i, value) = cbor.UInt8(i);
        assert(value == 1);

        (i, value) = cbor.UInt8(i);
        assert(value == 2);

        (i, value) = cbor.UInt8(i);
        assert(value == 3);

        vm.stopSnapshotGas();
    }
}
