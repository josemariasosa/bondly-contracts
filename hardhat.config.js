require("dotenv").config()
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    avalanche_testnet: {
      allowUnlimitedContractSize: true,
      gas: 5000000,
      gasLimit: 5000000,
      maxFeePerGas: 55000000000,
      maxPriorityFeePerGas: 55000000000,
      // url: `https://avalanche-fuji.infura.io/v3/${process.env.INFURA_API_KEY}`,
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts: [
        process.env.ALICE_PRIVATE_KEY,
        process.env.BOB_PRIVATE_KEY,
        process.env.CARL_PRIVATE_KEY,
      ]
    },
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200  // Adjust this number according to your contract's needs
    }
  }
};