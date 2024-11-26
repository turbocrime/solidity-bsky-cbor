// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "../src/CborDecode.sol";
import "../src/CommitCbor.sol";

contract CommitCborTest {
    bytes private constant rootCommitData =
        hex"a56364696478206469643a706c633a6d74713365346d67743777796a6868616e69657a656a3637637265766d336c61796b6c746f73703232716464617461d82a5825000171122066da6655bf8da79b69a87299cf170fed8497fa3059379dc4a8bfe1e28cab5d936470726576f66776657273696f6e03";

    uint256 private constant expectCommitDataCidHash =
        uint256(bytes32(hex"66da6655bf8da79b69a87299cf170fed8497fa3059379dc4a8bfe1e28cab5d93"));

    function test_readCommit_only() public pure {
        CommitCbor.readCommit(rootCommitData, 0);
    }

    function test_readCommit_valid() public pure {
        (CommitCbor.Commit memory commit, uint byteIdx) = CommitCbor.readCommit(rootCommitData, 0);

        require(byteIdx == rootCommitData.length, "expected to read all bytes");
        require(commit.version == 3, "expected version 3");
        require(bytes(commit.rev).length == 13, "expected rev to be 13 bytes");
        require(bytes(commit.did).length == 32, "expected did to be 32 bytes");
        require(CidCbor.Cid.unwrap(commit.data) != 0, "expected data cid to be non-null");
        require(CidCbor.Cid.unwrap(commit.data) == expectCommitDataCidHash, "expected cid hash");
    }
}
