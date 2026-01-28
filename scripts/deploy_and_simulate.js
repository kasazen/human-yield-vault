const hre = require("hardhat");

async function main() {
  console.log("🚀 Starting Common Protocol (Local Mode)...");
  const [deployer, user1] = await hre.ethers.getSigners();

  // 1. Deploy
  const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();
  const usdcAddr = await usdc.getAddress();

  const CommonGate = await hre.ethers.getContractFactory("CommonGate");
  const gate = await CommonGate.deploy(deployer.address);
  await gate.waitForDeployment();
  const gateAddr = await gate.getAddress();

  const CommonVault = await hre.ethers.getContractFactory("CommonVault");
  const vault = await CommonVault.deploy(usdcAddr, "Common Share", "cmUSDC", gateAddr);
  await vault.waitForDeployment();
  const vaultAddr = await vault.getAddress();

  // 2. Simulate
  console.log("   > Contracts Deployed.");
  console.log("   > Verifying User...");
  await gate.setVerification(user1.address, true);

  console.log("   > Minting 10,000 USDC to User...");
  const mintAmount = hre.ethers.parseUnits("10000", 18);
  await usdc.mint(user1.address, mintAmount);
  
  console.log("   > User Depositing 5,000 USDC...");
  const depositAmount = hre.ethers.parseUnits("5000", 18);
  await usdc.connect(user1).approve(vaultAddr, depositAmount);
  await vault.connect(user1).deposit(depositAmount, user1.address);

  console.log("   > Simulating 'Rebalance to Aave'...");
  await vault.rebalanceStrategy("Aave", hre.ethers.parseUnits("2500", 18), "Optimizing for higher variable rate");

  console.log("   > Simulating Yield Harvest (+$50 USDC)...");
  const yieldAmount = hre.ethers.parseUnits("50", 18);
  await usdc.mint(vaultAddr, yieldAmount); 
  await vault.harvest(yieldAmount);

  console.log("\n✅ BACKEND READY. COPY THESE ADDRESSES:");
  console.log("   - Vault:", vaultAddr);
  console.log("   - Gate: ", gateAddr);
  console.log("   - USDC: ", usdcAddr);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
