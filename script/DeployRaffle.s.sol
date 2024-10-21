// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            config.subscriptionId = createSubscription.createSubscription(
                config.vrfCoordinatorV2_5,
                config.deployerKey
            );

            // Fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5,
                config.subscriptionId,
                config.link,
                config.deployerKey
            );
        }

        // Deploy Raffle contract
        vm.startBroadcast(config.deployerKey);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );

        vm.stopBroadcast();

        // Add consumer
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinatorV2_5,
            config.subscriptionId,
            config.deployerKey
        );

        return (raffle, helperConfig);
    }
}
