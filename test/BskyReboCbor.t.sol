// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";
import "../src/CommitCbor.sol";
contract BskyRepoCBORTest {
    function test_readCommit() public pure {
        bytes memory rootCommitData = hex"a56364696478206469643a706c633a6d74713365346d67743777796a6868616e69657a656a3637637265766d336c61796b6c746f73703232716464617461d82a5825000171122066da6655bf8da79b69a87299cf170fed8497fa3059379dc4a8bfe1e28cab5d936470726576f66776657273696f6e03";

        (CommitCbor.Commit memory commit, uint byteIdx) = CommitCbor.readCommit(rootCommitData, 0);

        console.log("byteIdx: %s", byteIdx);
        console.log("did: %s", commit.did);
        console.log("version: %s", commit.version);
        console.log("rev: %s", commit.rev);
    }
}