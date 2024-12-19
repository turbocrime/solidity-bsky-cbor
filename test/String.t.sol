// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract StringTest is Test {
    function test_String_empty() public {
        bytes memory cbor = hex"60"; // zero-length string in CBOR
        uint i;
        string memory value;

        vm.startSnapshotGas("String_empty");
        (i, value) = cbor.String(0);
        vm.stopSnapshotGas();

        assert(bytes(value).length == 0);
    }

    function test_String_short() public {
        // String with 23 bytes (just below the threshold for an extended header)
        bytes memory cbor = hex"77414141414141414141414141414141414141414141414141";
        uint i;
        string memory value;

        vm.startSnapshotGas("String_short");
        (i, value) = cbor.String(0);
        vm.stopSnapshotGas();

        assert(bytes(value).length == 23);
    }

    function test_String_extended() public {
        // String with 24 bytes (just at the threshold for an extended header)
        bytes memory cbor = hex"7741414141414141414141414141414141414141414141414141";
        uint i;
        string memory value;

        vm.startSnapshotGas("String_extended");
        (i, value) = cbor.String(0);
        vm.stopSnapshotGas();

        assert(bytes(value).length == 23);
    }

    function test_String32() public {
        // 1 character "a"
        bytes memory cbor = hex"6161";
        uint i;
        bytes32 value;
        uint8 len;

        vm.startSnapshotGas("String32_short");
        (i, value, len) = cbor.String32(0);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
        assert(len == 1);
        assert(value == "a");
    }

    function testFail_String32_too_long() public pure {
        // 33 characters "thisisquitealongstringisuppose..."
        bytes memory cbor = hex"78217468697369737175697465616C6F6E67737472696E6769737570706F73652E2E2E";
        uint i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.String32(0);
        assert(len == 33);
        // missing the last character
        assert(value != bytes32("thisisquitealongstringisuppose.."));
    }

    function testFail_String32_parameter() public pure {
        bytes memory cbor = hex"6161";
        uint i;
        bytes32 value;
        uint8 len;
        (i, value, len) = cbor.String32(0, 33);
    }

    function test_skipString() public {
        bytes memory cbor = hex"6161";

        vm.startSnapshotGas("skipString");
        uint i = cbor.skipString(0);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
    }

    function testFail_skipString() public pure {
        bytes memory cbor = hex"50";
        uint i = cbor.skipString(0);
        assert(cbor[i] == cbor[i]);
    }

    function test_String1() public {
        bytes memory cbor = hex"6161";
        uint i;
        bytes1 value;

        vm.startSnapshotGas("String1");
        (i, value) = cbor.String1(0);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
        assert(value == bytes1("a"));
    }

    function testFail_String1_empty() public pure {
        bytes memory cbor = hex"60";
        uint i;
        bytes1 value;
        (i, value) = cbor.String1(0);
    }
}
