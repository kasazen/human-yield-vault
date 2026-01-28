// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICommonEvents {
    event Rebalance(string indexed protocol, uint256 amount, string reason, uint256 timestamp);
    event YieldHarvested(uint256 amount, uint256 newTotalAssets, uint256 newAPY, uint256 timestamp);
    event UserDeposit(address indexed user, uint256 amount, uint256 lockExpires);
    event UserWithdraw(address indexed user, uint256 amount);
    event DailyCheckIn(address indexed user, uint256 pointsEarned, uint256 newTotalPoints);
}
