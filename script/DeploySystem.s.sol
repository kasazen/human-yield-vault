// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/YieldDirector.sol";
import "../src/adapters/FlexibleAdapter.sol";
import "../src/vaults/SmartVault.sol";
import "../src/mocks/MockYieldSource.sol";

contract DeploySystem is Script {
    function run() external {
        vm.startBroadcast();

        address usdc = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        
        // 1. Deploy the Target Dummy (Mock Yield Source)
        MockYieldSource mockYield = new MockYieldSource(IERC20(usdc));
        console.log("Mock Yield Source Deployed:", address(mockYield));

        // 2. Deploy the Brain (Director)
        YieldDirector director = new YieldDirector();
        console.log("New Director Deployed:", address(director));

        // 3. Deploy the Muscle (Adapter) - Pointing to the MOCK
        FlexibleAdapter adapter = new FlexibleAdapter(usdc, address(mockYield), address(director));
        console.log("New Adapter Deployed:", address(adapter));

        // 4. Deploy the Body (SmartVault)
        SmartVault vault = new SmartVault(IERC20(usdc), "Yield Vault", "yUSDC");
        console.log("New SmartVault Deployed:", address(vault));

        // 5. Wire Everything
        director.setAdapter(address(adapter));      
        vault.setStrategist(address(director), true); 
        
        console.log("System Fully Wired!");

        vm.stopBroadcast();
    }
}
