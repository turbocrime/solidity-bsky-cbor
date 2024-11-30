// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";
import "../src/CidCbor.sol";

contract CidCborTest is Test {
    bytes private constant cidCbor =
        hex"D82A5825000171122066DA6655BF8DA79B69A87299CF170FED8497FA3059379DC4A8BFE1E28CAB5D93";

    function test_readCid_only() public pure {
        CidCbor.readCid(cidCbor, 0);
    }
}
