// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../../../cbor/ReadCid.sol";
import "../../com/atproto/RepoStrongRef.sol";

using ReadCbor for bytes;
using ReadCid for bytes;
using ReadComAtprotoRepoStrongRef for bytes;

struct AppBskyFeedLike {
    string text;
}

library ReadAppBskyFeedLike {
    bytes18 private constant nsid = "app.bsky.feed.like";

    function FeedLike(bytes memory cborData) internal pure returns (ComAtprotoRepoStrongRef memory feedLikeSubject) {
        (uint byteIdx, uint mapLen) = cborData.Map(0);

        require(mapLen >= 3, "expected at least type and 2 required fields in `app.bsky.feed.like` record");

        bytes32 mapKey;
        uint8 mapKeyLen;
        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, mapKeyLen) = cborData.String32(byteIdx, 9);
            if (
                // subject field is the subject of a like.
                mapKeyLen == 7 && bytes7(mapKey) == "subject"
            ) {
                (byteIdx, feedLikeSubject) = cborData.RepoStrongRef(byteIdx);
            } else if (
                // $type field should be "app.bsky.feed.like"
                mapKeyLen == 5 && bytes5(mapKey) == "$type"
            ) {
                bytes32 _type;
                uint8 itemLen;
                (byteIdx, _type, itemLen) = cborData.String32(byteIdx, 18);
                require(itemLen == 18 && bytes18(_type) == nsid, "unexpected record $type");
            } else if (
                // createdAt string unused
                mapKeyLen == 9 && bytes9(mapKey) == "createdAt"
            ) {
                // createdAt is arbitrary user-defined data. the useful and
                // verifiable timestamp is the commit's repo revision field
                byteIdx = cborData.skipString(byteIdx);
            } else {
                revert("unexpected record key");
            }
        }
        cborData.requireComplete(byteIdx);

        return feedLikeSubject;
    }
}
