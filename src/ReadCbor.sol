// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

uint8 constant maskMinor = 0x1f; // 0b0001_1111;
uint8 constant shiftMajor = 5;

uint8 constant MajorUnsigned = 0;
uint8 constant MajorNegative = 1;
uint8 constant MajorBytes = 2;
uint8 constant MajorText = 3;
uint8 constant MajorArray = 4;
uint8 constant MajorMap = 5;
uint8 constant MajorTag = 6;
uint8 constant MajorPrimitive = 7;

library ReadCbor {
    bool private constant ArgSizeByte = true;
    bool private constant ArgSizeExt = false;

    uint8 private constant SimpleFalse = (MajorPrimitive << shiftMajor) | 0x14;
    uint8 private constant SimpleTrue = (MajorPrimitive << shiftMajor) | 0x15;
    uint8 private constant SimpleNull = (MajorPrimitive << shiftMajor) | 0x16;
    uint8 private constant SimpleUndefined = (MajorPrimitive << shiftMajor) | 0x17;

    uint8 private constant MinorExtendU8 = 0x17 + 1; // 24
    uint8 private constant MinorExtendU16 = 0x17 + 2; // 25
    uint8 private constant MinorExtendU32 = 0x17 + 3; // 26
    uint8 private constant MinorExtendU64 = 0x17 + 4; // 27

    function requireRange(bytes memory cbor, uint i, uint64 advance) internal pure returns (uint ret) {
        ret = i + advance;
        require(ret <= cbor.length, "index advance out of range");
        return ret;
    }

    function requireComplete(bytes memory cbor, uint i) internal pure {
        require(i == cbor.length, "expected to read all bytes");
    }

    function mm(bytes memory cbor, uint i) private pure returns (uint, uint8 major, uint8 minor) {
        uint8 b = uint8(cbor[i]);
        return (i + 1, b >> shiftMajor, b & maskMinor);
    }

    function u16(bytes memory cbor, uint i) private pure returns (uint, uint16) {
        bytes2 value;
        assembly ("memory-safe") {
            value := mload(add(cbor, add(0x20, i)))
        }
        return (i + 2, uint16(value));
    }

    function u32(bytes memory cbor, uint i) private pure returns (uint, uint32) {
        bytes4 value;
        assembly ("memory-safe") {
            value := mload(add(cbor, add(0x20, i)))
        }
        return (i + 4, uint32(value));
    }

    function u64(bytes memory cbor, uint i) private pure returns (uint, uint64) {
        bytes8 value;
        assembly ("memory-safe") {
            value := mload(add(cbor, add(0x20, i)))
        }
        return (i + 8, uint64(value));
    }

    function headerExpect(bytes memory cbor, uint i, uint8 expectMajor) private pure returns (uint, uint64 arg) {
        uint8 major;
        uint8 minor;
        (i, major, minor) = mm(cbor, i);
        require(major == expectMajor, "unexpected major type");
        return parseArg(cbor, i, minor);
    }

    function headerExpect(bytes memory cbor, uint i, uint8 expectMajor, bool argSize)
        private
        pure
        returns (uint, uint64)
    {
        uint8 major;
        uint8 minor;
        (i, major, minor) = mm(cbor, i);
        require(major == expectMajor, "unexpected major type");
        if (argSize) {
            require(minor <= MinorExtendU8, "expected single-byte arg");
        } else {
            require(minor >= MinorExtendU16 && minor <= MinorExtendU64, "expected multi-byte arg");
        }
        return parseArg(cbor, i, minor);
    }

    function headerExpect(bytes memory cbor, uint i, uint8 expectMajor, uint8 expectMinor)
        private
        pure
        returns (uint, uint64)
    {
        uint8 major;
        uint8 minor;
        (i, major, minor) = mm(cbor, i);
        require(major == expectMajor, "unexpected major type");
        require(minor == expectMinor, "unexpected minor type");
        return parseArg(cbor, i, minor);
    }

    function header(bytes memory cbor, uint i) private pure returns (uint, uint64 arg, uint8 major) {
        uint8 minor;
        (i, major, minor) = mm(cbor, i);
        (i, arg) = parseArg(cbor, i, minor);
        return (i, arg, major);
    }

    function parseArg(bytes memory cbor, uint i, uint8 minor) private pure returns (uint, uint64 arg) {
        assert(minor < 32);
        if (minor < MinorExtendU8) {
            return (i, minor);
        } else {
            if (minor == MinorExtendU8) {
                arg = uint8(cbor[i]);
                require(arg >= MinorExtendU8, "invalid type argument (single-byte value too low)");
                return (i + 1, arg);
            } else if (minor == MinorExtendU16) {
                return u16(cbor, i);
            } else if (minor == MinorExtendU32) {
                return u32(cbor, i);
            } else if (minor == MinorExtendU64) {
                return u64(cbor, i);
            }
        }
        //require(minor != MinorIndefinite, "unsupported minor type (item length indefinite)");
        revert("minor type unsupported");
    }

    function wordOfType(bytes memory cbor, uint i, uint8 expectMajor, uint8 maxLen)
        private
        pure
        returns (uint, bytes32 ret, uint8 len)
    {
        require(maxLen <= 32, "maxLen out of range (32-bit word)");
        uint8 major;
        uint8 minor;
        (i, major, minor) = mm(cbor, i);
        require(major == expectMajor, "unexpected major type");

        if (minor < MinorExtendU8) {
            len = minor;
        } else {
            require(minor == MinorExtendU8, "excessive length");
            (i, len) = (i + 1, uint8(cbor[i]));
        }
        require(len <= maxLen, "item exceeds max length");

        assembly {
            ret := mload(add(cbor, add(0x20, i)))
        }

        return (requireRange(cbor, i, len), ret, len);
    }

    // ---- read primitive/simple ----

    function isNull(bytes memory cbor, uint i) internal pure returns (bool) {
        return uint8(cbor[i]) == SimpleNull;
    }

    function isUndefined(bytes memory cbor, uint i) internal pure returns (bool) {
        return uint8(cbor[i]) == SimpleUndefined;
    }

    function Bool(bytes memory cbor, uint i) internal pure returns (uint, bool) {
        uint8 h = uint8(cbor[i]);
        require(h == SimpleTrue || h == SimpleFalse, "expected boolean");
        return (i + 1, h == SimpleTrue);
    }

    // ---- read array size ----

    // An array of data items. The argument is the number of data items in the
    // array. Items in an array do not need to all be of the same type.
    function Array(bytes memory cbor, uint i) internal pure returns (uint, uint64 len) {
        return headerExpect(cbor, i, MajorArray);
    }

    // ---- read map size ----

    // A map is comprised of pairs of data items, each pair consisting of a key
    // that is immediately followed by a value. The argument is the number of
    // pairs of data items in the map.
    function Map(bytes memory cbor, uint i) internal pure returns (uint, uint64 len) {
        return headerExpect(cbor, i, MajorMap);
    }

    // ---- read string ----

    function String(bytes memory cbor, uint i) internal pure returns (uint, string memory ret) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorText);

        bytes memory bor = cbor;
        uint s = i;

        ret = new string(len);

        require(i + len <= bor.length, "slice out of bounds");
        assembly ("memory-safe") {
            for { let j := 0 } lt(j, len) { j := add(j, 0x20) } {
                mstore(add(ret, add(0x20, j)), mload(add(bor, add(0x20, s))))
                s := add(s, 0x20)
            }
        }

        return (requireRange(cbor, i, len), ret);
    }

    function String32(bytes memory cbor, uint i) internal pure returns (uint, bytes32 ret, uint8 len) {
        return wordOfType(cbor, i, MajorText, 32);
    }

    function String32(bytes memory cbor, uint i, uint8 maxLen) internal pure returns (uint, bytes32, uint8) {
        return wordOfType(cbor, i, MajorText, maxLen);
    }

    function skipString(bytes memory cbor, uint i) internal pure returns (uint) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorText);
        return requireRange(cbor, i, len);
    }

    // ---- read bytes ----

    function Bytes(bytes memory cbor, uint i) internal pure returns (uint, bytes memory ret) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorBytes);

        bytes memory bor = cbor;
        uint s = i;

        ret = new bytes(len);

        require(i + len <= bor.length, "slice out of bounds");
        assembly ("memory-safe") {
            for { let j := 0 } lt(j, len) { j := add(j, 0x20) } {
                mstore(add(ret, add(0x20, j)), mload(add(bor, add(0x20, s))))
                s := add(s, 0x20)
            }
        }

        return (requireRange(cbor, i, len), ret);
    }

    function Bytes32(bytes memory cbor, uint i) internal pure returns (uint, bytes32, uint8) {
        return wordOfType(cbor, i, MajorBytes, 32);
    }

    function Bytes32(bytes memory cbor, uint i, uint8 maxLen) internal pure returns (uint, bytes32, uint8) {
        return wordOfType(cbor, i, MajorBytes, maxLen);
    }

    function skipBytes(bytes memory cbor, uint i) internal pure returns (uint) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorBytes);
        return requireRange(cbor, i, len);
    }

    // ---- read tag ----

    function Tag(bytes memory cbor, uint i) internal pure returns (uint, uint64 ret) {
        (i, ret) = headerExpect(cbor, i, MajorTag);
        return (i, ret);
    }

    function Tag(bytes memory cbor, uint i, uint64 expectTag) internal pure returns (uint) {
        uint64 ret;
        (i, ret) = headerExpect(cbor, i, MajorTag);
        require(ret == expectTag, "unexpected tag value");
        return i;
    }

    // ---- read unsigned integer ----

    function UInt(bytes memory cbor, uint i) internal pure returns (uint, uint64 ret) {
        (i, ret) = headerExpect(cbor, i, MajorUnsigned);
        return (i, ret);
    }

    function UInt8(bytes memory cbor, uint i) internal pure returns (uint, uint8) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorUnsigned, ArgSizeByte);
        return (i, uint8(arg));
    }

    function UInt16(bytes memory cbor, uint i) internal pure returns (uint, uint16) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorUnsigned, MinorExtendU16);
        // headerExpect ensures arg size
        return (i, uint16(arg));
    }

    function UInt32(bytes memory cbor, uint i) internal pure returns (uint, uint32) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorUnsigned, MinorExtendU32);
        // headerExpect ensures arg size
        return (i, uint32(arg));
    }

    function UInt64(bytes memory cbor, uint i) internal pure returns (uint, uint64 ret) {
        (i, ret) = headerExpect(cbor, i, MajorUnsigned, MinorExtendU64);
        return (i, ret);
    }

    // ---- read negative integer ----

    function NInt(bytes memory cbor, uint i) internal pure returns (uint, int128) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorNegative);
        return (i, -1 - int128(uint128(arg)));
    }

    function NInt8(bytes memory cbor, uint i) internal pure returns (uint, int16) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorNegative, ArgSizeByte);
        return (i, -1 - int16(uint16(arg)));
    }

    function NInt16(bytes memory cbor, uint i) internal pure returns (uint, int32) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorNegative, MinorExtendU16);
        return (i, -1 - int32(uint32(arg)));
    }

    function NInt32(bytes memory cbor, uint i) internal pure returns (uint, int64) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorNegative, MinorExtendU32);
        return (i, -1 - int64(uint64(arg)));
    }

    function NInt64(bytes memory cbor, uint i) internal pure returns (uint, int128) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorNegative, MinorExtendU64);
        return (i, -1 - int128(uint128(arg)));
    }

    // ---- read primitive/float ----

    type float16 is uint16;
    type float32 is uint32;
    type float64 is uint64;

    function Float(bytes memory cbor, uint i) internal pure returns (uint, float64) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorPrimitive);
        return (i, float64.wrap(arg));
    }

    function Float16(bytes memory cbor, uint i) internal pure returns (uint, float16) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorPrimitive, MinorExtendU16);
        return (i, float16.wrap(uint16(arg)));
    }

    function Float32(bytes memory cbor, uint i) internal pure returns (uint, float32) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorPrimitive, MinorExtendU32);
        return (i, float32.wrap(uint32(arg)));
    }

    function Float64(bytes memory cbor, uint i) internal pure returns (uint, float64) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorPrimitive, MinorExtendU64);
        return (i, float64.wrap(arg));
    }
}
