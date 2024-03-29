// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBondly {
    error AlreadyAllowed(address _currency);
    error InvalidBalanceAmount();
    error InvalidSizeLimit();
    error InvalidZeroAddress();
    error InvalidZeroAmount();
    error NotEnoughBalance();
    error NotEnoughToPayFee(uint256 _fee);
    error NotSuccessfulOperation();
    error ProjectNotFound(bytes32 _hash_id);
    error Unauthorized();
    error InvalidMovementZeroAmount();
    error UnavailableCurrency(address _currency);
    error UnavailableStaking();
    error GenericError();

    struct ProjectJson {
        bytes32 id;

        address[] owners;
        uint32 approvalThreshold;
        address stableAddress;

        uint256 balanceEth;
        uint256 balanceStakedEth;
        uint256 balanceStable;

        /// @notice This amount is an approx representation in Eth.
        uint256 convertedStakedBalance;
        // uint256 convertedStakedBalanceUSD;
        // uint256 convertedEthBalanceUSD;
    }
}