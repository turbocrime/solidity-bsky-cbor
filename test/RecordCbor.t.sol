// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";
import "../src/RecordCbor.sol";

contract RecordCborTest {
    bytes private constant recordCbor =
        hex"a4647465787478196361722066696c65732063616e6e6f74206875727420796f75652474797065726170702e62736b792e666565642e706f7374656c616e67738162656e696372656174656441747818323032342d31312d31355431323a31303a33322e3031345a";

    function test_readRecord_only() public pure {
        RecordCbor.readRecord(recordCbor, 0);
    }

    function test_readRecord_valid() public pure {
        (RecordCbor.Record memory record, uint byteIdx) = RecordCbor.readRecord(recordCbor, 0);
        require(byteIdx == recordCbor.length, "expected to read all bytes");

        console.log("text", record.text);
        console.log("$type", record.dollarType);
    }
}
