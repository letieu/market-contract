const hre = require("hardhat");

async function main() {
  const ERC1155Collection = await ethers.getContractFactory("ERC1155Collection");
  const collection = await ERC1155Collection.deploy("Name", "Symbol", "uriABC");

  await collection.deployed();

  console.log("Collection deployed to:", collection.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
