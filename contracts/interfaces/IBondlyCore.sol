// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBondlyCore {
    error AlreadyAllowed(address _currency);
    error InvalidBalanceAmount();
    error InvalidSizeLimit();
    error InvalidZeroAddress();
    error NotEnoughBalance();
    error NotEnoughToPayFee(uint256 _fee);
    error ProjectNotFound(bytes32 _hash_id);
    error Unauthorized();
    error UnavailableCurrency(address _currency);

    error Inaccessible();

    struct ProjectJson {
        bytes32 id;

        address[] owners;
        uint32 approvalThreshold;
        address stableAddress;

        uint256 balanceAvax;
        uint256 balanceStable;

        ///@notice convertedToAvax gets the price in AVAX.
        uint256 convertedToAvax;
        uint256 balanceStakedAvax;
    }
}