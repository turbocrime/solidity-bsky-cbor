// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

using {cidEq as ==, cidNeq as !=, isNull, isFor} for CidSha256 global;

// we will only encounter CID v1 dag-cbor sha256, and sha256 fits a uint256.
// some CID fields may be nullable, so the zero value identifies a 'null' CID.
type CidSha256 is uint256;

function cidEq(CidSha256 a, CidSha256 b) pure returns (bool) {
    require(CidSha256.unwrap(a) != 0 && CidSha256.unwrap(b) != 0, "Invalid CID comparison: null CID");
    return CidSha256.unwrap(a) == CidSha256.unwrap(b);
}

function cidNeq(CidSha256 a, CidSha256 b) pure returns (bool) {
    return !cidEq(a, b);
}

function isFor(CidSha256 a, bytes memory b) pure returns (bool) {
    require(CidSha256.unwrap(a) != 0, "Invalid CID check: null CID");
    require(b.length != 0, "Invalid CID check: no content");
    return CidSha256.unwrap(a) == uint256(sha256(b));
}

function isNull(CidSha256 a) pure returns (bool) {
    return CidSha256.unwrap(a) == 0;
}

import "./CborRead.sol";

using CborRead for bytes;

library CborReadCid {
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
    bytes9 private constant cbor_tag42_bytes37_multibase_cidv1_dagcbor_sha256 = hex"D82A58250001711220";

    /**
     * @notice Reads a CIDv1 DAG-CBOR sha-256 from CBOR encoded data at the specified byte index
     * @dev Expects a 41-byte CID structure: 4 bytes CBOR header + 5 bytes multibase header + 32 bytes SHA-256 hash
     *      Reverts when:
     *      - The remaining bytes are less than the expected CID size
     *      - The CBOR header is not tag 42 with 37-byte item
     *      - The multibase header is not CIDv1 DAG-CBOR sha256
     *      - The hash value is zero
     * @return Cid The decoded CID
     * @return uint The next byte index after the CID
     */
    function Cid(bytes memory cbor, uint i) internal pure returns (uint, CidSha256) {
        bytes9 multibaseCborHead;
        uint256 cidSha256; // 32 bytes

        cbor.requireRange(i, multibaseCborHead.length + 32);

        assembly ("memory-safe") {
            // cbor header at index
            multibaseCborHead := mload(add(cbor, add(0x20, i)))
            // cid hash at index + cbor header + multibase header
            cidSha256 := mload(add(cbor, add(0x20, add(9, i))))
        }

        require(
            multibaseCborHead == cbor_tag42_bytes37_multibase_cidv1_dagcbor_sha256,
            "Expected CBOR tag 42 and 37-byte item containing multibase CIDv1 DAG-CBOR sha256"
        );
        require(cidSha256 != 0, "Expected non-zero sha256 hash");

        i += multibaseCborHead.length + 32;

        return (i, CidSha256.wrap(cidSha256));
    }

    /**
     * @notice Reads a CID that may be null from CBOR encoded data at the specified byte index
     * @dev If a CBOR null primitive appears at the byte index, the byte index
     *      is advanced appropriately and this function returns a 'zero' CID.
     * @return Cid The decoded CID, or zero CID if null
     * @return uint The next byte index after the CID or null value
     */
    function NullableCid(bytes memory cbor, uint i) internal pure returns (uint, CidSha256) {
        if (cbor.isNull(i)) {
            return (i + 1, CidSha256.wrap(0));
        } else {
            return CborReadCid.Cid(cbor, i);
        }
    }
}
