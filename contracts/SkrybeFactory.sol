// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Create2.sol";
import "solady/src/utils/ECDSA.sol";
import "./SkrybeCollection.sol";
import "./lib/SkrybeLib.sol";

contract SkrybeFactory {
    error InvalidFeeProvided();
    error InvalidCreationSignature();
    error InvalidEditSignature();
    error MustOwnCollection();

    event CollectionCreated(
        address indexed _creator,
        address indexed _contract,
        string _collectionId
    );

    uint256 collectionNonce = 0;
    uint256 public BASE_FEE = 0.0005 * 1 ether;

    mapping(uint256 => address) collections;

    address private owner;
    address private signer;
    address private ethscriber;

    constructor(address _signer, address _ethscriber) {
        owner = msg.sender;
        signer = _signer;
        ethscriber = _ethscriber;
    }

    function createCollection(
        CollectionParams calldata collectionParams,
        uint256 ethscriptionBaseFee,
        bytes calldata signature
    ) external {
        bytes32 message = keccak256(
            abi.encode(msg.sender, collectionParams.collectionId, "CREATE")
        );
        if (
            ECDSA.recover(ECDSA.toEthSignedMessageHash(message), signature) !=
            signer
        ) {
            revert InvalidCreationSignature();
        }

        collectionNonce++;

        SkrybeCollection collection = new SkrybeCollection(
            collectionParams,
            BASE_FEE,
            ethscriptionBaseFee,
            msg.sender,
            signer,
            ethscriber,
            owner
        );
        collections[collectionNonce] = address(collection);

        emit CollectionCreated(
            msg.sender,
            address(collection),
            collectionParams.collectionId
        );
    }
}
