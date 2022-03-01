require("@nomiclabs/hardhat-waffle");
const dotenv = require("dotenv");
dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.4",
  networks: {
    cronostest: {
      url: process.env.CRONOS_TEST_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    ropstent: {
      url: process.env.ROPSTEN_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
  }
};
