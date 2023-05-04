const { network, ethers } = require("hardhat")
const { networkConfig, developmentChain } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("30") // 2 should be enough

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  let vrfCoordinadorV2Address, subscriptionId

  if (developmentChain.includes(network.name)) {
    const vrfCoordinadorV2Mock = await ethers.getContract(
      "VRFCoordinatorV2Mock"
    )
    vrfCoordinadorV2Address = vrfCoordinadorV2Mock.address
    const transactionResponse = await vrfCoordinadorV2Mock.createSubscription()
    const transactionReceipt = await transactionResponse.wait(1)
    subscriptionId = transactionReceipt.events[0].args.subId
    //Fund the susbcripotion
    // Usually you dont need the link tokjen on a real network

    await vrfCoordinadorV2Mock.fundSubscription(
      subscriptionId,
      VRF_SUB_FUND_AMOUNT
    )
  } else {
    vrfCoordinadorV2Address = networkConfig[chainId]["VRFCoordinadorV2Mock"]
    subscriptionId = networkConfig[chainId]["subscriptionId"]
  }

  const entranceFee = networkConfig[chainId]["entranceFee"]
  const gasLane = networkConfig[chainId]["gasLane"]
  const callbackgasLimit = networkConfig[chainId]["callbackGasLimit"]
  const interval = networkConfig[chainId]["interval"]
  const args = [
    vrfCoordinadorV2Address,
    entranceFee,
    gasLane,
    subscriptionId,
    callbackgasLimit,
    interval,
  ]
 

  const raffle = await deploy("Raffle", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  })
  if (
    !developmentChain.includes(network.name) &&
    process.env.ETHERSCAM_API_KEY
  ) {
    log("Verifying...")
    await verify(raffle.address, args)
  }

  log("----------------------------------")
}

module.exports.tags = ["all", "raffle"]
