// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct CollectionParams {
    string collectionId;
    uint32 launchTimestamp;
    uint32 whitelistLaunchTimestamp;
    uint256 price;
    uint256 whitelistPrice;
    uint32 maxSupply;
    uint32 maxPerTxn;
    uint32 maxPerWhitelist;
    uint32 maxPerWallet;
    uint8 usesWhitelist;
}
