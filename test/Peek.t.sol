// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract PeekTest is Test {
    bytes private constant unsignedCbor = hex"00";
    bytes private constant negativeCbor = hex"20";
    bytes private constant bytesCbor = hex"40";
    bytes private constant textCbor = hex"60";
    bytes private constant arrayCbor = hex"80";
    bytes private constant mapCbor = hex"a0";
    bytes private constant tagCbor = hex"c0";
    bytes private constant falseCbor = hex"f4";
    bytes private constant nullCbor = hex"f6";
    bytes private constant trueCbor = hex"f5";
    bytes private constant undefinedCbor = hex"f7";

    function test_isArray() public {
        bool result;

        vm.startSnapshotGas("isArray_false");
        result = mapCbor.isArray(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isArray_true");
        result = arrayCbor.isArray(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isBool() public {
        bool result;

        vm.startSnapshotGas("isBool_false_undefinedCbor");
        result = undefinedCbor.isBool(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isBool_true_falseCbor");
        result = falseCbor.isBool(0);
        vm.stopSnapshotGas();
        assert(result);

        vm.startSnapshotGas("isBool_true_trueCbor");
        result = trueCbor.isBool(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isBytes() public {
        bool result;

        vm.startSnapshotGas("isBytes_false");
        result = textCbor.isBytes(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isBytes_true");
        result = bytesCbor.isBytes(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isInt() public {
        bool result;

        vm.startSnapshotGas("isInt_false");
        result = nullCbor.isInt(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isInt_true_unsignedCbor");
        result = unsignedCbor.isInt(0);
        vm.stopSnapshotGas();
        assert(result);

        vm.startSnapshotGas("isInt_true_negativeCbor");
        result = negativeCbor.isInt(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isMap() public {
        bool result;

        vm.startSnapshotGas("isMap_false");
        result = arrayCbor.isMap(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isMap_true");
        result = mapCbor.isMap(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isNInt() public {
        bool result;

        vm.startSnapshotGas("isNInt_false");
        result = unsignedCbor.isNInt(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isNInt_true");
        result = negativeCbor.isNInt(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isNull() public {
        bool result;

        vm.startSnapshotGas("isNull_false");
        result = unsignedCbor.isNull(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isNull_true");
        result = nullCbor.isNull(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isString() public {
        bool result;

        vm.startSnapshotGas("isString_false");
        result = bytesCbor.isString(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isString_true");
        result = textCbor.isString(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isTag() public {
        bool result;

        vm.startSnapshotGas("isTag_false");
        result = arrayCbor.isTag(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isTag_true");
        result = tagCbor.isTag(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isTag_expect() public {
        bool result;

        vm.startSnapshotGas("isTag_expect_false");
        result = tagCbor.isTag(0, 1);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isTag_expect_true");
        result = tagCbor.isTag(0, 0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_fuzz_isTag_expect_rand_64(uint64 rand64) public pure {
        bytes memory cbor = bytes.concat(bytes1(MajorTag << shiftMajor | MinorExtendU64), bytes8(rand64));
        assert(cbor.isTag(0, uint64(rand64)));
    }

    function test_fuzz_isTag_expect_rand_32(uint32 rand32) public pure {
        bytes memory cbor = bytes.concat(bytes1(MajorTag << shiftMajor | MinorExtendU32), bytes4(rand32));
        assert(cbor.isTag(0, uint32(rand32)));
    }

    function test_fuzz_isTag_expect_rand_16(uint16 rand16) public pure {
        bytes memory cbor = bytes.concat(bytes1(MajorTag << shiftMajor | MinorExtendU16), bytes2(rand16));
        assert(cbor.isTag(0, uint16(rand16)));
    }

    function test_isUInt() public {
        bool result;

        vm.startSnapshotGas("isUInt_false");
        result = negativeCbor.isUInt(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isUInt_true");
        result = unsignedCbor.isUInt(0);
        vm.stopSnapshotGas();
        assert(result);
    }

    function test_isUndefined() public {
        bool result;

        vm.startSnapshotGas("isUndefined_false");
        result = unsignedCbor.isUndefined(0);
        vm.stopSnapshotGas();
        assert(!result);

        vm.startSnapshotGas("isUndefined_true");
        result = undefinedCbor.isUndefined(0);
        vm.stopSnapshotGas();
        assert(result);
    }
}
