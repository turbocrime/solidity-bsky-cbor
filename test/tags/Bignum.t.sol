// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/tags/ReadBignum.sol";
import "../../src/ReadCbor.sol";

function bytesHead(uint8 len) pure returns (bytes memory) {
    return len < MinorExtendU8
        ? abi.encodePacked(uint8(MajorBytes << shiftMajor | len))
        : abi.encodePacked(uint16(MajorBytes << shiftMajor | MinorExtendU8) << 8 | len);
}

function intHead(uint64 num) pure returns (bytes memory) {
    if (num <= uint8(type(uint8).max)) {
        return abi.encodePacked(uint8(MajorUnsigned << shiftMajor | num));
    } else if (num <= uint16(type(uint16).max)) {
        return abi.encodePacked(uint16(MajorUnsigned << shiftMajor | MinorExtendU8) << 8 | uint16(num));
    } else if (num <= uint32(type(uint32).max)) {
        return abi.encodePacked(uint32(MajorUnsigned << shiftMajor | MinorExtendU16) << 16 | uint32(num));
    } else {
        return abi.encodePacked(uint64(MajorUnsigned << shiftMajor | MinorExtendU32) << 32 | uint64(num));
    }
}

contract BignumTest is Test {
    using ReadCbor for bytes;
    using ReadBignum for bytes;

    bytes1 internal constant HeadUBn = hex"c2";
    bytes1 internal constant HeadNBn = hex"c3";

    function test_UInt256_single() public {
        bytes memory cbor = abi.encodePacked(HeadUBn, bytesHead(1), hex"ff");
        uint i;
        uint256 value;

        vm.startSnapshotGas("UInt256_single");
        (i, value) = cbor.UInt256(i);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
        assert(value == 0xFF);
    }

    function test_UInt256_multi() public {
        // 2(h'12345678')
        bytes memory cbor = hex"c24412345678";
        uint i;
        uint256 value;

        vm.startSnapshotGas("UInt256_multi");
        (i, value) = cbor.UInt256(i);
        vm.stopSnapshotGas();

        assert(i == cbor.length);
        assert(value == 0x12345678);
    }

    function test_UInt256_max() public {
        bytes memory cbor = abi.encodePacked(HeadUBn, bytesHead(32), type(uint256).max);
        uint i;
        uint256 value;

        vm.startSnapshotGas("UInt256_max");
        (i, value) = cbor.UInt256(i);
        vm.stopSnapshotGas();

        assert(value == type(uint256).max);
        assert(i == cbor.length);
    }

    function testFail_UInt256_large() public pure {
        // a 33-byte positive bigint is too large to be a uint256
        bytes memory cbor = abi.encodePacked(HeadUBn, bytesHead(32 + 1), type(uint256).max, hex"ff");
        uint i;
        uint256 value;

        (i, value) = cbor.UInt256(i);

        // unreachable
        assert(i == cbor.length);
    }

    function test_UInt256_middle() public {
        // [2(h'123456'), "foo"]
        bytes memory cbor = hex"82c24312345663666F6F";
        uint i;
        uint32 len;
        uint256 value;
        string memory foo;

        (i, len) = cbor.Array(i);

        vm.startSnapshotGas("UInt256_middle");
        (i, value) = cbor.UInt256(i);
        vm.stopSnapshotGas();

        assert(value == 0x123456);
        (i, foo) = cbor.String(i);
        assert(i == cbor.length);
        assert(bytes3(bytes(foo)) == "foo");
    }

    function test_NInt256_single() public {
        // 3(h'ff')
        bytes memory cbor = hex"c341ff";
        uint i;
        int256 value;

        vm.startSnapshotGas("NInt256_single");
        (i, value) = cbor.NInt256(i);
        vm.stopSnapshotGas();

        assert(value == -1 - 0xFF);
        assert(i == cbor.length);
    }

    function test_NInt256_multi() public {
        // 3(h'12345678')
        bytes memory cbor = hex"c34412345678";
        uint i;
        int256 value;

        vm.startSnapshotGas("NInt256_multi");
        (i, value) = cbor.NInt256(i);
        vm.stopSnapshotGas();

        assert(value == -1 - 0x12345678);
        assert(i == cbor.length);
    }

    function test_NInt256_max() public {
        bytes memory cbor = abi.encodePacked(HeadNBn, bytesHead(32), uint256(type(int256).min) - 1);
        uint i;
        int256 value;

        vm.startSnapshotGas("NInt256_max");
        (i, value) = cbor.NInt256(i);
        vm.stopSnapshotGas();

        assert(value == type(int256).min);
        assert(i == cbor.length);
    }

    function testFail_NInt256_overflow() public {
        // Invalid: one more than the 'maximum' negative number that can be represented as an int256
        bytes memory cbor = abi.encodePacked(HeadNBn, bytesHead(32), uint256(type(int256).min));
        uint i;
        int256 value;

        vm.startSnapshotGas("NInt256_overflow");
        (i, value) = cbor.NInt256(i);
        vm.stopSnapshotGas();

        // unreachable
        assert(i == cbor.length);
    }

    function testFail_NInt256_max() public pure {
        // Invalid: maximum uint256 value as negative bignum
        // 3(h'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff')
        bytes memory cbor = abi.encodePacked(HeadNBn, bytesHead(32), bytes32(type(uint256).max));
        uint i;
        int256 value;

        (i, value) = cbor.NInt256(i);

        // unreachable
        assert(i == cbor.length);
    }

    function testFail_NInt256_large() public pure {
        // Invalid: 33-byte negative bignum is too large for int256
        bytes memory cbor = abi.encodePacked(HeadNBn, bytesHead(32 + 1), bytes32(type(uint256).max), hex"ff");
        uint i;
        int256 value;

        (i, value) = cbor.NInt256(i);

        // unreachable
        assert(i == cbor.length);
    }

    function test_NInt256_middle() public {
        // [3(h'123456'), "foo"]
        bytes memory cbor = hex"82c34312345663666F6F";
        uint i;
        uint32 len;
        int256 value;
        string memory foo;

        vm.startSnapshotGas("NInt256_middle");
        (i, len) = cbor.Array(i);
        vm.stopSnapshotGas();

        (i, value) = cbor.NInt256(i);
        assert(value == -1 - 0x123456);
        (i, foo) = cbor.String(i);
        assert(i == cbor.length);
        assert(bytes3(bytes(foo)) == "foo");
    }

    function test_fuzz_UInt256_random(uint256 randU) public pure {
        bytes memory cbor = abi.encodePacked(HeadUBn, bytesHead(32), randU);
        uint i;
        uint256 value;

        (i, value) = cbor.UInt256(i);
        assert(value == randU);
        assert(i == cbor.length);
    }

    function test_fuzz_NInt256_random(int256 randN) public pure {
        vm.assume(randN < 0);
        vm.assume(randN != type(int256).min);

        bytes memory cbor = abi.encodePacked(HeadNBn, bytesHead(32), (randN < 0 ? -randN : randN) - 1);
        uint i;
        int256 value;

        (i, value) = cbor.NInt256(i);
        assert(value == randN);
        assert(i == cbor.length);
    }

    function test_Integer() public {
        bytes memory cbor =
            hex"8C08387E18FF397FFE19FFFF3A7FFFFFFE1AFFFFFFFF3B7FFFFFFFFFFFFFFE1BFFFFFFFFFFFFFFFFC3507FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC250FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC358207FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
        uint j;
        int256 value;
        uint32 len;

        vm.startSnapshotGas("Integer");
        (j, len) = cbor.Array(j);
        vm.stopSnapshotGas();

        for (uint8 i = 0; i < len; i++) {
            (j, value) = cbor.Integer(j);
        }
        assert(j == cbor.length);
    }

    function testFail_Integer_UInt256_max() public pure {
        bytes memory cbor = abi.encodePacked(HeadUBn, bytesHead(32), type(uint256).max);
        uint i;
        int256 value;

        (i, value) = cbor.Integer(i);
        assert(uint256(value) == type(uint256).max);
        assert(i == cbor.length);
    }

    function testFail_Int256_notbignum() public pure {
        bytes memory cbor = hex"c4";
        uint i;
        int256 value;
        (i, value) = cbor.Int256(i);
    }
}
