// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";
import "../src/CidCbor.sol";

contract CidCborTest {
    bytes private constant cidCbor =
        hex"D82A5825000171122066DA6655BF8DA79B69A87299CF170FED8497FA3059379DC4A8BFE1E28CAB5D93";

    function test_readCidIndex_only() public pure {
        CidCbor.readCidIndex(cidCbor, 0);
    }

    function test_readCidIndex_readCidBytes32() public pure {
        (CidCbor.CidIndex cidIdx, uint byteIdx) = CidCbor.readCidIndex(cidCbor, 0);
        require(byteIdx == cidCbor.length, "expected to read all bytes");

        CidCbor.CidBytes32 cid = CidCbor.readCidBytes32(cidCbor, cidIdx);
        console.logBytes32(CidCbor.CidBytes32.unwrap(cid));
    }
}
