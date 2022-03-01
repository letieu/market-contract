const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Marketplace auction", function() {
  let collection;
  let marketplace;
  let owner;
  let account1;
  let account2;
  let account3;

  beforeEach(async () => {
    [owner, account1, account2, account3] = await ethers.getSigners();

    const ERC1155Collection = await ethers.getContractFactory("ERC1155Collection");
    collection = await ERC1155Collection.deploy("Name", "Symbol", "uriABC");
    await collection.deployed();

    const Marketplace = await ethers.getContractFactory("Marketplace");
    marketplace = await Marketplace.deploy(owner.address, 500);
    await marketplace.deployed();

    // mint some tokens
    await collection.connect(account1).create(account1.address, 10, "tokenUri");
    await collection.connect(account1).setApprovalForAll(marketplace.address, true);
  });

  it("Should putOnAuction", async function() {
    const endInOneMinute = Math.ceil((Date.now() + 60 * 1000) / 1000);
    const [id, amount, minBid] = [0, 6, ethers.utils.parseEther('1')];
    await marketplace.connect(account1).putOnAuction(collection.address, id, amount, minBid, endInOneMinute);

    const auction = await marketplace.auctionItems(collection.address, id, account1.address);

    expect(await marketplace.saleType(collection.address, id, account1.address)).to.equal(1);
    expect(auction.amount).to.equal(amount);
    expect(auction.maxBid).to.equal(minBid);
    expect(auction.maxBidder).to.equal('0x0000000000000000000000000000000000000000');
    expect(auction.endTime).to.equal(endInOneMinute);
  });

  it("Should add bid", async function() {
    // account1 put on auction
    const endInOneMinute = Math.ceil((Date.now() + 60 * 1000) / 1000);
    const [id, amount, minBid] = [0, 6, ethers.utils.parseEther('1')];
    await marketplace.connect(account1).putOnAuction(collection.address, id, amount, minBid, endInOneMinute);

    // account2 bid
    let options = { value: ethers.utils.parseEther("2") }
    await marketplace.connect(account2).bid(collection.address, id, account1.address, options);

    // account3 bid
    options = { value: ethers.utils.parseEther("3") }
    await marketplace.connect(account3).bid(collection.address, id, account1.address, options);

    const auction = await marketplace.auctionItems(collection.address, id, account1.address);

    expect(auction.maxBid).to.equal(ethers.utils.parseEther("3"));
    expect(auction.maxBidder).to.equal(account3.address);

    expect(await marketplace.pendingWithdraws(account2.address)).to.equal(ethers.utils.parseEther("2"));
  });

  it("Should end auction", async function() {
    // account1 put on auction
    const endInOneMinute = Math.ceil((Date.now() + 60 * 1000) / 1000);
    const [id, amount, minBid] = [0, 6, ethers.utils.parseEther('1')];
    await marketplace.connect(account1).putOnAuction(collection.address, id, amount, minBid, endInOneMinute);

    // account2 bid
    let options = { value: ethers.utils.parseEther("2") }
    await marketplace.connect(account2).bid(collection.address, id, account1.address, options);

    // account3 bid
    options = { value: ethers.utils.parseEther("3") }
    await marketplace.connect(account3).bid(collection.address, id, account1.address, options);

    // account1 end auction
    ethers.provider.send("evm_increaseTime", [60]);
    await marketplace.connect(account1).endAuction(collection.address, id, account1.address);

    const auction = await marketplace.auctionItems(collection.address, id, account1.address);
    expect(auction.ended).to.equal(true);

    // check token balance
    expect(await collection.balanceOf(account1.address, 0)).to.equal(4);
    expect(await collection.balanceOf(account3.address, 0)).to.equal(6);
  });

  it("Should withdraw", async function() {
    // account1 put on auction
    const endInOneMinute = Math.ceil((Date.now() + 90 * 1000) / 1000);
    const [id, amount, minBid] = [0, 6, ethers.utils.parseEther('1')];
    await marketplace.connect(account1).putOnAuction(collection.address, id, amount, minBid, endInOneMinute);

    // account2 bid
    let options = { value: ethers.utils.parseEther("2") }
    await marketplace.connect(account2).bid(collection.address, id, account1.address, options);

    // account3 bid
    options = { value: ethers.utils.parseEther("3") }
    await marketplace.connect(account3).bid(collection.address, id, account1.address, options);

    // account2 withdraw
    await marketplace.connect(account2).withdraw();
    expect(await marketplace.pendingWithdraws(account2.address)).to.equal(ethers.utils.parseEther("0"));
  })

});
