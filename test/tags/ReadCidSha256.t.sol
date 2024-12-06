// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../../src/tags/ReadCidSha256.sol";

using ReadCbor for bytes;
using ReadCidSha256 for bytes;

contract ReadCidSha256_Test is Test {
    bytes9 private constant dagHead = hex"D82A58250001711220";

    bytes private constant constantCidCbor =
        hex"D82A582500017112200000000000000000000000000000000000000000000000000000000000000001";

    bytes private constant rawCidCbor =
        hex"D82A582500015512200000000000000000000000000000000000000000000000000000000000000001";

    bytes private constant zeroCidCbor =
        hex"D82A582500017112200000000000000000000000000000000000000000000000000000000000000000";

    bytes private constant nullCbor = hex"F6";

    function test_Cid() public pure {
        constantCidCbor.Cid(0);
    }

    function test_NullableCid_nullCbor() public pure {
        (, CidSha256 nullCid) = nullCbor.NullableCid(0);
        assertEq(nullCid.isNull(), true);
    }

    function test_Cid_random(uint256 randomHash) public pure {
        vm.assume(randomHash != 0);
        bytes memory randomCidCbor = abi.encodePacked(dagHead, randomHash);
        (uint32 i, CidSha256 rando) = randomCidCbor.Cid(0);
        randomCidCbor.requireComplete(i);
        assertEq(CidSha256.unwrap(rando), randomHash);
    }

    function test_NullableCid_random(uint256 randomHash) public pure {
        bytes memory randomCidCbor = randomHash != 0 ? abi.encodePacked(dagHead, randomHash) : nullCbor;
        (uint32 i, CidSha256 rando) = randomCidCbor.NullableCid(0);
        randomCidCbor.requireComplete(i);
        if (randomHash == 0) {
            assertEq(rando.isNull(), true);
        } else {
            assertEq(CidSha256.unwrap(rando), randomHash);
        }
    }

    function testFail_Cid_zeroCidCbor() public pure {
        zeroCidCbor.Cid(0);
    }

    function testFail_Cid_nullCbor() public pure {
        nullCbor.Cid(0);
    }

    function testFail_Cid_NullableCid_zeroes() public pure {
        zeroCidCbor.NullableCid(0);
    }

    function test_Cid_multicodec_raw() public pure {
        rawCidCbor.Cid(0, 0x55);
    }
}
