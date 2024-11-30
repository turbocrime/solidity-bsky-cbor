// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "./src/CommitCbor.sol";
import "./src/TreeCbor.sol";

contract ExampleContract {
    using {CommitCbor.verifyCommit} for bytes;
    using {TreeCbor.readTree} for bytes[];
    using {TreeCbor.verifyInclusion} for Tree;

    string private lastRev;
    address private trustedSigner;

    constructor(string memory initRev, address initSigner) {
        lastRev = initRev;
        trustedSigner = initSigner;
    }

    function exampleUse(
        bytes calldata commitCbor,
        bytes calldata recordCbor,
        bytes[] calldata mstCbors,
        bytes32 sig_r,
        bytes32 sig_s,
        string calldata recordKey
    ) external {
        Commit memory commit = commitCbor.verifyCommit(sig_r, sig_s, trustedSigner, lastRev);
        Tree memory mst = mstCbors.readTree();
        Cid valueCid = mst.verifyInclusion(commit.data, recordKey);
        require(valueCid.isFor(recordCbor), "Key identifies a different record");

        lastRev = commit.rev;
        exampleAction(recordCbor);
    }

    function exampleAction(bytes calldata recordCbor) internal pure {
        /* no-op */
    }
}
