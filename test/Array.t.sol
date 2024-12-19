// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract ArrayTest is Test {
    function test_Array_empty() public {
        bytes memory cbor = hex"80"; // Empty array in CBOR
        uint i;
        uint32 len;

        vm.startSnapshotGas("Array_empty");
        (i, len) = cbor.Array(i);
        vm.stopSnapshotGas();

        assert(len == 0);
    }

    function test_Array_large() public {
        // Array with 23 elements (just below the threshold for extended header)
        bytes memory cbor = hex"97010101010101010101010101010101010101010101010101";
        uint i;
        uint32 len;

        vm.startSnapshotGas("Array_large");
        (i, len) = cbor.Array(i);
        vm.stopSnapshotGas();

        assert(len == 23);
    }

    function test_Array_nested() public {
        // [[1, 2], [3, 4]]
        bytes memory cbor = hex"82820102820304";
        uint i;
        uint outerLen;
        uint innerLen;
        uint8 value;

        vm.startSnapshotGas("Array_nested");

        (i, outerLen) = cbor.Array(0);
        assert(outerLen == 2);

        (i, innerLen) = cbor.Array(i);
        assert(innerLen == 2);

        (i, value) = cbor.UInt8(i);
        assert(value == 1);

        (i, value) = cbor.UInt8(i);
        assert(value == 2);

        (i, innerLen) = cbor.Array(i);
        assert(innerLen == 2);

        (i, value) = cbor.UInt8(i);
        assert(value == 3);

        (i, value) = cbor.UInt8(i);
        assert(value == 4);

        vm.stopSnapshotGas();
    }

    function test_Array_single() public {
        bytes memory cbor = hex"8118ff"; // [0xff]
        uint i;
        uint32 len;
        uint8 value;

        vm.startSnapshotGas("Array_single");

        (i, len) = cbor.Array(0);
        assert(len == 1);

        (i, value) = cbor.UInt8(i);
        assert(value == 0xff);

        vm.stopSnapshotGas();
    }

    function test_Array_mixed() public {
        // [1, "a", [2]]
        bytes memory cbor = hex"830161618102";
        uint i;
        uint32 len;
        uint8 value;
        string memory strValue;
        uint innerLen;

        vm.startSnapshotGas("Array_mixed");

        (i, len) = cbor.Array(i);
        assert(len == 3);

        (i, value) = cbor.UInt8(i);
        assert(value == 1);

        (i, strValue) = cbor.String(i);
        assert(bytes1(bytes(strValue)) == "a");

        (i, innerLen) = cbor.Array(i);
        assert(innerLen == 1);

        (i, value) = cbor.UInt8(i);
        assert(value == 2);

        vm.stopSnapshotGas();
    }
}
