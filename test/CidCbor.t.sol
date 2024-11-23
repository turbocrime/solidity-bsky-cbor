// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";
import "../src/CidCbor.sol";

contract CidCborTest is Test {
    bytes private constant cidCbor =
        hex"D82A5825000171122066DA6655BF8DA79B69A87299CF170FED8497FA3059379DC4A8BFE1E28CAB5D93";

    function test_readCidIndex_only() public pure {
        CidCbor.readCidIndex(cidCbor, 0);
    }

    function test_readCidBytes32_only() public pure {
        CidCbor.readCidBytes32(cidCbor, CidCbor.CidIndex.wrap(9));
    }
}
