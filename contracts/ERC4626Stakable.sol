// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// import "./interfaces/IBondly.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

abstract contract ERC4626Stakable {

    error StakingNotActive(IERC20 _allowedCurrency);
    error StakingNotExists(IERC20 _allowedCurrency);

    struct StakingService {
        IERC4626 staking;
        bool active;
        bool exists;
    }

    /// The address is the _allowedCurrency.
    /// The IERC4626 is the default staking integration for the currency.
    mapping(IERC20 => StakingService) public stakingService;

    /// The bytes32 are the Bondly Project ID.
    // mapping(bytes32 => mapping(IERC4626 => uint256)) public projectStBalance;
    mapping(bytes32 => uint256) public projectStBalance;

    function getStakingService(IERC20 _allowedCurrency) public view returns (IERC4626) {
        StakingService memory _service = stakingService[_allowedCurrency];
        if (!_service.exists) { revert StakingNotExists(_allowedCurrency); }
        return _service.staking;
    }

    function getActiveStakingService(
        IERC20 _allowedCurrency
    ) public view returns (IERC4626) {
        StakingService memory _service = stakingService[_allowedCurrency];
        if (!_service.exists) { revert StakingNotExists(_allowedCurrency); }
        if (!_service.active) { revert StakingNotActive(_allowedCurrency); }
        return _service.staking;
    }

    function totalStakedAmount(IERC20 _allowedCurrency) public view returns (uint256) {
        IERC4626 _staking = getStakingService(_allowedCurrency);
        return _staking.balanceOf(address(this));
    }

    // *********************
    // * Virtual Functions *
    // *********************

    function stakeByDeposit(uint256 _amount, string memory _projectSlug) public virtual;
    function stakeByMint(uint256 _shares, string memory _projectSlug) public virtual;
    function unstakeByWithdraw(uint256 _amount, string memory _projectSlug) public virtual;
    function unstakeByRedeem(uint256 _shares, string memory _projectSlug) public virtual;
}