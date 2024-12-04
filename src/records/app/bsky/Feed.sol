// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../../../repo/ReadCid.sol";
import "../../com/atproto/Repo.sol";

using ReadCbor for bytes;
using ReadCid for bytes;
using ComAtprotoRepo for bytes;

library AppBsky {
    bytes18 internal constant nsidFeedLike = "app.bsky.feed.like";
    bytes18 internal constant nsidFeedPost = "app.bsky.feed.post";

    struct FeedLike {
        ComAtprotoRepo.StrongRef subject;
    }

    struct FeedPost {
        string text;
    }

    function readFeedLike(bytes memory cborData) internal pure returns (FeedLike memory like) {
        (uint byteIdx, uint mapLen) = cborData.Map(0);

        require(mapLen == 3, "unexpected number of fields");

        bytes32 mapKey;
        uint8 mapKeyLen;
        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, mapKeyLen) = cborData.String32(byteIdx, 9);
            if (
                // subject field is the subject of a like.
                mapKeyLen == 7 && bytes7(mapKey) == "subject"
            ) {
                (byteIdx, like.subject) = cborData.readStrongRef(byteIdx);
            } else if (
                // $type field should be "app.bsky.feed.like"
                mapKeyLen == 5 && bytes5(mapKey) == "$type"
            ) {
                bytes32 _type;
                uint8 itemLen;
                (byteIdx, _type, itemLen) = cborData.String32(byteIdx, 18);
                require(itemLen == 18 && bytes18(_type) == nsidFeedLike, "unexpected record type");
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

        return like;
    }

    function readFeedPost(bytes memory cborData) internal pure returns (FeedPost memory post) {
        (uint byteIdx, uint mapLen) = cborData.Map(0);

        require(mapLen == 4, "unexpected number of fields");

        bytes32 mapKey;
        uint8 mapKeyLen;
        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, mapKeyLen) = cborData.String32(byteIdx, 9);
            if (
                // text field is the content of a text post.
                mapKeyLen == 4 && bytes4(mapKey) == "text"
            ) {
                (byteIdx, post.text) = cborData.String(byteIdx);
            } else if (
                // $type field should be "app.bsky.feed.post"
                mapKeyLen == 5 && bytes5(mapKey) == "$type"
            ) {
                bytes32 _type;
                uint8 itemLen;
                (byteIdx, _type, itemLen) = cborData.String32(byteIdx, 18);
                require(itemLen == 18 && bytes18(_type) == nsidFeedPost, "unexpected record type");
            } else if (
                // langs array unused
                mapKeyLen == 5 && bytes5(mapKey) == "langs"
            ) {
                uint langsLength;
                (byteIdx, langsLength) = cborData.Array(byteIdx);
                for (uint j = 0; j < langsLength; j++) {
                    byteIdx = cborData.skipString(byteIdx);
                }
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

        return post;
    }
}
