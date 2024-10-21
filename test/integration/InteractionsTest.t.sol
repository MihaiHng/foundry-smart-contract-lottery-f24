// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {VRFCoordinatorV2PlusMock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";

contract InteractionsTest is Test {
    HelperConfig helperConfig;
    VRFCoordinatorV2PlusMock vrfCoordinatorMock;
    LinkToken linkToken;
    CreateSubscription createSubscription;
    FundSubscription fundSubscription;
    AddConsumer addConsumer;

    uint256 subscriptionId;
    uint256 interval;
    bytes32 gasLane;
    uint256 entranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;
    uint256 deployerKey;
    address link;

    uint96 public constant FUND_AMOUNT = 3 ether;

    function setUp() external {
        // Deploy helperConfig contract and mocks
        helperConfig = new HelperConfig();
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();

        // Configutation needed from HelperConfig
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        subscriptionId = 0;
        gasLane = config.gasLane;
        interval = config.interval;
        entranceFee = config.entranceFee;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        deployerKey = config.deployerKey;
        link = config.link;

        // Mock coordinator
        vrfCoordinatorMock = VRFCoordinatorV2PlusMock(vrfCoordinatorV2_5);
    }

    function testCreateSubscription() public {
        //Arange

        //Act
        subscriptionId = createSubscription.createSubscription(
            vrfCoordinatorV2_5,
            deployerKey
        );
        //Assert
        assert(subscriptionId != 0);
    }

    function testFundSubscription() public {
        //Arange

        //Act
        subscriptionId = createSubscription.createSubscription(
            vrfCoordinatorV2_5,
            deployerKey
        );
        fundSubscription.fundSubscription(
            vrfCoordinatorV2_5,
            subscriptionId,
            link,
            deployerKey
        );
        (uint96 balance, , , , ) = vrfCoordinatorMock.getSubscription(
            subscriptionId
        );
        //Assert
        assertEq(balance, FUND_AMOUNT);
    }

    function testAddConsumer() public {
        //Arange

        //Act
        subscriptionId = createSubscription.createSubscription(
            vrfCoordinatorV2_5,
            deployerKey
        );
        fundSubscription.fundSubscription(
            vrfCoordinatorV2_5,
            subscriptionId,
            link,
            deployerKey
        );

        // Deploy Raffle to add it as consumer
        vm.startBroadcast(deployerKey);
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinatorV2_5,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        // Add the Raffle contract as a consumer
        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinatorV2_5,
            subscriptionId,
            deployerKey
        );

        //Assert
        (, , , , address[] memory consumers) = vrfCoordinatorMock
            .getSubscription(subscriptionId);
        assertEq(
            consumers[0],
            address(raffle),
            "Raffle contract should be added as consumer"
        );
    }
}
