// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableRoles.sol";
import "./ContextUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./OperatorFilterer.sol";
import "./IBaseCollection.sol";
import "./INiftyKit.sol";

abstract contract OFBaseCollection is
    OwnableRoles,
    OperatorFilterer,
    ContextUpgradeable,
    ERC2981Upgradeable,
    IBaseCollection
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 public constant ADMIN_ROLE = 1 << 0;
    uint256 public constant MANAGER_ROLE = 1 << 1;
    uint256 public constant BURNER_ROLE = 1 << 2;

    INiftyKit internal _niftyKit;
    address internal _treasury;
    uint256 internal _totalRevenue;

    // Operator Filtering
    bool internal operatorFilteringEnabled;

    function __BaseCollection_init(
        address owner_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) internal onlyInitializing {
        _initializeOwner(owner_);
        __ERC2981_init();
        _registerForOperatorFiltering();

        _niftyKit = INiftyKit(_msgSender());
        _treasury = treasury_;
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function withdraw() external onlyRolesOrOwner(ADMIN_ROLE) {
        require(address(this).balance > 0, "0 balance");

        INiftyKit niftyKit = _niftyKit;
        uint256 balance = address(this).balance;
        uint256 fees = niftyKit.getFees(address(this));
        niftyKit.addFeesClaimed(fees);
        AddressUpgradeable.sendValue(payable(address(niftyKit)), fees);
        AddressUpgradeable.sendValue(payable(_treasury), balance.sub(fees));
    }

    function setTreasury(address newTreasury)
        external
        onlyRolesOrOwner(ADMIN_ROLE)
    {
        _treasury = newTreasury;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRolesOrOwner(ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value)
        public
        onlyRolesOrOwner(ADMIN_ROLE)
    {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function totalRevenue() external view returns (uint256) {
        return _totalRevenue;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IBaseCollection).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}