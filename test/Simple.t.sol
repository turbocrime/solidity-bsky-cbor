// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract SimpleTest is Test {
    function test_decodeFalse() public pure {
        bytes memory cbor = hex"f4";
        uint32 i;
        bool value;
        (i, value) = cbor.Bool(i);
        assertEq(value, false);
    }

    function test_decodeTrue() public pure {
        bytes memory cbor = hex"f5";
        uint32 i;
        bool value;
        (i, value) = cbor.Bool(i);
        assertEq(value, true);
    }

    function testFail_decodeBool() public pure {
        bytes memory cbor = hex"f6";
        uint32 i;
        bool value;
        (i, value) = cbor.Bool(i);
    }

    function test_skipNull() public pure {
        bytes memory cbor = hex"f6";
        uint32 i;
        (i) = cbor.Null(i);
    }

    function testFail_skipNull() public pure {
        bytes memory cbor = hex"f7";
        uint32 i;
        (i) = cbor.Null(i);
    }

    function test_skipUndefined() public pure {
        bytes memory cbor = hex"f7";
        uint32 i;
        (i) = cbor.Undefined(i);
    }

    function testFail_skipUndefined() public pure {
        bytes memory cbor = hex"f6";
        uint32 i;
        (i) = cbor.Undefined(i);
    }
}
