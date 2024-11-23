/**
 *
 *   (c) 2022 Zondax AG
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
// THIS CODE WAS SECURITY REVIEWED BY KUDELSKI SECURITY, BUT NOT FORMALLY AUDITED

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

uint8 constant shiftMajor = 5;
uint8 constant maskMinor = 0x1f;

uint8 constant MajorUnsigned = 0;
uint8 constant MajorNegative = 1;
uint8 constant MajorBytes = 2;
uint8 constant MajorText = 3;
uint8 constant MajorArray = 4;
uint8 constant MajorMap = 5;
uint8 constant MajorTag = 6;
uint8 constant MajorPrimitive = 7;

uint8 constant MinorExtend1 = 24;
uint8 constant MinorExtend2 = 25;
uint8 constant MinorExtend4 = 26;
uint8 constant MinorExtend8 = 27;

uint8 constant MinorFalse = 0x14;
uint8 constant MinorTrue = 0x15;
uint8 constant MinorNull = 0x16;
uint8 constant MinorUndefined = 0x17;

/// @notice This library is a set a functions that allows anyone to decode cbor encoded bytes
/// @dev methods in this library try to read the data type indicated from cbor encoded data stored in bytes at a specific index
/// @dev if it successes, methods will return the read value and the new index (intial index plus read bytes)
/// @author Zondax AG
library CBORDecoder {
    function isNullNext(bytes memory cborData, uint byteIdx) internal pure returns (bool) {
        return uint8(cborData[byteIdx]) == MajorPrimitive << shiftMajor | MinorNull;
    }

    function readBool(bytes memory cborData, uint byteIdx) internal pure returns (bool, uint) {
        uint8 simpleValue = uint8(cborData[byteIdx]);
        uint8 simpleTrue = MajorPrimitive << shiftMajor | MinorTrue;
        uint8 simpleFalse = MajorPrimitive << shiftMajor | MinorFalse;
        require(simpleValue == simpleTrue || simpleValue == simpleFalse, "expected a simple boolean value");
        return (simpleValue == simpleTrue, byteIdx + 1);
    }

    function readFixedArray(bytes memory cborData, uint byteIdx) internal pure returns (uint64 len, uint) {
        uint8 major;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorArray, "expected an array");

        return (len, byteIdx);
    }

    function readFixedMap(bytes memory cborData, uint byteIdx) internal pure returns (uint64 len, uint) {
        uint8 major;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorMap, "expected a map");

        return (len, byteIdx);
    }

    function readString(bytes memory cborData, uint byteIdx) internal pure returns (string memory, uint) {
        uint8 major;
        uint64 len;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorText, "expected text");

        bytes memory slice = new bytes(len);
        uint slice_index = 0;
        for (uint256 i = byteIdx; i < byteIdx + len; i++) {
            slice[slice_index] = cborData[i];
            slice_index++;
        }

        return (string(slice), byteIdx + len);
    }

    function readStringBytes(bytes memory cborData, uint byteIdx) internal pure returns (bytes memory, uint) {
        uint8 major;
        uint64 len;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorText, "invalid major (expected MajorText)");

        bytes memory slice = new bytes(len);
        uint slice_index = 0;
        for (uint256 i = byteIdx; i < byteIdx + len; i++) {
            slice[slice_index] = cborData[i];
            slice_index++;
        }

        return (slice, byteIdx + len);
    }

    function readStringBytes9(bytes memory cborData, uint byteIdx) internal pure returns (bytes9, uint) {
        uint8 major;
        uint64 len;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorText && len <= 9, "expected string length of 9 or less");

        bytes9 slice;
        assembly {
            slice := and(mload(add(cborData, add(0x20, byteIdx))), not(shr(mul(len, 8), not(0))))
        }

        return (slice, byteIdx + len);
    }

    function readStringBytes7(bytes memory cborData, uint byteIdx) internal pure returns (bytes7, uint) {
        uint8 major;
        uint64 len;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorText && len <= 7, "expected string length of 7 or less");

        bytes7 slice;
        assembly {
            slice := and(mload(add(cborData, add(0x20, byteIdx))), not(shr(mul(len, 8), not(0))))
        }

        return (slice, byteIdx + len);
    }

    function readStringBytes1_normal(bytes memory cborData, uint byteIdx) internal pure returns (bytes1, uint) {
        uint8 major;
        uint64 len;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorText, "invalid major (expected MajorText)");
        require(len == 1, "expected string length of 1");

        return (cborData[byteIdx], byteIdx + len);
    }

    function readStringBytes1(bytes memory cborData, uint byteIdx) internal pure returns (bytes1, uint) {
        return readStringBytes1_normal(cborData, byteIdx);
    }

    function readStringBytes1_assembly(bytes memory cborData, uint byteIdx) internal pure returns (bytes1, uint) {
        uint8 head;
        assembly {
            head := mload(add(cborData, add(0x20, byteIdx)))
        }
        require(head == MajorText << shiftMajor | 0x01, "expected string length of 1");
        bytes1 slice;
        byteIdx += 1;
        assembly {
            slice := mload(add(cborData, add(0x20, byteIdx)))
        }
        return (slice, byteIdx + 2);
    }

    function skipString(bytes memory cborData, uint byteIdx) internal pure returns (uint) {
        uint8 major;
        uint64 len;
        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorText, "invalid major (expected MajorText)");
        return byteIdx + len;
    }

    function readBytes(bytes memory cborData, uint byteIdx) internal pure returns (bytes memory, uint) {
        uint8 major;
        uint64 len;

        (major, len, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorBytes, "invalid major (expected MajorBytes)");

        bytes memory slice = new bytes(len);
        uint slice_index = 0;
        for (uint256 i = byteIdx; i < byteIdx + len; i++) {
            slice[slice_index] = cborData[i];
            slice_index++;
        }

        return (slice, byteIdx + len);
    }

    function readUInt64(bytes memory cborData, uint byteIdx) internal pure returns (uint64, uint) {
        uint8 major;
        uint64 value;

        (major, value, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorUnsigned, "invalid major (expected MajorUnsigned)");

        return (value, byteIdx);
    }

    function readUInt32(bytes memory cborData, uint byteIdx) internal pure returns (uint32, uint) {
        uint8 major;
        uint64 value;

        (major, value, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorUnsigned, "invalid major (expected MajorUnsigned)");

        return (uint32(value), byteIdx);
    }

    function readUInt16(bytes memory cborData, uint byteIdx) internal pure returns (uint16, uint) {
        uint8 major;
        uint64 value;

        (major, value, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorUnsigned, "invalid major (expected MajorUnsigned)");

        return (uint16(value), byteIdx);
    }

    function readUInt8(bytes memory cborData, uint byteIdx) internal pure returns (uint8, uint) {
        uint8 major;
        uint64 value;

        (major, value, byteIdx) = parseCborHeader(cborData, byteIdx);
        require(major == MajorUnsigned, "invalid major (expected MajorUnsigned)");

        return (uint8(value), byteIdx);
    }

    function slice1(bytes memory bs, uint start) internal pure returns (uint8) {
        require(bs.length >= start + 1, "slicing out of range");
        return uint8(bs[start]);
    }

    function slice2(bytes memory bs, uint start) internal pure returns (uint16) {
        require(bs.length >= start + 2, "slicing out of range");
        uint16 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    function slice4(bytes memory bs, uint start) internal pure returns (uint32) {
        require(bs.length >= start + 4, "slicing out of range");
        uint32 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    function slice8(bytes memory bs, uint start) internal pure returns (uint64) {
        require(bs.length >= start + 8, "slicing out of range");
        uint64 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    function parseCborHeader(bytes memory cbor, uint byteIndex) internal pure returns (uint8 major, uint64 arg, uint) {
        uint8 head = uint8(cbor[byteIndex]);
        byteIndex += 1;
        major = head >> 5;
        uint8 minor = head & 0x1f;

        // minor literal
        if (minor < MinorExtend1) {
            arg = uint8(minor);
        } else {
            // extended header
            if (minor == MinorExtend1) {
                arg = slice1(cbor, byteIndex);
                byteIndex += 1;
            } else if (minor == MinorExtend2) {
                arg = slice2(cbor, byteIndex);
                byteIndex += 2;
            } else if (minor == MinorExtend4) {
                arg = slice4(cbor, byteIndex);
                byteIndex += 4;
            } else if (minor == MinorExtend8) {
                arg = slice8(cbor, byteIndex);
                byteIndex += 8;
            } else {
                revert("unsupported header minor >27. (no indefinite sequences)");
            }

            require(
                // floats (major primitive) are an exception to this rule
                arg >= 24 || major == MajorPrimitive,
                "an extended header must not contain a value that would fit inside a normal header"
            );
        }
        return (major, arg, byteIndex);
    }
}
