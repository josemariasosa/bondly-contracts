// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MOCK for ANKR Staking Interface
/// @author alpha-centauri.sats 🛰️

contract AnkrAvax {
    using SafeERC20 for IERC20;
    // using SafeERC20 for IERC4626;
    // using EnumerableSet for EnumerableSet.Bytes32Set;

    error NotEnoughBalance();

    struct pendingClaimCert {
        /// Timestamp in seconds.
        uint64 availableAt;
        uint256 amount;
    }

    mapping(address => pendingClaimCert) public pendingClaimCerts;
    mapping(address => uint256) public balanceAnkrAvax;

    uint256 public totalAvax;
    uint256 public totalAnkrAvax;

    function claimCerts(uint256 _amount) external {
        uint256 _balance = balanceAnkrAvax[msg.sender];
        if (_balance < _amount) { revert NotEnoughBalance(); }

    }

}

