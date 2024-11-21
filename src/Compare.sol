// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Compare {
    function bytesMatch(bytes memory one, bytes memory other) internal pure returns (bool) {
        return keccak256(abi.encodePacked(one)) == keccak256(abi.encodePacked(other));
    }

    function stringsMatch(string memory one, string memory other) internal pure returns (bool) {
        return keccak256(abi.encodePacked(one)) == keccak256(abi.encodePacked(other));
    }
}
