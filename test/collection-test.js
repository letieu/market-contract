const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC1155Collection", function() {
  let collection;
  let owner;
  let account1;

  beforeEach(async () => {
    const ERC1155Collection = await ethers.getContractFactory("ERC1155Collection");
    collection = await ERC1155Collection.deploy("Name", "Symbol", "uriABC");
    await collection.deployed();

    [owner, account1] = await ethers.getSigners();
  });
  it("Should deploy", async function() {
    expect(await collection.name()).to.equal("Name");
    expect(await collection.symbol()).to.equal("Symbol");
    expect(await collection.contractURI()).to.equal("uriABC");
  });

  it("Should have an owner", async function() {
    expect(await collection.owner()).to.equal(owner.address);
  });

  it("Should create new token", async function() {
    await collection.create(account1.address, 10, "tokenUri");
    expect(await collection.balanceOf(account1.address, 0)).to.equal(10);
    expect(await collection.uri(0)).to.equal("tokenUri");
    expect(await collection.uri(0)).to.equal("tokenUri");
  });

  it("Should have creator and royalty", async function() {
    await collection.create(account1.address, 10, "tokenUri");
    collection.setRoyalty(0, 25); // 0.25

    expect(await collection.getCreator(0)).to.equal(owner.address);
    expect(await collection.getRoyalty(0)).to.equal(25);
  });
});
