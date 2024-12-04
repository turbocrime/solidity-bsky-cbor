// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../../src/records/app/bsky/FeedLike.sol";
import "../../src/records/com/atproto/RepoStrongRef.sol";

using ReadCbor for bytes;

contract ReadAppBskyFeedLike_Test is Test {
    bytes private constant recordCbor =
        hex"a3652474797065726170702e62736b792e666565642e6c696b65677375626a656374a263636964783b626166797265696861366c616b33356273666332726a6c686d69796b35776c67777a7075657335696661616c3274377336646c64357a32356c757163757269784661743a2f2f6469643a706c633a696137366b766e6e646a757467656467677832696272656d2f6170702e62736b792e666565642e706f73742f336c6368716775667a72733367696372656174656441747818323032342d31322d30345430383a33313a31362e3435375a";

    string private constant expectedCid = "bafyreiha6lak35bsfc2rjlhmiyk5wlgwzpues5ifaal2t7s6dld5z25luq";
    string private constant expectedUri = "at://did:plc:ia76kvnndjutgedggx2ibrem/app.bsky.feed.post/3lchqgufzrs3g";

    function test_readRecord_only() public pure {
        ReadAppBskyFeedLike.FeedLike(recordCbor);
    }

    function test_readRecord_valid() public pure {
        ComAtprotoRepoStrongRef memory subject = ReadAppBskyFeedLike.FeedLike(recordCbor);
        require(keccak256(abi.encode(subject.cid)) == keccak256(abi.encode(expectedCid)), "cid mismatch");
        require(keccak256(abi.encode(subject.uri)) == keccak256(abi.encode(expectedUri)), "uri mismatch");
    }
}
