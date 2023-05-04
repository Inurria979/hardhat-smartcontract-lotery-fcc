// Enter the lotery ( paying)
// Pick a random winner 
// Selected every x time -> completly automated
// Chainlink oracle -> Randomness, Automated Execution ( Chainlink Keeper)
// Testing
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "hardhat/console.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeedpNotNeeded(uint currentBalance, uint numPlayers, uint rafleState) ;

/**
 * @title A sample Raffle Contract
 * @author Inurria979
 * @notice This contract is for creatinf a untamperable decentralized smart contract
 * @dev This implmets chainLink VRF v2 and chainlink keepers
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {

   /*Type declaration*/
   enum RaffleState{
        OPEN,
        CALCULATING
   }
   
    //State variable
    uint private immutable i_entranceFee;
    address payable [] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint private s_lastTimeStamp;
    //Lotery variabke
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint private  immutable i_interval;

    //events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint index);
    event WinnerPicked(address indexWinner);

     constructor(
        address vrfCoordinatorV2, // contract address
        uint entranceFee,
        bytes32 gasLane, 
        uint64 subscriptionId, 
        uint32 callbackGasLimit, 
        uint interval
      ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        //require msg.value > i_entre
        if(msg.value < i_entranceFee) {revert Raffle__NotEnoughETHEntered();}
        
        if (s_raffleState != RaffleState.OPEN) {revert Raffle__NotOpen();}
        
        s_players.push(payable(msg.sender));
        //Emit and event when we update a dynamic array or mapping
        emit RaffleEnter(msg.sender);
    }
     /**
     *  @dev that is th function that the cahinlink keeper nodes call ther look for the upkeepNeeded 
     * to return true.
     * The following should be true in order to return true
     * 1 Our time interval should have passed
     * 2 the lottery should have atleast 1 player and have some eth
     * 3 our supscription in feded with link
     * 4 lottery should be in a open 'state'
     * */
    function checkUpkeep(bytes memory /*checkdata*/) public view override
    returns(bool upKeepNeeded, bytes memory  /*performData*/ ){
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePass = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0 ;
        upKeepNeeded = (isOpen && timePass && hasPlayers && hasBalance);
    }
    //Request the random number
    //Do something with the number
    // 2 transaction proccess
    function performUpkeep(bytes calldata /* perforData*/) external override{ 
        
        (bool upKeepNeeded, ) = checkUpkeep("");

        if(!upKeepNeeded){
            revert Raffle__UpKeedpNotNeeded(address(this).balance, s_players.length, uint(s_raffleState) );
        }
        s_raffleState = RaffleState.CALCULATING;  
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
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable [](0);
        s_lastTimeStamp = block.timestamp;
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
    function getRaffleState() public view returns(RaffleState){
        return s_raffleState;
    }
    function getNumWords() public pure returns(uint){
        return NUM_WORDS;
    }
    function getNumerOfPlayer() public view returns(uint){
        return s_players.length;
    }
    function getLatesTimeStamp() public view returns(uint){
        return s_lastTimeStamp;
    }
    function requestConfirmations() public pure returns(uint){
        return REQUEST_CONFIRMATIONS;
    }
}