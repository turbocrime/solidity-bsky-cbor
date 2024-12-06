// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract TagTest is Test {
    function test_decodeTag() public pure {
        bytes memory cbor = hex"c0"; // Tag(0)
        uint32 i;
        uint64 tag;
        (i, tag) = cbor.Tag(i);
        cbor.requireComplete(i);
        assertEq(tag, 0);
    }

    function test_decodeExpectedTag() public pure {
        bytes memory cbor = hex"c0"; // Tag(0)
        uint32 i;
        i = cbor.Tag(i, 0);
        cbor.requireComplete(i);
    }

    function testFail_unexpectedTag() public pure {
        bytes memory cbor = hex"c0"; // Tag(0)
        uint32 i;
        cbor.Tag(i, 1);
    }

    function testFail_notTag() public pure {
        bytes memory cbor = hex"df"; // Not a tag
        uint32 i;
        cbor.Tag(i);
    }
}
