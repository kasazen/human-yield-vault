// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CommonGate.sol";
import "./ICommonEvents.sol";

contract CommonVault is ERC4626, Ownable, ICommonEvents {
    CommonGate public gate;
    uint256 public cumulativeYield;
    uint256 public lastHarvestTime;
    uint256 public currentAPY; 

    constructor(IERC20 _asset, string memory _name, string memory _symbol, address _gate) 
        ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) {
        gate = CommonGate(_gate);
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        require(gate.verifyProof(receiver), "Common: Verified humans only");
        gate.registerDeposit(receiver);
        emit UserDeposit(receiver, assets, block.timestamp + 24 hours);
        return super.deposit(assets, receiver);
    }
    function mint(uint256 shares, address receiver) public override returns (uint256) {
        require(gate.verifyProof(receiver), "Common: Verified humans only");
        gate.registerDeposit(receiver);
        return super.mint(shares, receiver);
    }
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        require(gate.canWithdraw(owner), "Common: Funds locked 24h");
        emit UserWithdraw(owner, assets);
        return super.withdraw(assets, receiver, owner);
    }
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        require(gate.canWithdraw(owner), "Common: Funds locked 24h");
        return super.redeem(shares, receiver, owner);
    }
    function rebalanceStrategy(string memory protocol, uint256 amount, string memory reason) external onlyOwner {
        emit Rebalance(protocol, amount, reason, block.timestamp);
    }
    function harvest(uint256 yieldAmount) external onlyOwner {
        cumulativeYield += yieldAmount;
        lastHarvestTime = block.timestamp;
        if (totalAssets() > 0) {
             currentAPY = (yieldAmount * 52 * 10000) / totalAssets(); 
        }
        emit YieldHarvested(yieldAmount, totalAssets(), currentAPY, block.timestamp);
    }
}
