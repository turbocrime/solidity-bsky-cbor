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
// THIS CODE WAS SECURITY REVIEWED BY KUDELSKI SECURITY, BUT NOT FORMALLY AUDITED

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ReadCbor} from "../../src/ReadCbor.sol";

/// @notice This file is meant to serve as a deployable contract to test the cbor decode library
/// @author Zondax AG
contract ComparisonTest is Test {
    using ReadCbor for bytes;

    function test_decodeFixedArray_ReadCbor() public pure {
        // [1,2,3,4,5,6,7,8,9,10,"test", h'01010101', false, null, true]
        bytes memory input = hex"8F0102030405060708090A64746573744401010101F4F6F5";
        uint32 index = 0;
        uint32 arrayLen = 0;
        uint8 num;
        string memory str = "";

        (index, arrayLen) = input.Array(index);
        require(arrayLen == 15, "array len is not 15");

        (index, num) = input.UInt8(index);
        require(num == 1, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 2, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 3, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 4, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 5, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 6, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 7, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 8, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 9, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 10, "num is not 1");

        (index, str) = input.String(index);
        require(keccak256(abi.encodePacked(str)) == keccak256(abi.encodePacked("test")), "str is not 'test'");
    }

    function test_decodeFalse_ReadCbor() public pure {
        bytes memory input = hex"f4";
        uint32 index = 0;
        bool value;

        (index, value) = input.Bool(index);
        require(value == false, "value is not false");
    }

    function test_decodeTrue_ReadCbor() public pure {
        bytes memory input = hex"f5";
        uint32 index = 0;
        bool value;

        (index, value) = input.Bool(index);
        require(value == true, "value is not true");
    }

    function test_decodeNull_ReadCbor() public pure {
        bytes memory input = hex"f6";
        bool value;

        value = input.isNull(0);
        require(value == true, "input is not null cbor");
    }

    function test_decodeInteger_ReadCbor() public pure {
        bytes memory input = hex"01";
        uint32 index = 0;
        uint8 value;

        (index, value) = input.UInt8(index);
        require(value == 1, "value is not 1");
    }

    function test_decodeString_ReadCbor() public pure {
        bytes memory input = hex"6a746573742076616c7565";
        uint32 index = 0;
        string memory value;
        string memory expected = "test value";

        (index, value) = input.String(index);
        require(keccak256(bytes(value)) == keccak256(bytes(expected)), "value is not 'test value'");
    }

    function test_decodeStringWithWeirdChar_ReadCbor() public pure {
        bytes memory input = hex"647A6FC3A9";
        uint32 index = 0;
        string memory value;

        (index, value) = input.String(index);
        // Does solidity support this ?
        require(keccak256(bytes(value)) == keccak256(bytes(unicode"zoé")), unicode"value is not 'zoé'");
    }

    function test_decodeArrayU8_ReadCbor() public pure {
        bytes memory input = hex"8501182b184218ea186f";

        uint32 index = 0;
        uint32 arrayLen = 0;
        uint8 num;

        (index, arrayLen) = input.Array(index);
        require(arrayLen == 5, "array len is not 5");

        (index, num) = input.UInt8(index);
        require(num == 1, "num is not 1");

        (index, num) = input.UInt8(index);
        require(num == 43, "num is not 43");

        (index, num) = input.UInt8(index);
        require(num == 66, "num is not 66");

        (index, num) = input.UInt8(index);
        require(num == 234, "num is not 234");

        (index, num) = input.UInt8(index);
        require(num == 111, "num is not 111");
    }
}
