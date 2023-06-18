// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBondly {
    error AlreadyAllowed(address _currency);
    error InvalidBalanceAmount();
    error InvalidSizeLimit();
    error InvalidZeroAddress();
    error NotEnoughToPayFee(uint256 _fee);
    error ProjectNotFound(bytes32 _hash_id);
    error Unauthorized();
    error UnavailableCurrency(address _currency);
}