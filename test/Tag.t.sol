// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract TagTest is Test {
    function test_Tag() public pure {
        bytes memory cbor = hex"c0"; // Tag(0)
        uint i;
        uint64 tag;
        (i, tag) = cbor.Tag(i);
        assert(i == cbor.length);
        assert(tag == 0);
    }

    function test_Tag_expected() public pure {
        bytes memory cbor = hex"c0"; // Tag(0)
        uint i;
        i = cbor.Tag(i, 0);
        assert(i == cbor.length);
    }

    function testFail_Tag_unexpected() public pure {
        bytes memory cbor = hex"c0"; // Tag(0)
        uint i;
        cbor.Tag(i, 1);
    }

    function testFail_Tag_invalid() public pure {
        bytes memory cbor = hex"df"; // Not a tag
        uint i;
        cbor.Tag(i);
    }
}
