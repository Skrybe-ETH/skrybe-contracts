// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {CollectionParams} from "../lib/SkrybeLib.sol";

interface ISkrybeFactory {
    event CollectionCreated(
        address indexed _creator,
        address indexed _contract,
        uint256 indexed _collectionId
    );

    event CollectionMinted(
        uint256 indexed _collectionId,
        address indexed _minter,
        uint256 indexed _startId,
        uint256 _amount
    );

    function createCollection(
        CollectionParams calldata collectionParams,
        string calldata encodedParams,
        bytes calldata signature
    ) external payable;

    function getCollectionAddress(
        uint256 collectionId
    ) external view returns (address);

    function setBaseFee(uint256 price) external;

    function setSigner(address _signer) external;

    function setEthscriber(address _ethscriber) external;

    function setSignerForCollectionInBatch(uint256 start, uint256 end) external;

    function setEthscriberForCollectionInBatch(
        uint256 start,
        uint256 end
    ) external;

    function setSuperAdminForCollectionInBatch(
        uint256 start,
        uint256 end
    ) external;
}
