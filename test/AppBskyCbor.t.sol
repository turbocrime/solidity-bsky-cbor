// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborRead.sol";
import "../src/AppBskyCbor.sol";

contract AppBskyCborTest is Test {
    bytes private constant recordCbor =
        hex"a4647465787478196361722066696c65732063616e6e6f74206875727420796f75652474797065726170702e62736b792e666565642e706f7374656c616e67738162656e696372656174656441747818323032342d31312d31355431323a31303a33322e3031345a";

    string private constant expectedText = "car files cannot hurt you";

    function test_readRecord_only() public pure {
        AppBsky.FeedPost(recordCbor);
    }

    function test_readRecord_valid() public pure {
        AppBskyFeedPost memory post = AppBsky.FeedPost(recordCbor);
        require(keccak256(abi.encode(post.text)) == keccak256(abi.encode(expectedText)), "text mismatch");
    }
}
