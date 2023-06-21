// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// import "./interfaces/IBondly.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

abstract contract ERC4626Stakable {

    /// The address is the _allowedCurrency.
    /// The IERC4626 is the default staking integration for the currency.
    mapping(IERC20 => IERC4626) public stakingService;

    /// The bytes32 are the Bondly Project ID.
    mapping(bytes32 => mapping(IERC4626 => uint256)) public projectStBalance;

    function totalStakedAmount(IERC20 _allowedCurrency) public view returns (uint256) {
        IERC4626 _staking = stakingService[_allowedCurrency];
        return _staking.balanceOf(address(this));
    }

    // *********************
    // * Virtual Functions *
    // *********************

    function stakeIdleFunds(uint256 _amount, IERC20 _allowedCurrency) public virtual;
}