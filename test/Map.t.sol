// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract MapTest is Test {
    // Test map handling
    function test_decodeEmptyMap() public pure {
        bytes memory cbor = hex"a0"; // Empty map in CBOR
        uint32 i;
        uint len;
        (i, len) = cbor.Map(0);
        require(len == 0, "failed to decode empty map");
    }

    // Additional map tests
    function test_decodeSingleKeyMap() public pure {
        bytes memory cbor = hex"a161618102"; // {"a": [2]}
        uint32 i;
        uint len;
        string memory key;
        uint arrayLen;
        uint8 value;

        (i, len) = cbor.Map(i);
        assertEq(len, 1);

        (i, key) = cbor.String(i);
        assertEq(bytes1(bytes(key)), "a");

        (i, arrayLen) = cbor.Array(i);
        assertEq(arrayLen, 1);
        (i, value) = cbor.UInt8(i);
        assertEq(value, 2);
    }

    // Test deeply nested structures
    function test_deeplyNestedStructure() public pure {
        // {"a": {"b": {"c": [1, 2, 3]}}}
        bytes memory cbor = hex"a16161a16162a1616383010203";
        uint32 i;
        uint len;
        bytes32 key;
        uint arrayLen;
        uint8 value;

        (i, len) = cbor.Map(0);
        assertEq(len, 1);

        (i, key,) = cbor.String32(i, 1);
        assertEq(bytes1(key), "a");

        (i, len) = cbor.Map(i);
        assertEq(len, 1);

        (i, key,) = cbor.String32(i, 1);
        assertEq(bytes1(key), "b");

        (i, len) = cbor.Map(i);
        assertEq(len, 1);

        (i, key,) = cbor.String32(i, 1);
        assertEq(bytes1(key), "c");

        (i, arrayLen) = cbor.Array(i);
        assertEq(arrayLen, 3);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 1);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 2);

        (i, value) = cbor.UInt8(i);
        assertEq(value, 3);
    }

    function test_decodeNestedMap() public pure {
        // {"a": {"b": 1, "c": 2}, "d": 3}
        bytes memory cbor = hex"a26161a2616201616302616403";
        uint32 i;
        uint outerLen;
        uint innerLen;
        bytes32 key;
        uint8 value;

        (i, outerLen) = cbor.Map(0);
        require(outerLen == 2, "outer map length mismatch");

        /*
        uint32 kLen;
        (i, key, kLen) = cbor.String32(i, 1);
        require(kLen == 1 && bytes1(key) == "a", "first key mismatch");

        (i, innerLen) = cbor.Map(i);
        require(innerLen == 2, "inner map length mismatch");

        (i, key, kLen) = cbor.String32(i, 1);
        require(kLen == 1 && bytes1(key) == "b", "inner first key mismatch");
        (i, value) = cbor.UInt8(i);
        require(value == 1, "inner first value mismatch");

        (i, key, kLen) = cbor.String32(i, 1);
        require(kLen == 1 && bytes1(key) == "c", "inner second key mismatch");
        (i, value) = cbor.UInt8(i);
        require(value == 2, "inner second value mismatch");

        (i, key, kLen) = cbor.String32(i, 1);
        require(kLen == 1 && bytes1(key) == "d", "second key mismatch");
        (i, value) = cbor.UInt8(i);
        require(value == 3, "second value mismatch");
        */
        (i, outerLen) = cbor.Map(0);
        require(outerLen == 2, "outer map length mismatch");

        (i, key,) = cbor.String32(i, 1);
        require((key) == "a", "first key mismatch");

        (i, innerLen) = cbor.Map(i);
        require(innerLen == 2, "inner map length mismatch");

        (i, key,) = cbor.String32(i, 1);
        require((key) == "b", "inner first key mismatch");
        (i, value) = cbor.UInt8(i);
        require(value == 1, "inner first value mismatch");

        (i, key,) = cbor.String32(i, 1);
        require((key) == "c", "inner second key mismatch");
        (i, value) = cbor.UInt8(i);
        require(value == 2, "inner second value mismatch");

        (i, key,) = cbor.String32(i, 1);
        require((key) == "d", "second key mismatch");
        (i, value) = cbor.UInt8(i);
        require(value == 3, "second value mismatch");
    }
}
