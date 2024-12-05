// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "forge-std/console.sol";

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
    uint8 private constant MinorExtendU8 = 0x17 + 1; // 24
    uint8 private constant MinorExtendU16 = 0x17 + 2; // 25
    uint8 private constant MinorExtendU32 = 0x17 + 3; // 26
    uint8 private constant MinorExtendU64 = 0x17 + 4; // 27
    // minors 28-30 are reserved
    // minor 31 is unsupported

    function requireRange(bytes memory cbor, uint i) internal pure returns (uint) {
        require(i <= cbor.length, "index advance out of range");
        return i;
    }

    function requireComplete(bytes memory cbor, uint i) internal pure {
        require(i == cbor.length, "expected to read all bytes");
    }

    function u8(bytes memory cbor, uint i) private pure returns (uint n, uint8 ret) {
        assembly ("memory-safe") {
            // Load 1 bytes directly into value starting at position i
            ret := shr(248, mload(add(add(cbor, 0x20), i))) // 248 = 256 - (8 bits)
            n := add(i, 1)
        }
    }

    function u16(bytes memory cbor, uint i) private pure returns (uint n, uint16 ret) {
        assembly ("memory-safe") {
            // Load 2 bytes directly into value starting at position i
            ret := shr(240, mload(add(add(cbor, 0x20), i))) // 240 = 256 - (16 bits)
            n := add(i, 2)
        }
    }

    function u32(bytes memory cbor, uint i) private pure returns (uint n, uint32 ret) {
        assembly ("memory-safe") {
            // Load 4 bytes directly into value starting at position i
            ret := shr(224, mload(add(add(cbor, 0x20), i))) // 224 = 256 - (32 bits)
            n := add(i, 4)
        }
    }

    function u64(bytes memory cbor, uint i) private pure returns (uint n, uint64 ret) {
        assembly ("memory-safe") {
            // Load 8 bytes directly into value starting at position i
            ret := shr(192, mload(add(add(cbor, 0x20), i))) // 192 = 256 - (64 bits)
            n := add(i, 8)
        }
    }

    function headerExpect(bytes memory cbor, uint i, uint8 expectMajor) internal pure returns (uint, uint64) {
        uint8 h;
        (i, h) = u8(cbor, i);
        require(h >> shiftMajor == expectMajor, "unexpected major type");
        return parseArg(cbor, i, h & maskMinor);
    }

    function headerExpect(bytes memory cbor, uint i, uint8 expectMajor, uint8 expectMinor)
        internal
        pure
        returns (uint, uint64)
    {
        uint8 h;
        (i, h) = u8(cbor, i);
        uint8 major = h >> shiftMajor;
        uint8 minor = h & maskMinor;
        require(major == expectMajor, "unexpected major type");
        require(minor == expectMinor, "unexpected minor type");
        return parseArg(cbor, i, minor);
    }

    function headerExpectByteArg(bytes memory cbor, uint i, uint8 expectMajor)
        internal
        pure
        returns (uint, uint8 ret)
    {
        uint8 major;

        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i)))
            // Compute major and minor in one assembly block
            major := shr(5, h)
            ret := and(h, 0x1f)
            i := add(i, 1)
        }

        require(major == expectMajor, "unexpected major type");

        if (ret >= MinorExtendU8) {
            require(ret == MinorExtendU8, "expected single-byte arg");
            assembly ("memory-safe") {
                ret := shr(248, mload(add(add(cbor, 0x20), i)))
                i := add(i, 1)
            }
            require(ret >= MinorExtendU8, "invalid type argument (single-byte value too low)");
        }

        return (i, ret);
    }

    function headerExpectMultibyteArg(bytes memory cbor, uint i, uint8 expectMajor)
        internal
        pure
        returns (uint, uint64)
    {
        uint8 h;
        (i, h) = u8(cbor, i);
        uint8 major = h >> shiftMajor;
        uint8 minor = h & maskMinor;
        require(major == expectMajor, "unexpected major type");
        require(minor > MinorExtendU8, "expected multi-byte arg");
        return parseArg(cbor, i, minor);
    }

    function header(bytes memory cbor, uint i) internal pure returns (uint, uint64 arg, uint8) {
        uint8 h;
        (i, h) = u8(cbor, i);
        uint8 major = h >> shiftMajor;
        uint8 minor = h & maskMinor;
        (i, arg) = parseArg(cbor, i, minor);
        return (i, arg, major);
    }

    function parseArg(bytes memory cbor, uint i, uint8 minor) private pure returns (uint, uint64) {
        assert(minor < 32);
        if (minor < MinorExtendU8) {
            return (i, minor);
        } else {
            if (minor == MinorExtendU8) {
                uint8 arg;
                (i, arg) = u8(cbor, i);
                require(arg >= MinorExtendU8, "invalid type argument (single-byte value too low)");
                return (i, arg);
            } else if (minor == MinorExtendU16) {
                return u16(cbor, i);
            } else if (minor == MinorExtendU32) {
                return u32(cbor, i);
            } else if (minor == MinorExtendU64) {
                return u64(cbor, i);
            }
        }
        revert("minor unsupported");
    }

    // ---- read primitive/simple ----

    function isNull(bytes memory cbor, uint i) internal pure returns (bool ret) {
        assembly ("memory-safe") {
            ret := eq(byte(0, mload(add(add(cbor, 0x20), i))), 0xf6)
        }
    }

    function isUndefined(bytes memory cbor, uint i) internal pure returns (bool ret) {
        assembly ("memory-safe") {
            ret := eq(byte(0, mload(add(add(cbor, 0x20), i))), 0xf7)
        }
    }

    function Bool(bytes memory cbor, uint i) internal pure returns (uint, bool ret) {
        uint8 h;
        assembly ("memory-safe") {
            h := byte(0, mload(add(add(cbor, 0x20), i)))
            ret := eq(h, 0xF5)
            i := add(i, 1)
        }
        require(h == 0xF4 || ret, "expected boolean");
        return (i, ret);
    }

    // ---- read array size ----

    // An array of data items. The argument is the number of data items in the
    // array. Items in an array do not need to all be of the same type.
    function Array(bytes memory cbor, uint i) internal pure returns (uint, uint64) {
        return headerExpect(cbor, i, MajorArray);
    }

    // ---- read map size ----

    // A map is comprised of pairs of data items, each pair consisting of a key
    // that is immediately followed by a value. The argument is the number of
    // pairs of data items in the map.
    function Map(bytes memory cbor, uint i) internal pure returns (uint, uint64) {
        return headerExpect(cbor, i, MajorMap);
    }

    // ---- read string ----

    function String(bytes memory cbor, uint i) internal pure returns (uint, string memory ret) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorText);

        bytes memory bor = cbor;
        uint s = i;

        ret = new string(len);

        assembly ("memory-safe") {
            for { let j := 0 } lt(j, len) { j := add(j, 0x20) } {
                mstore(add(ret, add(0x20, j)), mload(add(bor, add(0x20, s))))
                s := add(s, 0x20)
            }
        }

        return (requireRange(cbor, i + len), ret);
    }

    function String32(bytes memory cbor, uint i) internal pure returns (uint, bytes32 ret, uint8 len) {
        return String32(cbor, i, 32);
    }

    function String32(bytes memory cbor, uint i, uint8 maxLen) internal pure returns (uint, bytes32 ret, uint8 len) {
        require(maxLen <= 32, "maxLen out of range (32-byte word)");

        (i, len) = headerExpectByteArg(cbor, i, MajorText);
        require(len <= maxLen, "item exceeds max length");

        assembly {
            ret := mload(add(cbor, add(0x20, i)))
        }

        return (requireRange(cbor, i + len), ret, uint8(len));
    }

    function String1(bytes memory cbor, uint i) internal pure returns (uint, bytes1 s) {
        bool valid;
        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i))) // load header byte
            valid := eq(h, 0x61) // 0x61 = (MajorText << 5) | 0x01
            s := mload(add(add(cbor, 0x21), i)) // load string byte
            i := add(i, 2)
        }
        require(valid, "expected single-byte string");
        return (i, s);
    }

    function skipString(bytes memory cbor, uint i) internal pure returns (uint) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorText);
        return requireRange(cbor, i + len);
    }

    // ---- read bytes ----

    function Bytes(bytes memory cbor, uint i) internal pure returns (uint, bytes memory ret) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorBytes);

        bytes memory bor = cbor;
        uint s = i;

        ret = new bytes(len);

        assembly ("memory-safe") {
            for { let j := 0 } lt(j, len) { j := add(j, 0x20) } {
                mstore(add(ret, add(0x20, j)), mload(add(bor, add(0x20, s))))
                s := add(s, 0x20)
            }
        }

        return (requireRange(cbor, i + len), ret);
    }

    function Bytes32(bytes memory cbor, uint i) internal pure returns (uint, bytes32, uint8) {
        return Bytes32(cbor, i, 32);
    }

    function Bytes32(bytes memory cbor, uint i, uint8 maxLen) internal pure returns (uint, bytes32 ret, uint8 len) {
        require(maxLen <= 32, "maxLen out of range (32-byte word)");

        (i, len) = headerExpectByteArg(cbor, i, MajorBytes);
        require(len <= maxLen, "item exceeds max length");

        assembly {
            ret := mload(add(cbor, add(0x20, i)))
        }

        return (requireRange(cbor, i + len), ret, uint8(len));
    }

    function skipBytes(bytes memory cbor, uint i) internal pure returns (uint) {
        uint64 len;
        (i, len) = headerExpect(cbor, i, MajorBytes);
        return requireRange(cbor, i + len);
    }

    // ---- read tag ----

    function Tag(bytes memory cbor, uint i) internal pure returns (uint, uint64 ret) {
        (i, ret) = headerExpect(cbor, i, MajorTag);
        return (i, ret);
    }

    function Tag(bytes memory cbor, uint i, uint64 expectTag) internal pure returns (uint) {
        uint64 ret;
        (i, ret) = headerExpectByteArg(cbor, i, MajorTag);
        require(ret == expectTag, "unexpected tag value");
        return i;
    }

    // ---- read unsigned integer ----

    function UInt(bytes memory cbor, uint i) internal pure returns (uint, uint64) {
        return headerExpect(cbor, i, MajorUnsigned);
    }

    function UInt8(bytes memory cbor, uint i) internal pure returns (uint, uint8) {
        return headerExpectByteArg(cbor, i, MajorUnsigned);
    }

    function UInt16(bytes memory cbor, uint i) internal pure returns (uint, uint16) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorUnsigned, MinorExtendU16);
        return (i, uint16(arg));
    }

    function UInt32(bytes memory cbor, uint i) internal pure returns (uint, uint32) {
        uint64 arg;
        (i, arg) = headerExpect(cbor, i, MajorUnsigned, MinorExtendU32);
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
        uint8 arg;
        (i, arg) = headerExpectByteArg(cbor, i, MajorNegative);
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

    /*
    // ---- read primitive/float ----

    type float16 is uint16;
    type float32 is uint32;
    type float64 is uint64;

    function Float(bytes memory cbor, uint i) internal pure returns (uint, float64) {
        uint64 arg;
        (i, arg) = headerExpectMultibyteArg(cbor, i, MajorPrimitive);
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
    */
}
