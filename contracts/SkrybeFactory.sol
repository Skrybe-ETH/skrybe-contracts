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
    error LaunchMustBeInFuture();

    event CollectionCreated(
        address indexed _creator,
        address indexed _contract,
        string _collectionId
    );

    uint256 public BASE_FEE = 0.0005 * 1 ether;

    mapping(string => address) public collections;

    address private owner;
    address private signer;
    address private ethscriber;

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }

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

        if (collectionParams.launchTimestamp <= block.timestamp) {
            revert LaunchMustBeInFuture();
        }

        SkrybeCollection collection = new SkrybeCollection(
            collectionParams,
            BASE_FEE,
            ethscriptionBaseFee,
            msg.sender,
            signer,
            ethscriber,
            owner
        );
        collections[collectionParams.collectionId] = address(collection);

        emit CollectionCreated(
            msg.sender,
            address(collection),
            collectionParams.collectionId
        );
    }

    function setBaseFee(uint256 _baseFee) external onlyOwner {
        BASE_FEE = _baseFee;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setEthscriber(address _ethscriber) external onlyOwner {
        ethscriber = _ethscriber;
    }
}
