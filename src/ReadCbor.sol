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

uint8 constant MinorExtendU8 = 0x17 + 1; // 24
uint8 constant MinorExtendU16 = 0x17 + 2; // 25
uint8 constant MinorExtendU32 = 0x17 + 3; // 26
uint8 constant MinorExtendU64 = 0x17 + 4; // 27

uint8 constant SimpleFalse = 0x14;
uint8 constant SimpleTrue = 0x15;
uint8 constant SimpleNull = 0x16;
uint8 constant SimpleUndefined = 0x17;

library ReadCbor {
    /// @notice Parses a header type argument based on the minor type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current (header) index in the byte array
    /// @param minor The minor bits from the header byte
    /// @return The new index and the parsed argument value
    function parseArg(bytes memory cbor, uint32 i, uint8 minor) private pure returns (uint32, uint64) {
        if (minor < MinorExtendU8) {
            return (i, minor);
        } else if (minor == MinorExtendU8) {
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
        revert("minor unsupported");
    }

    function u8(bytes memory cbor, uint32 i) private pure returns (uint32 n, uint8 ret) {
        assembly ("memory-safe") {
            // Load 1 bytes directly into value starting at position i
            ret := shr(248, mload(add(add(cbor, 0x20), i))) // 248 = 256 - (8 bits)
            n := add(i, 1)
        }
    }

    function u16(bytes memory cbor, uint32 i) private pure returns (uint32 n, uint16 ret) {
        assembly ("memory-safe") {
            // Load 2 bytes directly into value starting at position i
            ret := shr(240, mload(add(add(cbor, 0x20), i))) // 240 = 256 - (16 bits)
            n := add(i, 2)
        }
    }

    function u32(bytes memory cbor, uint32 i) private pure returns (uint32 n, uint32 ret) {
        assembly ("memory-safe") {
            // Load 4 bytes directly into value starting at position i
            ret := shr(224, mload(add(add(cbor, 0x20), i))) // 224 = 256 - (32 bits)
            n := add(i, 4)
        }
    }

    function u64(bytes memory cbor, uint32 i) private pure returns (uint32 n, uint64 ret) {
        assembly ("memory-safe") {
            // Load 8 bytes directly into value starting at position i
            ret := shr(192, mload(add(add(cbor, 0x20), i))) // 192 = 256 - (64 bits)
            n := add(i, 8)
        }
    }

    /// @notice Ensures the current index is within bounds
    /// @param cbor The CBOR-encoded bytes
    /// @param i The index to check
    /// @return The validated index
    /// @dev Reverts if index is out of range
    function requireRange(bytes memory cbor, uint32 i) internal pure returns (uint32) {
        require(i <= cbor.length, "index out of range");
        return i;
    }

    /// @notice Verifies that all CBOR bytes have been read (index == cbor.length)
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @dev Reverts if there are unread bytes remaining
    function requireComplete(bytes memory cbor, uint32 i) internal pure {
        require(i == cbor.length, "expected to read all bytes");
    }

    /// @notice Reads a CBOR header, and possibly header extension
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index, type argument, and major type
    function header(bytes memory cbor, uint32 i) internal pure returns (uint32, uint64 arg, uint8 major) {
        uint8 h;
        (i, h) = u8(cbor, i);
        major = h >> shiftMajor;
        uint8 minor = h & maskMinor;
        (i, arg) = parseArg(cbor, i, minor);
        return (i, arg, major);
    }

    /// @notice Reads a CBOR header with an expected major type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @return The new index and argument value
    /// @dev Reverts if major type doesn't match expected
    function header(bytes memory cbor, uint32 i, uint8 expectMajor) internal pure returns (uint32, uint64) {
        uint8 h;
        (i, h) = u8(cbor, i);
        require(h >> shiftMajor == expectMajor, "unexpected major type");
        return parseArg(cbor, i, h & maskMinor);
    }

    /// @notice Reads a CBOR header with expected major and minor types
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @param expectMinor The expected minor type
    /// @return The new index and argument value
    /// @dev Reverts if major or minor types don't match expected
    function header(bytes memory cbor, uint32 i, uint8 expectMajor, uint8 expectMinor)
        internal
        pure
        returns (uint32, uint64)
    {
        uint8 h;
        (i, h) = u8(cbor, i);
        uint8 major = h >> shiftMajor;
        require(major == expectMajor, "unexpected major type");
        uint8 minor = h & maskMinor;
        require(minor == expectMinor, "unexpected minor type");
        return parseArg(cbor, i, minor);
    }

    /// @notice Optimized header reading for uint8 type arguments of an expected major type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @return The new index and argument value
    /// @dev For u8 type arguments only (literal minor or 1-byte extended)
    function header8(bytes memory cbor, uint32 i, uint8 expectMajor) internal pure returns (uint32, uint8 arg) {
        uint8 major;

        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i)))
            major := shr(shiftMajor, h)
            arg := and(h, maskMinor)
            i := add(i, 1)
        }

        require(major == expectMajor, "unexpected major type");

        if (arg >= MinorExtendU8) {
            require(arg == MinorExtendU8, "unexpected minor type");
            assembly ("memory-safe") {
                arg := shr(248, mload(add(add(cbor, 0x20), i)))
                i := add(i, 1)
            }
            require(arg >= MinorExtendU8, "invalid extended header");
        }

        return (i, arg);
    }

    /// @notice Optimized header reading for uint32 type arguments of an expected major type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @return The new index and argument value
    /// @dev For type arguments expected to specify a length, uint32 is sufficient
    function header32(bytes memory cbor, uint32 i, uint8 expectMajor) internal pure returns (uint32, uint32 arg) {
        uint8 major;

        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i)))
            major := shr(shiftMajor, h)
            arg := and(h, maskMinor) // minor literal arg
            i := add(i, 1)
        }

        require(major == expectMajor, "unexpected major type");

        if (arg == MinorExtendU8) {
            assembly ("memory-safe") {
                arg := shr(248, mload(add(add(cbor, 0x20), i)))
                i := add(i, 1)
            }
            require(arg >= MinorExtendU8, "invalid extended header");
        } else if (arg >= MinorExtendU8) {
            require(arg <= MinorExtendU32, "unexpected minor type");
            if (arg == MinorExtendU16) {
                assembly ("memory-safe") {
                    arg := shr(240, mload(add(add(cbor, 0x20), i)))
                    i := add(i, 2)
                }
            } else if (arg == MinorExtendU32) {
                assembly ("memory-safe") {
                    arg := shr(224, mload(add(add(cbor, 0x20), i)))
                    i := add(i, 4)
                }
            }
        }

        return (i, arg);
    }

    /// @notice Checks if the next item is null
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is null
    function isNull(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(byte(0, mload(add(add(cbor, 0x20), i))), or(shl(shiftMajor, MajorPrimitive), SimpleNull))
        }
    }

    /// @notice Reads a null item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index
    /// @dev Reverts if item is not null
    function Null(bytes memory cbor, uint32 i) internal pure returns (uint32) {
        require(isNull(cbor, i), "expected null");
        return i + 1;
    }

    /// @notice Checks if the next item is undefined
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is undefined
    function isUndefined(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(byte(0, mload(add(add(cbor, 0x20), i))), or(shl(shiftMajor, MajorPrimitive), SimpleUndefined))
        }
    }

    /// @notice Reads an undefined item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index
    /// @dev Reverts if item is not undefined
    function Undefined(bytes memory cbor, uint32 i) internal pure returns (uint32) {
        require(isUndefined(cbor, i), "expected undefined");
        return i + 1;
    }

    /// @notice Checks if the next item is a boolean
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a boolean
    function isBool(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            let h := byte(0, mload(add(add(cbor, 0x20), i)))
            indeed :=
                or(
                    eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleTrue)),
                    eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleFalse))
                )
        }
    }

    /// @notice Reads a boolean item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the boolean value
    /// @dev Reverts if item is not a boolean
    function Bool(bytes memory cbor, uint32 i) internal pure returns (uint32, bool isTrue) {
        bool isFalse;
        assembly ("memory-safe") {
            let h := byte(0, mload(add(add(cbor, 0x20), i)))
            isTrue := eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleTrue))
            isFalse := eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleFalse))
            i := add(i, 1)
        }
        require(isFalse || isTrue, "expected boolean");
        return (i, isTrue);
    }

    /// @notice Checks if the next item is an array
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is an array
    function isArray(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorArray)
        }
    }

    /// @notice Reads an array header and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the number of items in the array
    function Array(bytes memory cbor, uint32 i) internal pure returns (uint32, uint32) {
        // An array of data items. The argument is the number of data items in the
        // array. Items in an array do not need to all be of the same type.
        return header32(cbor, i, MajorArray);
    }

    /// @notice Checks if the next item is a map
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a map
    function isMap(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorMap)
        }
    }

    /// @notice Reads a map header and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the number of key-value pairs in the map
    function Map(bytes memory cbor, uint32 i) internal pure returns (uint32, uint32) {
        // A map is comprised of pairs of data items, each pair consisting of a key
        // that is immediately followed by a value. The argument is the number of
        // pairs of data items in the map.
        return header32(cbor, i, MajorMap);
    }

    /// @notice Checks if the next item is a string
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a string
    function isString(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorText)
        }
    }

    /// @notice Reads a string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the string value
    function String(bytes memory cbor, uint32 i) internal pure returns (uint32, string memory ret) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorText);

        ret = new string(len);
        assembly ("memory-safe") {
            for { let j := 0 } lt(j, len) { j := add(j, 0x20) } {
                mstore(add(ret, add(0x20, j)), mload(add(cbor, add(i, add(0x20, j)))))
            }
        }

        return (requireRange(cbor, i + len), ret);
    }

    /// @notice Reads a string item into a bytes32 and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index, the bytes32 value, and the string length
    /// @dev Reverts if string length exceeds 32
    function String32(bytes memory cbor, uint32 i) internal pure returns (uint32, bytes32 ret, uint8 len) {
        return String32(cbor, i, 32);
    }

    /// @notice Reads a string item into a bytes32 and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param maxLen The maximum allowed string length, which must be <= 32
    /// @return The new index, the bytes32 value, and the string length
    /// @dev Reverts if string length exceeds maxLen
    function String32(bytes memory cbor, uint32 i, uint8 maxLen)
        internal
        pure
        returns (uint32, bytes32 ret, uint8 len)
    {
        assert(maxLen <= 32);
        (i, len) = header8(cbor, i, MajorText);
        require(len <= maxLen, "string length out of range");

        assembly ("memory-safe") {
            ret := mload(add(cbor, add(0x20, i)))
            ret := and(ret, not(shr(mul(len, 8), not(0))))
        }

        return (requireRange(cbor, i + len), ret, uint8(len));
    }

    /// @notice Reads a single-byte string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the single byte value
    /// @dev Reverts if string length is not exactly 1
    function String1(bytes memory cbor, uint32 i) internal pure returns (uint32, bytes1 s) {
        bool valid;
        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i))) // load header byte
            valid := eq(h, or(shl(shiftMajor, MajorText), 1))
            s := mload(add(add(add(cbor, 0x20), i), 1)) // load string byte
            i := add(i, 2)
        }
        require(valid, "expected single-byte string");
        return (i, s);
    }

    /// @notice Skips a string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index after the string
    function skipString(bytes memory cbor, uint32 i) internal pure returns (uint32) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorText);
        return requireRange(cbor, i + len);
    }

    /// @notice Checks if the next item is a byte string
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a byte string
    function isBytes(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorBytes)
        }
    }

    /// @notice Reads a byte string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the byte string value
    function Bytes(bytes memory cbor, uint32 i) internal pure returns (uint32, bytes memory ret) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorBytes);

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

    /// @notice Reads a byte string item into a bytes32 and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index, the bytes32 value, and the byte string length
    function Bytes32(bytes memory cbor, uint32 i) internal pure returns (uint32, bytes32, uint8) {
        return Bytes32(cbor, i, 32);
    }

    /// @notice Reads a byte string item into a bytes32 and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param maxLen The maximum allowed byte string length, which must be <= 32
    /// @return The new index, the bytes32 value, and the byte string length
    /// @dev Reverts if byte string length exceeds maxLen
    function Bytes32(bytes memory cbor, uint32 i, uint8 maxLen)
        internal
        pure
        returns (uint32, bytes32 ret, uint8 len)
    {
        assert(maxLen <= 32);
        (i, len) = header8(cbor, i, MajorBytes);
        require(len <= maxLen, "bytes length out of range");

        assembly ("memory-safe") {
            ret := mload(add(cbor, add(0x20, i)))
            ret := and(ret, not(shr(mul(len, 8), not(0))))
        }

        return (requireRange(cbor, i + len), ret, uint8(len));
    }

    /// @notice Skips a byte string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index after the byte string
    function skipBytes(bytes memory cbor, uint32 i) internal pure returns (uint32) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorBytes);
        return requireRange(cbor, i + len);
    }

    /// @notice Checks if the next item is a tag
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a tag
    function isTag(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorTag)
        }
    }

    /// @notice Checks if the next item is a specific tag
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectTag The expected tag value
    /// @return indeed the next item is the expected tag
    function isTag(bytes memory cbor, uint32 i, uint64 expectTag) internal pure returns (bool indeed) {
        uint64 arg;
        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i)))

            if eq(shr(shiftMajor, h), MajorTag) {
                //let arg := and(h, maskMinor)
                arg := and(h, maskMinor)
                i := add(i, 1)
                if gt(arg, 0x17) {
                    switch arg
                    case 0x18 { arg := shr(248, mload(add(add(cbor, 0x20), i))) }
                    case 0x19 { arg := shr(240, mload(add(add(cbor, 0x20), i))) }
                    case 0x1a { arg := shr(224, mload(add(add(cbor, 0x20), i))) }
                    case 0x1b { arg := shr(192, mload(add(add(cbor, 0x20), i))) }
                    default { arg := not(expectTag) }
                }

                indeed := eq(arg, expectTag)
            }
        }
    }

    /// @notice Reads a tag item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the tag value
    function Tag(bytes memory cbor, uint32 i) internal pure returns (uint32, uint64 tag) {
        return header(cbor, i, MajorTag);
    }

    /// @notice Reads a specific tag item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectTag The expected tag value
    /// @return The new index
    /// @dev Reverts if tag doesn't match expected value
    function Tag(bytes memory cbor, uint32 i, uint64 expectTag) internal pure returns (uint32) {
        uint64 tag;
        (i, tag) = header(cbor, i, MajorTag);
        require(tag == expectTag, "unexpected tag");
        return i;
    }

    /// @notice Checks if the next item is an unsigned (positive) integer
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is an unsigned integer
    function isUInt(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorUnsigned)
        }
    }

    /// @notice Reads an unsigned integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the unsigned integer value
    function UInt(bytes memory cbor, uint32 i) internal pure returns (uint32, uint64) {
        return header(cbor, i, MajorUnsigned);
    }

    /// @notice Reads a uint8 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the uint8 value
    function UInt8(bytes memory cbor, uint32 i) internal pure returns (uint32, uint8) {
        return header8(cbor, i, MajorUnsigned);
    }

    /// @notice Reads a uint16 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the uint16 value
    function UInt16(bytes memory cbor, uint32 i) internal pure returns (uint32, uint16) {
        uint64 arg;
        (i, arg) = header(cbor, i, MajorUnsigned, MinorExtendU16);
        return (i, uint16(arg));
    }

    /// @notice Reads a uint32 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the uint32 value
    function UInt32(bytes memory cbor, uint32 i) internal pure returns (uint32, uint32) {
        uint64 arg;
        (i, arg) = header(cbor, i, MajorUnsigned, MinorExtendU32);
        return (i, uint32(arg));
    }

    /// @notice Reads a uint64 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the uint64 value
    function UInt64(bytes memory cbor, uint32 i) internal pure returns (uint32, uint64 ret) {
        (i, ret) = header(cbor, i, MajorUnsigned, MinorExtendU64);
        return (i, ret);
    }

    /// @notice Checks if the next item is a negative integer
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a negative integer
    function isNInt(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorNegative)
        }
    }

    /// @notice Reads a negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and the negative integer value
    function NInt(bytes memory cbor, uint32 i) internal pure returns (uint32, int72) {
        uint64 arg;
        (i, arg) = header(cbor, i, MajorNegative);
        return (i, -1 - int72(uint72(arg)));
    }

    /// @notice Reads an 8-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and a signed int16 value
    function NInt8(bytes memory cbor, uint32 i) internal pure returns (uint32, int16) {
        uint8 arg;
        (i, arg) = header8(cbor, i, MajorNegative);
        return (i, -1 - int16(uint16(arg)));
    }

    /// @notice Reads a 16-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and a signed int24 value
    function NInt16(bytes memory cbor, uint32 i) internal pure returns (uint32, int24) {
        uint64 arg;
        (i, arg) = header(cbor, i, MajorNegative, MinorExtendU16);
        return (i, -1 - int24(uint24(arg)));
    }

    /// @notice Reads a 32-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and a signed int40 value
    function NInt32(bytes memory cbor, uint32 i) internal pure returns (uint32, int40) {
        uint64 arg;
        (i, arg) = header(cbor, i, MajorNegative, MinorExtendU32);
        return (i, -1 - int40(uint40(arg)));
    }

    /// @notice Reads a 64-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and a signed int72 value
    function NInt64(bytes memory cbor, uint32 i) internal pure returns (uint32, int72) {
        uint64 arg;
        (i, arg) = header(cbor, i, MajorNegative, MinorExtendU64);
        return (i, -1 - int72(uint72(arg)));
    }

    /// @notice Checks if the next item is any integer (positive or negative)
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is any integer
    function isInt(bytes memory cbor, uint32 i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            let major := shr(253, mload(add(add(cbor, 0x20), i)))
            indeed := or(eq(major, MajorUnsigned), eq(major, MajorNegative))
        }
    }

    /// @notice Reads any integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return The new index and a signed int72 value
    function Int(bytes memory cbor, uint32 i) internal pure returns (uint32, int72) {
        uint8 h;
        uint8 major;
        (, h) = u8(cbor, i);
        major = h >> shiftMajor;
        if (major == MajorUnsigned) {
            uint72 arg;
            (i, arg) = UInt(cbor, i);
            return (i, int72(arg));
        } else if (major == MajorNegative) {
            return NInt(cbor, i);
        }
        revert("unexpected major type");
    }
}
