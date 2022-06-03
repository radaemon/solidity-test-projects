// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID contract uses for funding requests
    // Initialized in the constructor
    uint64 s_subscriptionId;

    // Rinkeby Chainlink VRF coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas
    uint32 callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint private constant ROLL_IN_PROGRESS = 42;

    address s_owner;

    // requestID => address of the roller
    // contract can keep track of who to assign the result when it comes back
    mapping(uint256 => address) private s_rollers;
    // stores the roller and the result of the dice roll
    mapping(address => uint256) private s_results;

    event DiceRolled(uint indexed requestId, address indexed roller);
    event DiceLanded(uint indexed requestId, uint indexed result);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function rollDice(address roller)
        public
        onlyOwner
        returns (uint requestId)
    {
        require(s_results[roller] == 0, "Player has already rolled");

        // will revert if sub Id not valid
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        // map the request id to the roller
        s_rollers[requestId] = roller;
        // temporary change his result to ROLL_IN_PROGRESS
        s_results[roller] = ROLL_IN_PROGRESS;
        // emit event we are rolling dice for a player
        emit DiceRolled(requestId, roller);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // transform the result to a number between 1 and 20 inclusively
        uint d20Value = (randomWords[0] % 20) + 1;
        // assign the value to the address in the s_results mapping
        s_results[s_rollers[requestId]] = d20Value;
        // emit event to signal event has landed
        emit DiceLanded(requestId, d20Value);
    }

    function getPlayershouse(address player)
        public
        view
        returns (string memory)
    {
        require(s_results[player] != 0, "Player has not been assigned a house");
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");
        return getHouseName(s_results[player]);
    }

    function getHouseName(uint id) private pure returns (string memory) {
        string[20] memory houseNames = [
            "Targaryen",
            "Lannister",
            "Stark",
            "Tyrell",
            "Baratheon",
            "Martell",
            "Tully",
            "Bolton",
            "Greyjoy",
            "Arryn",
            "Frey",
            "Mormont",
            "Tarley",
            "Dayne",
            "Umber",
            "Valeryon",
            "Manderly",
            "Clegane",
            "Glover",
            "Karstark"
        ];
        return houseNames[id - 1];
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}
