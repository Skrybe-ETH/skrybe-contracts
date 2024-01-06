// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {CollectionParams} from "../lib/SkrybeLib.sol";

interface ISkrybeCollection {
    event Mint(
        address indexed _minter,
        uint256 indexed startId,
        uint256 indexed amount
    );

    function mint(uint256 amount) external payable;

    function whitelistMint(
        uint256 amount,
        bytes calldata signature
    ) external payable;

    function totalSupply() external view returns (uint256);

    function editCollection(
        CollectionParams calldata collectionParams
    ) external;

    function withdraw() external;

    function setSkrybeSigner(address _signer) external;

    function setEthscriberAddress(address _ethscriber) external;

    function transferSuperAdmin(address _super) external;

    function pauseCollection(bool _state) external;
}
