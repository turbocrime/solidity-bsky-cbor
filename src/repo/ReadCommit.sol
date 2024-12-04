// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../cbor/ReadCid.sol";

using ReadCbor for bytes;
using ReadCid for bytes;

struct Commit {
    // omitted fields:
    // - uint8 verison;
    // - Null/CidSha256 prev;
    // - bytes sig;
    string did;
    CidSha256 data;
    string rev;
}

library ReadCommit {
    uint8 private constant COMMIT_VERSION = 3;
    uint8 private constant SIG_V = 1 + 27;

    function readCommit(bytes memory cbor) internal pure returns (Commit memory commit) {
        (uint i, uint mapLen) = cbor.Map(0);

        require(mapLen == 5 || mapLen == 4, "expected 4 or 5 fields in commit");

        for (uint8 mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            bytes32 mapKey;
            uint8 mapKeyLen;
            (i, mapKey, mapKeyLen) = cbor.String32(i, 7);
            if (mapKeyLen == 3 && bytes3(mapKey) == "did") {
                (i, commit.did) = cbor.String(i);
                // TODO: did formats? more comprehensive validation?
                require(bytes(commit.did).length == 32, "commit did string must be 32 bytes");
            } else if (bytes7(mapKey) == "version") {
                uint8 version;
                (i, version) = cbor.UInt8(i);
                require(version == COMMIT_VERSION, "commit version number must be 3");
            } else if (mapKeyLen == 4 && bytes4(mapKey) == "data") {
                (i, commit.data) = cbor.Cid(i);
            } else if (mapKeyLen == 4 && bytes4(mapKey) == "prev") {
                // TODO: possible assertions?
                (i,) = cbor.NullableCid(i);
            } else if (mapKeyLen == 3 && bytes3(mapKey) == "rev") {
                // monotonic commit timestamp
                (i, commit.rev) = cbor.String(i);
            } else {
                revert("unexpected commit field");
            }
        }

        cbor.requireComplete(i);

        return commit;
    }

    // TODO: confirm this actually works lol
    function compareRevs(string memory rev1, string memory rev2) internal pure returns (bool) {
        bytes memory rev1Bytes = bytes(rev1);
        bytes memory rev2Bytes = bytes(rev2);
        require(
            rev1Bytes.length <= 32 && rev2Bytes.length <= 32, "unimplemented comparison of revs longer than 32 bytes"
        );
        return uint256(bytes32(rev1Bytes)) > uint256(bytes32(rev2Bytes));
    }

    function readVerifiedCommit(bytes memory cbor, bytes32 sig_r, bytes32 sig_s, address signer, string memory lastRev)
        internal
        pure
        returns (Commit memory)
    {
        require(signer != address(0), "Null signer");
        require(signer == ecrecover(sha256(cbor), SIG_V, sig_r, sig_s), "Invalid signature");
        Commit memory commit = readCommit(cbor);
        require(compareRevs(commit.rev, lastRev), "commit rev must be newer than last rev");
        return commit;
    }
}
