// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommonGate is Ownable {
    mapping(address => bool) public isVerified;
    mapping(address => uint256) public lastDepositTime;
    mapping(address => uint256) public initialDepositTime;
    mapping(address => uint256) public extraPoints;
    mapping(address => uint256) public lastCheckInTime;
    
    uint256 public constant LOCK_DURATION = 24 hours;
    uint256 public constant BOOST_THRESHOLD = 7 days;
    uint256 public constant CHECKIN_COOLDOWN = 20 hours;
    uint256 public constant POINTS_PER_CHECKIN = 10;
    uint256 public constant POINTS_PER_USDC_DAY = 1;

    event VerificationUpdated(address indexed user, bool status);
    event DailyCheckIn(address indexed user, uint256 pointsAdded);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setVerification(address user, bool status) external onlyOwner {
        isVerified[user] = status;
        emit VerificationUpdated(user, status);
    }
    function verifyProof(address user) external view returns (bool) {
        return isVerified[user];
    }
    function registerDeposit(address user) external {
        lastDepositTime[user] = block.timestamp;
        if (initialDepositTime[user] == 0) initialDepositTime[user] = block.timestamp;
    }
    function canWithdraw(address user) external view returns (bool) {
        if (lastDepositTime[user] == 0) return true;
        return block.timestamp >= lastDepositTime[user] + LOCK_DURATION;
    }
    function dailyCheckIn() external {
        require(isVerified[msg.sender], "Common: Must be verified");
        require(block.timestamp >= lastCheckInTime[msg.sender] + CHECKIN_COOLDOWN, "Common: Come back tomorrow");
        lastCheckInTime[msg.sender] = block.timestamp;
        extraPoints[msg.sender] += POINTS_PER_CHECKIN;
        emit DailyCheckIn(msg.sender, POINTS_PER_CHECKIN);
    }
    function calculatePoints(address user, uint256 currentBalance) external view returns (uint256) {
        uint256 total = extraPoints[user];
        if (initialDepositTime[user] != 0 && currentBalance > 0) {
            uint256 secondsHeld = block.timestamp - initialDepositTime[user];
            uint256 daysHeld = secondsHeld / 1 days;
            uint256 holdingPoints = currentBalance * daysHeld * POINTS_PER_USDC_DAY;
            if (secondsHeld >= BOOST_THRESHOLD) holdingPoints = holdingPoints * 3;
            total += holdingPoints;
        }
        return total;
    }
    function isBoostActive(address user) external view returns (bool) {
        if (initialDepositTime[user] == 0) return false;
        return (block.timestamp - initialDepositTime[user]) >= BOOST_THRESHOLD;
    }
}
