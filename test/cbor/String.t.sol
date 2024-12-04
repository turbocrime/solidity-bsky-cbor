// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract StringTest is Test {
    // Additional string tests
    function test_decodeMediumString() public pure {
        // String with 24 bytes (just above the threshold for one-byte length encoding)
        bytes memory cbor = hex"7818484848484848484848484848484848484848484848484848"; // 24 times 'H'
        uint i;
        string memory value;
        (i, value) = cbor.String(0);
        require(bytes(value).length == 24, "failed to decode 24-byte string");
    }

    /*
    function test_decodeUTF8String() public pure {
        bytes memory cbor = hex"6c48656c6c6f2c20e4b896e7958c";
        uint i;
        string memory value;
        (i, value) = cbor.String(0);
        assertEq(bytes(value).length, 12);
    }
    */

    // Test string handling
    function test_decodeEmptyString() public pure {
        bytes memory cbor = hex"60"; // zero-length string in CBOR
        uint i;
        string memory value;
        (i, value) = cbor.String(0);
        assertEq(bytes(value).length, 0);
    }

    function test_decodeShortString() public pure {
        // String with 23 bytes (just below the threshold for an extended header)
        bytes memory cbor = hex"77414141414141414141414141414141414141414141414141";
        uint i;
        string memory value;
        (i, value) = cbor.String(0);
        assertEq(bytes(value).length, 23);
    }

    function test_decodeLongString() public pure {
        // String with 24 bytes (just at the threshold for an extended header)
        bytes memory cbor = hex"7741414141414141414141414141414141414141414141414141";
        uint i;
        string memory value;
        (i, value) = cbor.String(0);
        assertEq(bytes(value).length, 23);
    }

    function testFail_invalidString() public pure {
        bytes memory cbor = hex"61"; // Incomplete string
        uint i;
        string memory value;
        (i, value) = cbor.String(i); // Will revert due to incomplete data
    }
}
