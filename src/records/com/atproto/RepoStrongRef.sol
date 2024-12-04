// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../../../cbor/ReadCid.sol";

using ReadCbor for bytes;

struct ComAtprotoRepoStrongRef {
    string cid; // i don't know why this cid is a string. i guess it's for the URI target?
    string uri; // at-uri
}

library ReadComAtprotoRepoStrongRef {
    bytes26 private constant nsid = "com.atproto.repo.strongRef";

    function RepoStrongRef(bytes memory cborData, uint byteIdx)
        internal
        pure
        returns (uint, ComAtprotoRepoStrongRef memory ref)
    {
        uint mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);

        require(mapLen >= 2, "expected 2 required fields in `com.atproto.repo.strongRef`");

        bytes32 mapKey;
        uint8 mapKeyLen;

        string memory cid;
        string memory uri;

        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, mapKeyLen) = cborData.String32(byteIdx, 9);
            if (
                // cid field
                mapKeyLen == 3 && bytes3(mapKey) == "cid"
            ) {
                //(byteIdx, cid) = cborData.Cid(byteIdx);
                (byteIdx, cid) = cborData.String(byteIdx);
            } else if (
                // uri field
                mapKeyLen == 3 && bytes3(mapKey) == "uri"
            ) {
                (byteIdx, uri) = cborData.String(byteIdx);
            } else {
                revert("unexpected record key");
            }
        }

        return (byteIdx, ComAtprotoRepoStrongRef(cid, uri));
    }
}
