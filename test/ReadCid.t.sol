// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../../src/repo/ReadCid.sol";

using ReadCbor for bytes;
using ReadCid for bytes;

contract ReadCid_Test is Test {
    bytes private constant cidCbor =
        hex"D82A5825000171122066DA6655BF8DA79B69A87299CF170FED8497FA3059379DC4A8BFE1E28CAB5D93";
    uint256 private constant expectedHash =
        uint256(bytes32(hex"66DA6655BF8DA79B69A87299CF170FED8497FA3059379DC4A8BFE1E28CAB5D93"));

    function test_Cid_only() internal pure {
        cidCbor.Cid(0);
    }

    function test_Cid_valid() internal pure {
        (uint i, CidSha256 cid) = cidCbor.Cid(0);
        cidCbor.requireComplete(i);
        assertEq(CidSha256.unwrap(cid), expectedHash);
    }
}
