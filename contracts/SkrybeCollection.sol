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

    uint256 private constant _TOTAL_SUPPLY_SLOT = 0x05345cdf77eb68f44c;

    CollectionParams COLLECTION_SETTINGS;

    uint256 SKRYBE_BASE_FEE;
    uint256 ETHSCRIPTION_BASE_FEE;

    bool IS_PAUSED;

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
        if (block.timestamp < COLLECTION_SETTINGS.launchTimestamp) {
            revert CollectionNotLaunched();
        }
        if (
            msg.value !=
            ((COLLECTION_SETTINGS.price +
                ETHSCRIPTION_BASE_FEE +
                SKRYBE_BASE_FEE) * amount)
        ) {
            revert InvalidFeeProvided();
        }
        if (
            (totalSupply() + amount > COLLECTION_SETTINGS.maxSupply) ||
            (COLLECTION_SETTINGS.maxPerTxn > 0 &&
                amount > COLLECTION_SETTINGS.maxPerTxn) ||
            (COLLECTION_SETTINGS.maxPerWallet > 0 &&
                numberMinted[msg.sender] + amount >
                COLLECTION_SETTINGS.maxPerWallet)
        ) {
            revert RequestingTooMany();
        }

        (bool success, ) = address(ETHSCRIBER_ADDRESS).call{
            value: (SKRYBE_BASE_FEE + ETHSCRIPTION_BASE_FEE) * amount
        }("");
        if (!success) {
            revert FailedToTransfer();
        }

        emit Mint(msg.sender, totalSupply(), amount);

        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(_TOTAL_SUPPLY_SLOT, amount)
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`
                revert(0x1c, 0x04)
            }
            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
        }

        unchecked {
            numberMinted[msg.sender] += amount;
        }
    }

    function whitelistMint(
        uint256 amount,
        bytes calldata signature
    ) external payable {
        if (block.timestamp < COLLECTION_SETTINGS.whitelistLaunchTimestamp) {
            revert CollectionNotLaunched();
        }
        if (amount + totalSupply() > COLLECTION_SETTINGS.maxSupply) {
            revert RequestingTooMany();
        }
        if (
            COLLECTION_SETTINGS.maxPerWhitelist > 0 &&
            (whitelistMints[msg.sender] + amount >
                COLLECTION_SETTINGS.maxPerWhitelist)
        ) {
            revert RequestingMoreThanWhitelistAllows();
        }
        bytes32 message = keccak256(
            abi.encode(msg.sender, amount, COLLECTION_SETTINGS.collectionId)
        );

        if (
            msg.value !=
            (amount * COLLECTION_SETTINGS.whitelistPrice) +
                (amount * SKRYBE_BASE_FEE)
        ) {
            revert InvalidFeeProvided();
        }

        if (
            ECDSA.recover(ECDSA.toEthSignedMessageHash(message), signature) !=
            SKRYBE_SIGNER
        ) {
            revert InvalidWhitelistSignature();
        }

        (bool success, ) = address(ETHSCRIBER_ADDRESS).call{
            value: (SKRYBE_BASE_FEE + ETHSCRIPTION_BASE_FEE) * amount
        }("");
        if (!success) {
            revert FailedToTransfer();
        }

        emit Mint(msg.sender, totalSupply(), amount);

        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(_TOTAL_SUPPLY_SLOT, amount)
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`
                revert(0x1c, 0x04)
            }
            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
        }
    }

    function totalSupply() public view returns (uint256 result) {
        assembly {
            result := sload(_TOTAL_SUPPLY_SLOT)
        }
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

    function pauseCollection(bool _state) external onlySuperAdmin {
        IS_PAUSED = _state;
    }
}
