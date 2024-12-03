// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import "./CborRead.sol";
import "./CborReadCid.sol";

using CborRead for bytes;
using CborReadCid for bytes;

struct AppBskyFeedPost {
    string text;
}

library AppBsky {
    bytes18 private constant nsidFeedPost = "app.bsky.feed.post";

    function FeedPost(bytes memory cborData) internal pure returns (AppBskyFeedPost memory feedPost) {
        uint byteIdx = 0;
        (byteIdx, feedPost.text) = FeedPost(cborData, byteIdx);
        cborData.requireComplete(byteIdx);
        return feedPost;
    }

    function FeedPost(bytes memory cborData, uint byteIdx) internal pure returns (uint, string memory feedPostText) {
        uint mapLen;
        (byteIdx, mapLen) = cborData.Map(byteIdx);

        require(mapLen == 4, "expected 4 fields in `app.bsky.feed.post` record");

        bytes32 mapKey;
        uint8 mapKeyLen;
        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (byteIdx, mapKey, mapKeyLen) = cborData.String32(byteIdx, 9);
            if (
                // text field is the content of a text post.
                mapKeyLen == 4 && bytes4(mapKey) == "text"
            ) {
                (byteIdx, feedPostText) = cborData.String(byteIdx);
            } else if (
                // $type field should be "app.bsky.feed.post"
                mapKeyLen == 5 && bytes5(mapKey) == "$type"
            ) {
                bytes32 dollarType;
                uint8 dollarTypeLen;
                (byteIdx, dollarType, dollarTypeLen) = cborData.String32(byteIdx, 18);
                require(dollarTypeLen == 18 && bytes18(dollarType) == nsidFeedPost, "unexpected record $type");
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

        return (byteIdx, feedPostText);
    }
}
