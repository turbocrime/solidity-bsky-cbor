// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "./CidCbor.sol";

struct Commit {
    string did;
    // uint8 verison;
    Cid data;
    string rev;
    // Cid prev;
    // bytes sig;
} // forgefmt: disable-line

library CommitCbor {
    using CBORDecoder for bytes;

    uint8 private constant COMMIT_VERSION = 3;
    uint8 private constant SIG_V = 1 + 27;

    function readCommit(bytes memory cborData) internal pure returns (Commit memory commit) {
        uint byteIdx = 0;
        (commit, byteIdx) = readCommitAt(cborData, byteIdx);
        require(byteIdx == cborData.length, "expected to read all bytes");
        return commit;
    }

    function readCommitAt(bytes memory cborData, uint byteIdx) private pure returns (Commit memory commit, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);

        require(mapLen == 5, "expected 5 fields in commit");

        for (uint i = 0; i < mapLen; i++) {
            bytes8 mapKey;
            (mapKey, byteIdx) = cborData.readStringBytes7(byteIdx);
            if (bytes4(mapKey) == "did") {
                (commit.did, byteIdx) = cborData.readString(byteIdx);
                // TODO: other did formats? more comprehensive validation?
                require(bytes(commit.did).length == 32, "commit did string must be 32 bytes");
            } else if (bytes7(mapKey) == "version") {
                uint8 version;
                (version, byteIdx) = cborData.readUInt8(byteIdx);
                require(version == COMMIT_VERSION, "commit version number must be 3");
            } else if (bytes5(mapKey) == "data") {
                (commit.data, byteIdx) = CidCbor.readCid(cborData, byteIdx);
            } else if (bytes5(mapKey) == "prev") {
                // TODO: possible assertions?
                (, byteIdx) = CidCbor.readNullableCid(cborData, byteIdx);
            } else if (bytes4(mapKey) == "rev") {
                // monotonic commit timestamp
                (commit.rev, byteIdx) = cborData.readString(byteIdx);
            } else {
                revert("unexpected commit field");
            }
        }

        return (commit, byteIdx);
    }

    // TODO: confirm this actually works lol
    function compareRevs(string memory rev1, string memory rev2) internal pure returns (bool) {
        bytes memory rev1Bytes = bytes(rev1);
        bytes memory rev2Bytes = bytes(rev2);
        require(rev1Bytes.length <= 32 && rev2Bytes.length <= 32, "unimplemented comparison of revs longer than 32 bytes");
        return uint256(bytes32(rev1Bytes)) > uint256(bytes32(rev2Bytes));
    }

    function verifyCommit(bytes memory commit, bytes32 sig_r, bytes32 sig_s, address signer, string memory lastRev)
        internal
        pure
        returns (Commit memory)
    {
        require(signer != address(0), "Null signer");
        require(signer == ecrecover(sha256(commit), SIG_V, sig_r, sig_s), "Invalid signature");
        Commit memory parsed = readCommit(commit);
        require(compareRevs(parsed.rev, lastRev), "commit rev must be newer than last rev");
        return parsed;
    }

    function verifyCommitWithoutRev(bytes memory commit, bytes32 sig_r, bytes32 sig_s, address signer)
        internal
        pure
        returns (Commit memory)
    {
        return verifyCommit(commit, sig_r, sig_s, signer, string(hex"00"));
    }
}
