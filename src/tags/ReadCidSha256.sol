// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../ReadCbor.sol";

// we will only encounter CID v1 dag-cbor sha256, which perfectly fits uint256.
// some CID fields may be nullable, so the zero value represents a 'null' CID.
type CidSha256 is uint256;

using {_op_cidEq as ==, _op_cidNeq as !=, isNull, isFor} for CidSha256 global;

function _op_cidEq(CidSha256 a, CidSha256 b) pure returns (bool) {
    assert(CidSha256.unwrap(a) != 0 && CidSha256.unwrap(b) != 0);
    return CidSha256.unwrap(a) == CidSha256.unwrap(b);
}

function _op_cidNeq(CidSha256 a, CidSha256 b) pure returns (bool) {
    assert(CidSha256.unwrap(a) != 0 && CidSha256.unwrap(b) != 0);
    return CidSha256.unwrap(a) != CidSha256.unwrap(b);
}

function isFor(CidSha256 a, bytes memory b) pure returns (bool) {
    assert(CidSha256.unwrap(a) != 0 && b.length != 0);
    return CidSha256.unwrap(a) == uint256(sha256(b));
}

function isNull(CidSha256 a) pure returns (bool) {
    return CidSha256.unwrap(a) == 0;
}

library ReadCidSha256 {
    using ReadCbor for bytes;

    // all CIDs encountered should have a 9-byte header
    //    ─────────┬─────────
    //       hex   │ meaning
    //    ─────────┼─────────
    //       D8    │ CBOR major primitive, minor next byte
    //       2A    │ CBOR tag value 42 (CID)
    //       58    │ CBOR major bytes, minor next byte
    //       25    │ CBOR bytes length 37
    //       00    │ multibase format
    //       01    │ multiformat CID version 1
    //    71 || 55 │ multicodec DAG-CBOR or raw
    //       12    │ multihash type sha-256
    //       20    │ multihash size 32 bytes
    //    ─────────┴─────────
    bytes6 private constant cborTag42_cborBytes37_multibaseCidV1 = hex"D82A58250001";
    bytes1 private constant multicodecDagCbor = hex"71";
    bytes1 private constant multicodecRaw = hex"55";
    bytes2 private constant multihashSha256_multihashBytes32 = hex"1220";

    /**
     * @notice Reads a CID from CBOR encoded data at the specified byte index
     * @dev Expects 41 bytes: 4 bytes CBOR + 5 bytes multiformat + 32 bytes hash
     *      Reverts when:
     *      - Required length exceeds range
     *      - CBOR header is not a tag 42 and 37-byte item
     *      - Multibase header is not CID v1
     *      - Multicodec is mismatched (default DAG-CBOR, raw)
     *      - Multihash algorithm is not SHA-256
     *      - Multihash length is not 32 bytes
     *      - Hash content is zero
     * @return uint The next byte index after the CID
     * @return CidSha256 The representative hash
     */
    function Cid(bytes memory cbor, uint32 i) internal pure returns (uint32, CidSha256) {
        return Cid(cbor, i, multicodecDagCbor);
    }

    function Cid(bytes memory cbor, uint32 i, bytes1 multicodec) internal pure returns (uint32, CidSha256) {
        assert(multicodec == multicodecDagCbor || multicodec == multicodecRaw);
        bytes9 cborMultibase;
        bytes9 expect =
            bytes9(abi.encodePacked(cborTag42_cborBytes37_multibaseCidV1, multicodec, multihashSha256_multihashBytes32));

        uint256 cidSha256; // 32 bytes

        assembly ("memory-safe") {
            // cbor header at index
            cborMultibase := mload(add(cbor, add(0x20, i)))
            cidSha256 := mload(add(cbor, add(0x29, i)))
        }

        require(cborMultibase == expect, "Expected CBOR tag 42 and 37-byte CIDv1");
        require(cidSha256 != 0, "Expected non-zero CID value");

        return (
            cbor.requireRange(
                i + 4 // cbor header
                    + 5 // multibase header
                    + 32 // hash size
            ),
            CidSha256.wrap(cidSha256)
        );
    }

    /**
     * @notice Reads a CID that may be null from CBOR encoded data at the specified byte index
     * @dev If a CBOR null primitive appears at the byte index, the byte index
     *      is advanced appropriately and this function returns a 'zero' CID.
     * @return Cid The decoded CID, or zero CID if null
     * @return uint The next byte index after the CID or null value
     */
    function NullableCid(bytes memory cbor, uint32 i) internal pure returns (uint32, CidSha256) {
        return cbor.isNull(i) ? (i + 1, CidSha256.wrap(0)) : ReadCidSha256.Cid(cbor, i);
    }
}
