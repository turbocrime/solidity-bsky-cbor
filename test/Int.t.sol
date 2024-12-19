// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {console, Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract IntTest is Test {
    // Test generic Int method
    function test_Int() public {
        bytes memory cborUInt_Zero = hex"00";
        bytes memory cborNInt_NegOne = hex"20";
        uint i;
        int value;

        vm.startSnapshotGas("Int_zero");
        (i, value) = cborUInt_Zero.Int(0);
        vm.stopSnapshotGas();
        assert(value == 0);

        vm.startSnapshotGas("Int_neg_one");
        (i, value) = cborNInt_NegOne.Int(0);
        vm.stopSnapshotGas();
        assert(value == -1);
    }

    function test_Int_uint16() public {
        bytes memory cbor = hex"19FFFF";
        uint i;
        int value;

        vm.startSnapshotGas("Int_uint16");
        (i, value) = cbor.Int(0);
        vm.stopSnapshotGas();
        assert(value == 0xFFFF);
    }

    function test_Int_nint16() public {
        bytes memory cbor = hex"39FFFF";
        uint i;
        int value;

        vm.startSnapshotGas("Int_nint16");
        (i, value) = cbor.Int(0);
        vm.stopSnapshotGas();

        assert(value == -1 - 0xFFFF);
    }

    function test_Int_max() public {
        bytes memory cbor = hex"1bffffffffffffffff";
        uint i;
        int value;

        vm.startSnapshotGas("Int_max");
        (i, value) = cbor.Int(0);
        vm.stopSnapshotGas();

        assert(value == 0xFFFF_FFFF_FFFF_FFFF);
    }

    function test_Int_min() public {
        bytes memory cbor = hex"3bFFFFFFFFFFFFFFFF";
        uint i;
        int value;

        vm.startSnapshotGas("Int_min");
        (i, value) = cbor.Int(0);
        vm.stopSnapshotGas();

        assert(value == -1 - 0xFFFF_FFFF_FFFF_FFFF);
    }

    function testFail_Int_not() public {
        bytes memory cbor = hex"f7";
        uint i;
        int value;

        vm.startSnapshotGas("Int_not");
        (i, value) = cbor.Int(0);
        vm.stopSnapshotGas();
    }
}
