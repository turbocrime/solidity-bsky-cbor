/**
 *
 *   (c) 2023 Zondax AG
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
//
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";

/// @author Zondax AG
/// @author turbocrime
contract CborDecodeTest is Test {
    using CborDecode for bytes;

    function test_decodeFixedArray() public pure {
        bytes memory input = hex"8F0102030405060708090A64746573744401010101F4F6F5";
        uint index = 0;
        uint arrayLen = 0;
        uint8 num;
        string memory str = "";

        (arrayLen, index) = input.readFixedArray(index);
        require(arrayLen == 15, "array len is not 15");

        (num, index) = input.readUInt8(index);
        require(num == 1, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 2, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 3, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 4, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 5, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 6, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 7, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 8, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 9, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 10, "num is not 1");

        (str, index) = input.readString(index);
        require(keccak256(abi.encodePacked(str)) == keccak256(abi.encodePacked("test")), "str is not 'test'");
    }

    function test_decodeFalse() public pure {
        bytes memory input = hex"f4";
        uint index = 0;
        bool value;

        (value, index) = input.readBool(0);
        require(value == false, "value is not false");
    }

    function test_decodeTrue() public pure {
        bytes memory input = hex"f5";
        uint index = 0;
        bool value;

        (value, index) = input.readBool(0);
        require(value == true, "value is not true");
    }

    function test_decodeNull() public pure {
        bytes memory input = hex"f6";
        bool value;

        value = input.isNullNext(0);
        require(value == true, "input is not null cbor");
    }

    function test_decodeInteger() public pure {
        bytes memory input = hex"01";
        uint index = 0;
        uint8 value;

        (value, index) = input.readUInt8(0);
        require(value == 1, "value is not 1");
    }

    function test_decodeString() public pure {
        bytes memory input = hex"6a746573742076616c7565";
        uint index = 0;
        string memory value;
        string memory expected = "test value";

        (value, index) = input.readString(0);
        require(keccak256(bytes(value)) == keccak256(bytes(expected)), "value is not 'test value'");
    }

    function test_decodeStringWithWeirdChar() public pure {
        bytes memory input = hex"647A6FC3A9";
        uint index = 0;
        string memory value;

        (value, index) = input.readString(0);
        // Does solidity support this ?
        require(keccak256(bytes(value)) == keccak256(bytes(unicode"zoé")), unicode"value is not 'zoé'");
    }

    function test_decodeArrayU8() public pure {
        bytes memory input = hex"8501182b184218ea186f";

        uint index = 0;
        uint arrayLen = 0;
        uint8 num;

        console.log("reading fixed array");
        (arrayLen, index) = input.readFixedArray(index);
        console.log("arrayLen", arrayLen);
        require(arrayLen == 5, "array len is not 5");

        (num, index) = input.readUInt8(index);
        require(num == 1, "num is not 1");

        (num, index) = input.readUInt8(index);
        require(num == 43, "num is not 43");

        (num, index) = input.readUInt8(index);
        require(num == 66, "num is not 66");

        (num, index) = input.readUInt8(index);
        require(num == 234, "num is not 234");

        (num, index) = input.readUInt8(index);
        require(num == 111, "num is not 111");
    }

    function test_decodeFixedMap() public pure {
        bytes memory input = hex"A3616101616202616303";

        uint index = 0;
        uint mapLen = 0;
        (mapLen, index) = input.readFixedMap(index);
        require(mapLen == 3, "map len is not 2");

        bytes1 mapKey;
        uint8 mapValue;
        (mapKey, index) = input.readStringBytes1(index);
        require(mapKey == "a", "map key is not 'a'");

        (mapValue, index) = input.readUInt8(index);
        require(mapValue == 1, "map value is not 1");

        (mapKey, index) = input.readStringBytes1(index);
        require(mapKey == "b", "map key is not 'b'");

        (mapValue, index) = input.readUInt8(index);
        require(mapValue == 2, "map value is not 2");

        (mapKey, index) = input.readStringBytes1(index);
        require(mapKey == "c", "map key is not 'c'");

        (mapValue, index) = input.readUInt8(index);
        require(mapValue == 3, "map value is not 3");
    }
}
