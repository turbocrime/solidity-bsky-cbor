// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "./CidCbor.sol";

struct AppBskyFeedPost {
    string text;
}

library AppBsky {
    using CBORDecoder for bytes;

    bytes19 private constant nsidFeedPost = "app.bsky.feed.post";

    function FeedPost(bytes memory cborData) internal pure returns (AppBskyFeedPost memory feedPost) {
        uint byteIdx = 0;
        (feedPost.text, byteIdx) = FeedPost(cborData, byteIdx);
        require(byteIdx == cborData.length, "expected to read all bytes");
        return feedPost;
    }

    function FeedPost(bytes memory cborData, uint byteIdx) internal pure returns (string memory feedPostText, uint) {
        uint mapLen;
        (mapLen, byteIdx) = cborData.readFixedMap(byteIdx);

        require(mapLen == 4, "expected 4 fields in `app.bsky.feed.post` record");

        bytes9 mapKey;
        for (uint mapIdx = 0; mapIdx < mapLen; mapIdx++) {
            (mapKey, byteIdx) = cborData.readStringBytes9(byteIdx);
            if (
                // text field is the content of a text post.
                bytes5(mapKey) == "text"
            ) {
                (feedPostText, byteIdx) = cborData.readString(byteIdx);
            } else if (
                // $type field should be "app.bsky.feed.post"
                bytes6(mapKey) == "$type"
            ) {
                bytes memory dollarType;
                (dollarType, byteIdx) = cborData.readStringBytes(byteIdx);
                require(bytes19(bytes(dollarType)) == nsidFeedPost, "unexpected record $type");
            } else if (
                // langs array unused
                bytes6(mapKey) == "langs"
            ) {
                uint langsLength;
                (langsLength, byteIdx) = cborData.readFixedArray(byteIdx);
                for (uint j = 0; j < langsLength; j++) {
                    byteIdx = cborData.skipString(byteIdx);
                }
            } else if (
                // createdAt string unused
                bytes9(mapKey) == "createdAt"
            ) {
                // createdAt is arbitrary user-defined data. the useful and
                // verifiable timestamp is the commit's repo revision field
                byteIdx = cborData.skipString(byteIdx);
            } else {
                revert("unexpected record key");
            }
        }

        return (feedPostText, byteIdx);
    }
}
