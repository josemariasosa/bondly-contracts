// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IBondlyCore.sol";
import "./interfaces/IStakeController.sol";
import "./mocks/interfaces/IAnkrAvax.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Stake Controller 👩‍✈️ I will stake safely for Bondly Core v0.3
/// @author alpha-centauri.sats 🛰️

contract StakeController is IStakeController, Ownable {
    using SafeERC20 for IERC20;
    // using SafeERC20 for IERC4626;
    // using EnumerableSet for EnumerableSet.Bytes32Set;

    error Unauthorized();
    error NotEnoughBalance();

    bool public active;

    IBondlyCore immutable public core;
    IAnkrAvax immutable public ankrAvax;

    /// @notice this will start a new unstaking process, approx 28 days of duration.
    uint64 public nextUnstakeAvailableAt;

    uint256 private totalToUnstake;

    struct ProjectStakingStatus {
        uint64 unfreezeAt;
        uint256 balanceAvaxAtUnfreeze;
        uint256 balanceAnkrAvax;
    }

    /// @notice ankrAVAX Token Ankr Staked AVAX 🔺
    mapping(bytes32 => ProjectStakingStatus) public stakingStatus;

    modifier onlyCore() {
        if (msg.sender != address(core)) { revert Unauthorized(); }
        _;
    }

    constructor(IBondlyCore _core, IAnkrAvax _ankrAvax) {
        active = true;
        core = _core;
        ankrAvax = _ankrAvax;
    }

    function getCoolingPeriod() public pure returns (uint64) {
        /// TODO: hardcoded 28 days.
        return 28 * 60 * 60 * 24;
    }

    function getStakedBalance(bytes32 _projectId) external view returns (uint256) {
        return stakingStatus[_projectId].balanceAnkrAvax;
    }

    function convertToAssets(uint256 _stBalance) public view returns (uint256) {
        /// TODO:
        uint256 _earnings = 0;
        if (!active) { return 0; }
        return _stBalance + _earnings;
    }

    function isActive() external view returns (bool) {
        return active;
    }

    function createUnstakeOrder(bytes32 _projectHashId, uint256 _shares) external onlyCore {
        ProjectStakingStatus memory _status = stakingStatus[_projectHashId];
        if (_status.balanceAnkrAvax < _shares) { revert NotEnoughBalance(); }

        if (_status.balanceAvaxAtUnfreeze > 0 && _status.unfreezeAt < block.timestamp) {
            _status = _returningAvaxToProject(_projectHashId);
        }
        _status.balanceAvaxAtUnfreeze += convertToAssets(_shares);
        _status.unfreezeAt = nextUnstakeAvailableAt + getCoolingPeriod();
        
        // Storage.
        stakingStatus[_projectHashId] = _status;
    }

    function finishUnstake(bytes32 _projectHashId) external onlyCore {
        stakingStatus[_projectHashId] = _returningAvaxToProject(_projectHashId);
    }

    function startUnstakeProcess() public {
        require(nextUnstakeAvailableAt < block.timestamp);

        uint256 _totalToUnstake = totalToUnstake;
        totalToUnstake = 0;
        nextUnstakeAvailableAt = uint64(block.timestamp) + getCoolingPeriod();

        ankrAvax.claimCerts(_totalToUnstake);
    }

    function stake(bytes32 _projectHashId) external payable onlyCore {

    }

    /// *********************
    /// * Private functions *
    /// *********************

    /// @dev This function returns a status, make sure to save it in storage, if needed.
    function _returningAvaxToProject(bytes32 _projectHashId) private returns (ProjectStakingStatus memory) {
        ProjectStakingStatus memory _status = stakingStatus[_projectHashId];
        require(_status.balanceAvaxAtUnfreeze > 0);
        require(_status.unfreezeAt < block.timestamp);

        uint256 _amountToSend = _status.balanceAvaxAtUnfreeze;
        _status.balanceAvaxAtUnfreeze = 0;

        (bool success, ) = address(core).call{value: msg.value}(
            abi.encodeWithSignature(
                "fundProjectHash(bytes32,uint256)",
                _projectHashId,
                _amountToSend
            )
        );
        require(success);

        return _status;
    }
}