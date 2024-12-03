// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../../src/CborRead.sol";

using CborRead for bytes;

/// @author Zondax AG
/// @author turbocrime
contract CborReadDecodeTest is Test {
    function test_decodeFixedArray() public pure {
        bytes memory cbor = hex"8F0102030405060708090A64746573744401010101F4F6F5";
        uint i;
        uint arrayLen;
        uint8 num;
        string memory str;

        (i, arrayLen) = cbor.Array(i);
        require(arrayLen == 15, "array len is not 15");

        (i, num) = cbor.UInt8(i);
        require(num == 1, "num is not 1");

        (i, num) = cbor.UInt8(i);
        require(num == 2, "num is not 2");

        (i, num) = cbor.UInt8(i);
        require(num == 3, "num is not 3");

        (i, num) = cbor.UInt8(i);
        require(num == 4, "num is not 4");

        (i, num) = cbor.UInt8(i);
        require(num == 5, "num is not 5");

        (i, num) = cbor.UInt8(i);
        require(num == 6, "num is not 6");

        (i, num) = cbor.UInt8(i);
        require(num == 7, "num is not 7");

        (i, num) = cbor.UInt8(i);
        require(num == 8, "num is not 8");

        (i, num) = cbor.UInt8(i);
        require(num == 9, "num is not 9");

        (i, num) = cbor.UInt8(i);
        require(num == 10, "num is not 10");

        (i, str) = cbor.String(i);
        require(keccak256(abi.encodePacked(str)) == keccak256(abi.encodePacked("test")), "str is not 'test'");
    }

    function test_decodeFalse() public pure {
        bytes memory cbor = hex"f4";
        uint i;
        bool value;
        (i, value) = cbor.Bool(i);
        require(value == false, "value is not false");
    }

    function test_decodeTrue() public pure {
        bytes memory cbor = hex"f5";
        uint i;
        bool value;
        (i, value) = cbor.Bool(i);
        require(value == true, "value is not true");
    }

    function test_decodeNull() public pure {
        bytes memory cbor = hex"f6";
        uint i;
        require(cbor.isNull(i), "input is not null cbor");
    }

    function test_decodeInteger() public pure {
        bytes memory cbor = hex"01";
        uint i;
        uint8 value;
        (i, value) = cbor.UInt8(i);
        require(value == 1, "value is not 1");
    }

    function test_decodeString() public pure {
        bytes memory cbor = hex"6a746573742076616c7565";
        string memory expected = "test value";
        uint i;
        string memory value;

        (i, value) = cbor.String(i);
        require(keccak256(bytes(value)) == keccak256(bytes(expected)), "value is not 'test value'");
    }

    function test_decodeStringWithWeirdChar() public pure {
        bytes memory cbor = hex"647A6FC3A9";
        uint i;
        string memory value;

        (i, value) = cbor.String(i);
        require(keccak256(bytes(value)) == keccak256(bytes(unicode"zoé")), unicode"value is not 'zoé'");
    }

    function test_decodeArrayU8() public pure {
        bytes memory cbor = hex"8501182b184218ea186f";
        uint i;
        uint64 arrayLen;
        uint8 num;

        (i, arrayLen) = cbor.Array(i);
        require(arrayLen == 5, "array len is not 5");

        (i, num) = cbor.UInt8(i);
        require(num == 1, "num is not 1");

        (i, num) = cbor.UInt8(i);
        require(num == 43, "num is not 43");

        (i, num) = cbor.UInt8(i);
        require(num == 66, "num is not 66");

        (i, num) = cbor.UInt8(i);
        require(num == 234, "num is not 234");

        (i, num) = cbor.UInt8(i);
        require(num == 111, "num is not 111");
    }

    function test_decodeFixedMap() public pure {
        bytes memory cbor = hex"A3616101616202616303";
        uint i;
        uint64 mapLen;
        bytes1 mapKey;
        uint8 mapValue;

        (i, mapLen) = cbor.Map(i);
        require(mapLen == 3, "map len is not 3");

        bytes32 mapKeyBytes;
        uint8 mapKeyLen;
        (i, mapKeyBytes, mapKeyLen) = cbor.String32(i, 1);
        mapKey = bytes1(mapKeyBytes);
        require(mapKey == "a", "map key is not 'a'");

        (i, mapValue) = cbor.UInt8(i);
        require(mapValue == 1, "map value is not 1");

        (i, mapKeyBytes, mapKeyLen) = cbor.String32(i, 1);
        mapKey = bytes1(mapKeyBytes);
        require(mapKey == "b", "map key is not 'b'");

        (i, mapValue) = cbor.UInt8(i);
        require(mapValue == 2, "map value is not 2");

        (i, mapKeyBytes, mapKeyLen) = cbor.String32(i, 1);
        mapKey = bytes1(mapKeyBytes);
        require(mapKey == "c", "map key is not 'c'");

        (i, mapValue) = cbor.UInt8(i);
        require(mapValue == 3, "map value is not 3");
    }
}
