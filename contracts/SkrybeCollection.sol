// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "solady/src/utils/ECDSA.sol";
import "./lib/SkrybeLib.sol";

/// @title SkrybeCollection V1
/// @author Max Bridgland <@maxbridgland>
/// @notice This contract is expected to be used alongside the SkrybeFactory
contract SkrybeCollection {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev Sender is requesting more than MAX_PER_TXN allows.
    error RequestingMoreThanWhitelistAllows();

    /// @dev Signature provided to whitelistMint function is invalid.
    error InvalidWhitelistSignature();

    /// @dev msg.value does not meet required value.
    error InvalidFeeProvided();

    /// @dev Requesting to mint more than allowed per transaction, or sold out.
    error RequestingTooMany();

    /// @dev Failed to transfer Ethscription fee for ethscribing.
    error FailedToTransfer();

    /// @dev Collection has not launched yet.
    error CollectionNotLaunched();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM EVENTS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event Mint(
        address indexed _minter,
        uint256 indexed startId,
        uint256 indexed amount
    );

    uint256 public TOTAL_SUPPLY = 0;

    CollectionParams public COLLECTION_SETTINGS;

    uint256 SKRYBE_BASE_FEE;
    uint256 ETHSCRIPTION_BASE_FEE;

    uint8 IS_PAUSED = 1;

    address OWNER;
    address SKRYBE_SIGNER;
    address ETHSCRIBER_ADDRESS;
    address SUPER_ADMIN;

    string COLLECTION_ID;

    mapping(address => bool) ADMINS;
    mapping(address => uint256) whitelistMints;
    mapping(address => uint256) numberMinted;
    mapping(uint256 setting => uint256 value) collectionSettings;

    modifier onlySuperAdmin() {
        require(msg.sender == SUPER_ADMIN, "Must be super administrator.");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == OWNER || ADMINS[msg.sender],
            "Must be owner or admin."
        );
        _;
    }

    constructor(
        CollectionParams memory _collectionParams,
        uint256 _SKRYBE_BASE_FEE,
        uint256 _ETHSCRIPTION_BASE_FEE,
        address _OWNER,
        address _SIGNER,
        address _ETHSCRIBER_ADDRESS,
        address _SUPER_ADMIN
    ) {
        COLLECTION_SETTINGS = _collectionParams;
        SKRYBE_BASE_FEE = _SKRYBE_BASE_FEE;
        ETHSCRIPTION_BASE_FEE = _ETHSCRIPTION_BASE_FEE;
        OWNER = _OWNER;
        SKRYBE_SIGNER = _SIGNER;
        ETHSCRIBER_ADDRESS = _ETHSCRIBER_ADDRESS;
        SUPER_ADMIN = _SUPER_ADMIN;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PUBLIC FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function mint(uint256 amount) external payable {
        CollectionParams memory _collectionParams = COLLECTION_SETTINGS;

        if (
            block.timestamp < _collectionParams.launchTimestamp ||
            IS_PAUSED == 2
        ) {
            revert CollectionNotLaunched();
        }

        uint256 ethscriptionFee = (SKRYBE_BASE_FEE + ETHSCRIPTION_BASE_FEE) *
            amount;
        uint256 totalPrice = (_collectionParams.price * amount) +
            ethscriptionFee;

        if (msg.value != totalPrice) {
            revert InvalidFeeProvided();
        }
        if (
            (TOTAL_SUPPLY + amount > _collectionParams.maxSupply) ||
            (_collectionParams.maxPerTxn > 0 &&
                amount > _collectionParams.maxPerTxn) ||
            (_collectionParams.maxPerWallet > 0 &&
                numberMinted[msg.sender] + amount >
                _collectionParams.maxPerWallet)
        ) {
            revert RequestingTooMany();
        }

        (bool success, ) = address(ETHSCRIBER_ADDRESS).call{
            value: ethscriptionFee
        }("");
        if (!success) {
            revert FailedToTransfer();
        }

        emit Mint(msg.sender, TOTAL_SUPPLY, amount);

        unchecked {
            TOTAL_SUPPLY += amount;
        }

        if (_collectionParams.maxPerWallet != 0) {
            unchecked {
                numberMinted[msg.sender] += amount;
            }
        }
    }

    function whitelistMint(
        uint256 amount,
        bytes calldata signature
    ) external payable {
        CollectionParams memory _collectionParams = COLLECTION_SETTINGS;

        if (
            block.timestamp < _collectionParams.whitelistLaunchTimestamp ||
            IS_PAUSED == 2
        ) {
            revert CollectionNotLaunched();
        }
        if (amount + TOTAL_SUPPLY > _collectionParams.maxSupply) {
            revert RequestingTooMany();
        }
        if (
            _collectionParams.maxPerWhitelist > 0 &&
            (whitelistMints[msg.sender] + amount >
                _collectionParams.maxPerWhitelist)
        ) {
            revert RequestingMoreThanWhitelistAllows();
        }
        bytes32 message = keccak256(
            abi.encode(msg.sender, amount, _collectionParams.collectionId)
        );

        uint256 ethscriptionFee = (SKRYBE_BASE_FEE + ETHSCRIPTION_BASE_FEE) *
            amount;
        uint256 totalPrice = (_collectionParams.whitelistPrice * amount) +
            ethscriptionFee;

        if (msg.value != totalPrice) {
            revert InvalidFeeProvided();
        }

        if (
            ECDSA.recover(ECDSA.toEthSignedMessageHash(message), signature) !=
            SKRYBE_SIGNER
        ) {
            revert InvalidWhitelistSignature();
        }

        (bool success, ) = address(ETHSCRIBER_ADDRESS).call{
            value: ethscriptionFee
        }("");
        if (!success) {
            revert FailedToTransfer();
        }

        emit Mint(msg.sender, TOTAL_SUPPLY, amount);

        unchecked {
            TOTAL_SUPPLY += amount;
        }

        if (_collectionParams.maxPerWhitelist > 0) {
            unchecked {
                whitelistMints[msg.sender] += amount;
            }
        }
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ADMIN FUNCTIONS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function editCollection(
        CollectionParams calldata collectionParams
    ) external onlyOwnerOrAdmin {
        COLLECTION_SETTINGS = collectionParams;
    }

    function withdraw() external onlyOwnerOrAdmin {
        (bool success, ) = address(OWNER).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert FailedToTransfer();
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   SUPER ADMIN FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function setSkrybeSigner(address _signer) external onlySuperAdmin {
        SKRYBE_SIGNER = _signer;
    }

    function setEthscriberAddress(address _ethscriber) external onlySuperAdmin {
        ETHSCRIBER_ADDRESS = _ethscriber;
    }

    function transferSuperAdmin(address _super) external onlySuperAdmin {
        SUPER_ADMIN = _super;
    }

    function pauseCollection(uint8 _state) external onlySuperAdmin {
        IS_PAUSED = _state;
    }
}
