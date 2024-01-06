// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct CollectionParams {
    string collectionId;
    uint256 price;
    uint256 whitelistPrice;
    uint256 maxSupply;
    uint256 maxPerTxn;
    uint256 maxPerWhitelist;
    uint256 usesWhitelist;
}
