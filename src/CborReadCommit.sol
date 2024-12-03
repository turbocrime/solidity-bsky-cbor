// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "./CborReadCid.sol";

struct Commit {
    string did;
    // uint8 verison;
    CidSha256 data;
    string rev;
    // Cid prev;
    // bytes sig;
} // forgefmt: disable-line

library CborReadCommit {
    using CborRead for bytes;
    using CborReadCid for bytes;

    uint8 private constant COMMIT_VERSION = 3;
    uint8 private constant SIG_V = 1 + 27;

    function UnsafeCommit(bytes memory cbor, uint i) internal pure returns (uint, Commit memory commit) {
        uint mapLen;
        (i, mapLen) = cbor.Map(i);

        require(mapLen == 5, "expected 5 fields in commit");

        for (uint8 mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            bytes32 mapKey;
            uint8 mapKeyLen;
            (i, mapKey, mapKeyLen) = cbor.String32(i, 7);
            if (mapKeyLen == 3 && bytes3(mapKey) == "did") {
                (i, commit.did ) = cbor.String(i);
                // TODO: did formats? more comprehensive validation?
                require(bytes(commit.did).length == 32, "commit did string must be 32 bytes");
            } else if (bytes7(mapKey) == "version") {
                uint8 version;
                (i, version ) = cbor.UInt8(i);
                require(version == COMMIT_VERSION, "commit version number must be 3");
            } else if (mapKeyLen == 4 && bytes4(mapKey) == "data") {
                (i, commit.data ) = cbor.Cid(i);
            } else if (mapKeyLen == 4 && bytes4(mapKey) == "prev") {
                // TODO: possible assertions?
                (i, ) = cbor.NullableCid(i);
            } else if (mapKeyLen == 3 && bytes3(mapKey) == "rev") {
                // monotonic commit timestamp
                (i, commit.rev ) = cbor.String(i);
            } else {
                revert("unexpected commit field");
            }
        }

        return (i, commit);
    }

    // TODO: confirm this actually works lol
    function compareRevs(string memory rev1, string memory rev2) internal pure returns (bool) {
        bytes memory rev1Bytes = bytes(rev1);
        bytes memory rev2Bytes = bytes(rev2);
        require(rev1Bytes.length <= 32 && rev2Bytes.length <= 32, "unimplemented comparison of revs longer than 32 bytes");
        return uint256(bytes32(rev1Bytes)) > uint256(bytes32(rev2Bytes));
    }

    function verifyCommit(bytes memory cbor, bytes32 sig_r, bytes32 sig_s, address signer, string memory lastRev)
        internal
        pure
        returns (Commit memory)
    {
        require(signer != address(0), "Null signer");
        require(signer == ecrecover(sha256(cbor), SIG_V, sig_r, sig_s), "Invalid signature");
        (uint i, Commit memory parsed) = UnsafeCommit(cbor, 0);
        cbor.requireComplete(i);
        require(compareRevs(parsed.rev, lastRev), "commit rev must be newer than last rev");
        return parsed;
    }

    function verifyCommitWithoutRev(bytes memory cbor, bytes32 sig_r, bytes32 sig_s, address signer)
        internal
        pure
        returns (Commit memory)
    {
        return verifyCommit(cbor, sig_r, sig_s, signer, string(hex"00"));
    }
}
