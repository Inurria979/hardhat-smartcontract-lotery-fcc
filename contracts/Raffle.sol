// Enter the lotery ( paying)
// Pick a random winner 
// Selected every x time -> completly automated
// Chainlink oracle -> Randomness, Automated Execution ( Chainlink Keeper)

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
contract Raffle is VRFConsumerBaseV2{
    //State variable
    uint private immutable i_entranceFee;
    address payable [] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    //Lotery variabke
    address private s_recentWinner;
    //events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint index);
    event WinnerPicked(address indexWinner);
     constructor(address vrfCoordinatorV2, uint entranceFee,
        bytes32 gasLane, uint64 subscriptionId, 
        uint32 callbackGasLimit
      ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        //require msg.value > i_entre
        if(msg.value < i_entranceFee) {revert Raffle__NotEnoughETHEntered();}
        s_players.push(payable(msg.sender));
        //Emit and event when we update a dynamic array or mapping
        emit RaffleEnter(msg.sender);
    }
    //Request the random number
    //Do something with the number
    // 2 transaction proccess
    function requestRandomWinner() external{   
        uint requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gasLane keyHash
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }
    //Because is override we need an uint, but we do not used
    function fulfillRandomWords(uint /*requestId*/, uint[] memory randomWords) internal override{
        uint indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success){
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }
    function getEntrenceFee () public view returns(uint){
        return i_entranceFee;
    }
    function getPlayer(uint index) public view  returns(address){
        return s_players[index];
    }
    function getRecentWinner () public view returns(address){
        return s_recentWinner;
    }
}