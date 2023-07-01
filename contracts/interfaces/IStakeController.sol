// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IStakeController {

    function getStakedBalance(bytes32 _projectHashId) external view returns (uint256);
    function convertToAssets(uint256 _stBalance) external view returns (uint256);
    function isActive() external view returns (bool);
    function stake(bytes32 _projectHashId) external payable;
    function unStake(bytes32 _projectHashId, uint256 _shares) external payable;

    // error AlreadyAllowed(address _currency);
    // error InvalidBalanceAmount();
    // error InvalidSizeLimit();
    // error InvalidZeroAddress();
    // error NotEnoughBalance();
    // error NotEnoughToPayFee(uint256 _fee);
    // error ProjectNotFound(bytes32 _hash_id);
    // error Unauthorized();
    // error UnavailableCurrency(address _currency);

    // struct ProjectJson {
    //     bytes32 id;

    //     address[] owners;
    //     uint32 approvalThreshold;
    //     address stableAddress;

    //     uint256 balanceAvax;
    //     uint256 balanceStable;

    //     uint256 balanceStakedStable;
    //     uint256 convertedToAvax;
    // }
}