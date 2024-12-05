// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../../src/records/app/bsky/Feed.sol";
import "../../src/records/com/atproto/Repo.sol";

using ReadCbor for bytes;

contract ReadAppBskyFeed_Test is Test {
    bytes private constant cborFeedLike =
        hex"a3652474797065726170702e62736b792e666565642e6c696b65677375626a656374a263636964783b626166797265696861366c616b33356273666332726a6c686d69796b35776c67777a7075657335696661616c3274377336646c64357a32356c757163757269784661743a2f2f6469643a706c633a696137366b766e6e646a757467656467677832696272656d2f6170702e62736b792e666565642e706f73742f336c6368716775667a72733367696372656174656441747818323032342d31322d30345430383a33313a31362e3435375a";

    string private constant expectedFeedLikeCid = "bafyreiha6lak35bsfc2rjlhmiyk5wlgwzpues5ifaal2t7s6dld5z25luq";
    string private constant expectedFeedLikeUri =
        "at://did:plc:ia76kvnndjutgedggx2ibrem/app.bsky.feed.post/3lchqgufzrs3g";

    function test_readFeedLike_only() public pure {
        AppBsky.readFeedLike(cborFeedLike);
    }

    function test_readFeedLike_valid() public pure {
        ComAtprotoRepo.StrongRef memory like = AppBsky.readFeedLike(cborFeedLike);
        require(keccak256(abi.encode(like.cid)) == keccak256(abi.encode(expectedFeedLikeCid)), "cid mismatch");
        require(keccak256(abi.encode(like.uri)) == keccak256(abi.encode(expectedFeedLikeUri)), "uri mismatch");
    }

    bytes private constant cborFeedPost =
        hex"a4647465787478196361722066696c65732063616e6e6f74206875727420796f75652474797065726170702e62736b792e666565642e706f7374656c616e67738162656e696372656174656441747818323032342d31312d31355431323a31303a33322e3031345a";

    string private constant expectedFeedPostText = "car files cannot hurt you";

    function test_readFeedPost_only() public pure {
        AppBsky.readFeedPost(cborFeedPost);
    }

    function test_readFeedPost_valid() public pure {
        string memory post = AppBsky.readFeedPost(cborFeedPost);
        require(keccak256(abi.encode(post)) == keccak256(abi.encode(expectedFeedPostText)), "text mismatch");
    }

    bytes private constant cborFeedRepost =
        hex"a3652474797065746170702e62736b792e666565642e7265706f7374677375626a656374a263636964783b62616679726569676370786b707a6176717963333274757375376e356f61366f6f71367766646e6b7167733275787268783770746834347077756d63757269784661743a2f2f6469643a706c633a61346c6234337665636361617a786a32747432626c616f772f6170702e62736b792e666565642e706f73742f336c62656f366f6f7567733276696372656174656441747818323032342d31312d32305431323a33383a31362e3232325a";

    string private constant expectedFeedRepostCid = "bafyreigcpxkpzavqyc32tusu7n5oa6ooq6wfdnkqgs2uxrhx7pth44pwum";
    string private constant expectedFeedRepostUri =
        "at://did:plc:a4lb43veccaazxj2tt2blaow/app.bsky.feed.post/3lbeo6oougs2v";

    function test_readFeedRepost_only() public pure {
        AppBsky.readFeedRepost(cborFeedRepost);
    }

    function test_readFeedRepost() public pure {
        ComAtprotoRepo.StrongRef memory repost = AppBsky.readFeedRepost(cborFeedRepost);
        require(keccak256(abi.encode(repost.cid)) == keccak256(abi.encode(expectedFeedRepostCid)), "cid mismatch");
        require(keccak256(abi.encode(repost.uri)) == keccak256(abi.encode(expectedFeedRepostUri)), "uri mismatch");
    }
}
