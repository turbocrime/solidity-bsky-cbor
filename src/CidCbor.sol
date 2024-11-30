// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "./CborDecode.sol";

using {cidEq as ==, cidNeq as !=, isNull, isFor} for Cid global;

// we will only encounter CID v1 dag-cbor sha256, and sha256 fits a uint256.
// some CID fields may be nullable, so the zero value identifies a 'null' CID.
type Cid is uint256;

function cidEq(Cid a, Cid b) pure returns (bool) {
    require(Cid.unwrap(a) != 0 && Cid.unwrap(b) != 0, "Invalid CID comparison: null CID");
    return Cid.unwrap(a) == Cid.unwrap(b);
}

function cidNeq(Cid a, Cid b) pure returns (bool) {
    return !cidEq(a, b);
}

function isFor(Cid a, bytes memory b) pure returns (bool) {
    require(Cid.unwrap(a) != 0, "Invalid CID check: null CID");
    require(b.length != 0, "Invalid CID check: no content");
    return Cid.unwrap(a) == uint256(sha256(b));
}

function isNull(Cid a) pure returns (bool) {
    return Cid.unwrap(a) == 0;
}

library CidCbor {
    using CBORDecoder for bytes;

    // any CIDv1 DAG-CBOR sha-256 will always have this 9-byte header
    // ─────┬─────────
    //  hex │ meaning
    // ─────┼─────────
    //   D8 │ CBOR major primitive, minor next byte
    //   2A │ CBOR tag value 42 (CID)
    //   58 │ CBOR major bytes, minor next byte
    //   25 │ CBOR bytes length 37
    //   00 │ multibase format
    //   01 │ multiformat CID version 1
    //   71 │ multicodec DAG-CBOR
    //   12 │ multihash type sha-256
    //   20 │ multihash size 32 bytes
    // ─────┴─────────
    bytes4 private constant cbor_tag42_bytes37 = hex"D82A5825";
    bytes5 private constant multibase_cidv1_dagcbor_sha256 = hex"0001711220";

    /**
     * @notice Reads a CIDv1 DAG-CBOR sha-256 from CBOR encoded data at the specified byte index
     * @dev Expects a 41-byte CID structure: 4 bytes CBOR header + 5 bytes multibase header + 32 bytes SHA-256 hash
     *      Reverts when:
     *      - The remaining bytes are less than the expected CID size
     *      - The CBOR header is not tag 42 with 37-byte item
     *      - The multibase header is not CIDv1 DAG-CBOR sha256
     *      - The hash value is zero
     * @param cborData The CBOR encoded byte array containing the CID
     * @param byteIdx The starting index in the byte array to read from
     * @return Cid The decoded CID
     * @return uint The next byte index after the CID
     */
    function readCid(bytes memory cborData, uint byteIdx) internal pure returns (Cid, uint) {
        bytes4 cborHead;
        bytes5 multibaseHead;
        uint256 cidSha256; // 32 bytes

        require(byteIdx + 4 + 5 + 32 <= cborData.length, "Expected CID size is out of range");

        assembly ("memory-safe") {
            // cbor header at index
            cborHead := mload(add(cborData, add(0x20, byteIdx)))
            // multibase header at index + cbor header
            multibaseHead := mload(add(cborData, add(0x20, add(4, byteIdx))))
            // cid hash at index + cbor header + multibase header
            cidSha256 := mload(add(cborData, add(0x20, add(9, byteIdx))))
        }

        require(cborHead == cbor_tag42_bytes37, "Expected CBOR tag 42 and 37-byte item");
        require(multibaseHead == multibase_cidv1_dagcbor_sha256, "Expected multibase CIDv1 DAG-CBOR sha256");
        require(cidSha256 != 0, "Expected non-zero sha256 hash");

        return (Cid.wrap(cidSha256), byteIdx + 4 + 5 + 32);
    }

    /**
     * @notice Reads a CID that may be null from CBOR encoded data at the specified byte index
     * @dev If a CBOR null primitive appears at the byte index, the byte index
     *      is advanced appropriately and this function returns a 'zero' CID.
     * @param cborData The CBOR bytes containing the CID or null
     * @param byteIdx The starting index to read from
     * @return Cid The decoded CID, or zero CID if null
     * @return uint The next byte index after the CID or null value
     */
    function readNullableCid(bytes memory cborData, uint byteIdx) internal pure returns (Cid, uint) {
        if (cborData.isNullNext(byteIdx)) {
            return (Cid.wrap(0), byteIdx + 1);
        } else {
            return readCid(cborData, byteIdx);
        }
    }
}
