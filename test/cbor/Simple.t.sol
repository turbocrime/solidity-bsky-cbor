// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract SimpleTest is Test {
    function test_decodeFalse() public pure {
        bytes memory cbor = hex"f4";
        uint i;
        bool value;
        (i, value) = cbor.Bool(i);
        assertEq(value, false);
    }

    function test_decodeTrue() public pure {
        bytes memory cbor = hex"f5";
        uint i;
        bool value;
        (i, value) = cbor.Bool(i);
        assertEq(value, true);
    }

    function test_decodeNull() public pure {
        bytes memory cbor = hex"f6";
        uint i;
        assertTrue(cbor.isNull(i));
    }

    function test_decodeUndefined() public pure {
        bytes memory cbor = hex"f7";
        uint i;
        assertTrue(cbor.isUndefined(i));
    }

    /*
    function test_decodeBreak() public pure {
        bytes memory cbor = hex"ff"; // Break in CBOR
        uint i;
        require(cbor.isBreak(i), "failed to decode break");
    }
    */
}
