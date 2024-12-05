// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../../../tags/ReadCid.sol";

using ReadCbor for bytes;

library ComAtprotoRepo {
    bytes26 private constant nsid = "com.atproto.repo.strongRef";

    struct StrongRef {
        string cid; // this cid is a string, as it's intended for a URI target segment
        string uri; // at: uri
    }

    function readStrongRef(bytes memory cborData) internal pure returns (StrongRef memory) {
        (uint byteIdx, StrongRef memory ref) = readStrongRef(cborData, 0);
        cborData.requireComplete(byteIdx);
        return ref;
    }

    function readStrongRef(bytes memory cborData, uint byteIdx) internal pure returns (uint, StrongRef memory ref) {
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

        return (byteIdx, StrongRef(cid, uri));
    }
}
