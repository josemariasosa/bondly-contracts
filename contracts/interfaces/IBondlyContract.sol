// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBondlyContract {
    error InvalidZeroAddress();
    error AlreadyAllowed(address _currency);
    error InvalidSizeLimit();
    error InvalidBalanceAmount();
    error UnavailableCurrency(address _currency);
    error ProjectNotFound(bytes32 _hash_id);
}