const { network } = require("hardhat")
const { ethers } = require("hardhat")
const { developmentChain } = require("../helper-hardhat-config")
const BASE_FEE = ethers.utils.parseEther("0.25") // is the premium. It cost 0.25 LINK per request
const GAS_PRICE_LINK = 1e9 // link per gas .Calculated vallue based of gas price of the chain
//The price of reques change based on the price of theg gas

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  const args = [BASE_FEE, GAS_PRICE_LINK]
  if (developmentChain.includes(network.name)) {
    log("Local network detected! deploying mocks...")
    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      log: true,
      args: args,
    })
    log("Mocks Deployed ")
    log("--------------------------------------------")
  }
}

module.exports.tags = ["all", "mocks"]
