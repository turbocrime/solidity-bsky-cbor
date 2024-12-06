// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract RangeTest is Test {
    function test_requireRange() public pure {
        bytes memory cbor = hex"0102";
        uint32 i = cbor.requireRange(1); // Should succeed
        assertEq(i, 1);

        i = cbor.requireRange(2); // Should succeed at end
        assertEq(i, 2);
    }

    function testFail_requireRange() public pure {
        bytes memory cbor = hex"0102";
        cbor.requireRange(3); // Should fail - beyond end
    }

    function test_requireComplete() public pure {
        bytes memory cbor = hex"0102";
        uint32 i = 2;
        cbor.requireComplete(i); // Should succeed - at end
    }

    function testFail_requireComplete() public pure {
        bytes memory cbor = hex"0102";
        uint32 i = 1;
        cbor.requireComplete(i); // Should fail - not at end
    }
}
