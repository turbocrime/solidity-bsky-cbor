// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract SimpleTest is Test {
    function test_Boolean() public {
        bytes memory cbor = hex"f4f5";
        uint i;
        bool value;

        vm.startSnapshotGas("Boolean_false");
        (i, value) = cbor.Bool(i);
        vm.stopSnapshotGas();
        assert(value == false);

        vm.startSnapshotGas("Boolean_true");
        (i, value) = cbor.Bool(i);
        vm.stopSnapshotGas();
        assert(value == true);

        assert(i == cbor.length);
    }

    function testFail_Boolean_invalid() public pure {
        bytes memory cbor = hex"f6";
        uint i;
        bool value;
        (i, value) = cbor.Bool(i);
    }

    function test_skipNull() public {
        bytes memory cbor = hex"f6";
        uint i;

        vm.startSnapshotGas("skipNull");
        (i) = cbor.Null(i);
        vm.stopSnapshotGas();
    }

    function testFail_skipNull() public pure {
        bytes memory cbor = hex"f7";
        uint i;
        (i) = cbor.Null(i);
    }

    function test_skipUndefined() public {
        bytes memory cbor = hex"f7";
        uint i;

        vm.startSnapshotGas("skipUndefined");
        (i) = cbor.Undefined(i);
        vm.stopSnapshotGas();
    }

    function testFail_skipUndefined() public pure {
        bytes memory cbor = hex"f6";
        uint i;
        (i) = cbor.Undefined(i);
    }
}
