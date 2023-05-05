const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const {
  developmentChain,
  networkConfig,
} = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")
!developmentChain.includes(network.name)
  ? describe.skip
  : describe("Raffle", async () => {
      let raffle, vrfCoordinadorV2Mock, raffleEntranceFee, deployer, interval
      const chainId = network.config.chainId
      beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer
        await deployments.fixture(["all"])
        raffle = await ethers.getContract("Raffle", deployer)
        vrfCoordinadorV2Mock = await ethers.getContract(
          "VRFCoordinatorV2Mock",
          deployer
        )
        raffleEntranceFee = await raffle.getEntrenceFee()
            interval = await raffle.getInterval()
    })

      describe("Constructor ", async () => {
        it("initializes the raffle correctly", async () => {
          //Ideally 1 it per assert
          const raffleState = await raffle.getRaffleState()
          const interval = await raffle.getInterval()
          assert.equal(raffleState.toString(), "0")
          assert.equal(interval.toString(), networkConfig[chainId]["interval"])
        })
      })

      describe("Enter Raffle", async () => {
        it("Revert if u dont pay enough", async () => {
          await expect(raffle.enterRaffle()).to.be.revertedWith(
            "Raffle__NotEnoughETHEntered"
          )
        })

        it("records players when they enter ", async () => {
          await raffle.enterRaffle({ value: raffleEntranceFee })
          const playerFromContract = await raffle.getPlayer(0)
          assert.equal(playerFromContract, deployer)
        })
        it("emits an event on enter", async () =>{
            await expect(
              raffle.enterRaffle({ value: raffleEntranceFee })
            ).to.emit(raffle, "RaffleEnter")
        })
        it("does not allow entrance when raffle is calculating", async () => {
            await raffle.enterRaffle({value: raffleEntranceFee})
            await network.provider.send("evm_increaseTime", [interval.toNumber() +1])
            await network.provider.send("evm_mine", [])
            // We pretend to be chainlink Keeper
            await raffle.performUpkeep([])
            await expect(raffle.enterRaffle(({value: raffleEntranceFee}))).to.be.revertedWith("Raffle__NotOpen")
        })
    
    })
      //describe("")
    })
