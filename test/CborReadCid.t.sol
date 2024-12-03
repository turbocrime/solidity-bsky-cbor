// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborRead.sol";
import "../src/CborReadCid.sol";

using CborRead for bytes;
using CborReadCid for bytes;

contract CborReadCidTest is Test {
    bytes private constant cidCbor =
        hex"D82A5825000171122066DA6655BF8DA79B69A87299CF170FED8497FA3059379DC4A8BFE1E28CAB5D93";

    function test_CborCursor_Cid() internal pure {
        (uint i, CidSha256 cid) = cidCbor.Cid(0);
        cidCbor.requireComplete(i);
        require(
            CidSha256.unwrap(cid)
                == uint256(bytes32(hex"66DA6655BF8DA79B69A87299CF170FED8497FA3059379DC4A8BFE1E28CAB5D93")),
            "cid is incorrect"
        );
    }
}
