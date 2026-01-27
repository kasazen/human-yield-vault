// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BoringVault} from "../src/base/BoringVault.sol";
import {ManagerWithMerkleVerification} from "../src/core/ManagerWithMerkleVerification.sol";
import {TellerWithMultiAssetSupport} from "../src/core/TellerWithMultiAssetSupport.sol";
import {AccountantWithRateProviders} from "../src/core/AccountantWithRateProviders.sol";
import {RevenueSplitter} from "../src/core/RevenueSplitter.sol";
import {VedaArcticLens} from "../src/core/VedaArcticLens.sol";
import {WorldIDHook} from "../src/hooks/WorldIDHook.sol";
import {MorphoBlueDecoder} from "../src/decoders/MorphoBlueDecoder.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract DeployVedaArctic is Script {
    function run() external {
        // ---------------------------------------------------------
        // 1. Configuration (World Chain Mainnet Constants)
        // ---------------------------------------------------------
        address usdcAddr = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address morphoBlueAddr = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

        // ---------------------------------------------------------
        // 2. Strict Ownership (Hardcoded Security)
        // ---------------------------------------------------------
        // We explicitly define the owner to prevent accidental assignment to a hot wallet
        address mainOwner = 0xc387A2EB7878ef61C032226B21f2A596E727564C;
        address partnerWallet = address(0xDEAFBEEF); // Replace with real partner if needed

        // ---------------------------------------------------------
        // 3. Deploy Infrastructure
        // ---------------------------------------------------------
        vm.startBroadcast();

        // Core Components
        WorldIDHook hook = new WorldIDHook();
        RevenueSplitter splitter = new RevenueSplitter(mainOwner, partnerWallet);
        VedaArcticLens lens = new VedaArcticLens();

        // The Brain (Accountant) - Locked to mainOwner
        AccountantWithRateProviders accountant = new AccountantWithRateProviders(
            mainOwner, usdcAddr, address(hook), address(splitter)
        );

        // The Vault (Asset Container) - Locked to mainOwner
        BoringVault vault = new BoringVault(payable(mainOwner), "Veda Arctic USDC", "vUSDC", ERC20(usdcAddr));

        // The Manager (Security Layer) - Locked to mainOwner
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(
            mainOwner, address(vault)
        );

        // The Teller (Human Gate) - Locked to mainOwner
        TellerWithMultiAssetSupport teller = new TellerWithMultiAssetSupport(
            mainOwner, address(vault), address(accountant)
        );

        // ---------------------------------------------------------
        // 4. Safety Equipment (Decoders)
        // ---------------------------------------------------------
        MorphoBlueDecoder morphoDecoder = new MorphoBlueDecoder(morphoBlueAddr, usdcAddr);

        // ---------------------------------------------------------
        // 5. Wiring & Permissions
        // ---------------------------------------------------------
        // Note: Since 'mainOwner' is 0xc387..., and we are likely deploying from 
        // the same address, we can configure these. If deploying from a different 
        // gas wallet, these calls might revert or need to be done by the owner later.
        
        // We assume msg.sender (deployer) == mainOwner for initial setup
        if (msg.sender == mainOwner) {
            accountant.setTeller(address(teller));
            vault.setManager(address(manager));
        } else {
            console.log("WARNING: Deployer is not Owner. You must manually call setTeller/setManager from 0xc387...");
        }

        vm.stopBroadcast();

        // ---------------------------------------------------------
        // 6. Output Verification
        // ---------------------------------------------------------
        console.log("=== VEDA ARCTIC DEPLOYMENT COMPLETE ===");
        console.log("OWNER LOCKED TO:    ", mainOwner);
        console.log("Lens (Frontend):    ", address(lens));
        console.log("Teller (User Gate): ", address(teller));
        console.log("Vault (Holdings):   ", address(vault));
        console.log("Manager (Brain):    ", address(manager));
        console.log("Morpho Decoder:     ", address(morphoDecoder));
    }
}
