const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Marketplace fixed", function() {
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

  it("Should deploy", async function() {
    expect(await marketplace.marketPayee()).to.equal(owner.address);
    expect(await marketplace.marketPercent()).to.equal(500);
  });

  it("Should putOnSale", async function() {
    const [id, amount, price] = [0, 6, ethers.utils.parseEther('0.1')];
    await marketplace.connect(account1).putOnSale(collection.address, id, amount, price);

    expect(await marketplace.saleType(collection.address, id, account1.address)).to.equal(0);

    const [saleAmount, salePrice] = await marketplace.fixedItems(collection.address, id, account1.address);
    expect(saleAmount).to.equal(amount);
    expect(salePrice).to.equal(price);
  });

  it("Should buy", async function() {
    const [id, amount, price] = [0, 6, ethers.utils.parseEther('10')];
    const buyAmmount = 4;
    //put on sale
    await marketplace.connect(account1).putOnSale(collection.address, id, amount, price);

    // buy token
    const options = { value: ethers.utils.parseEther("40") }
    await marketplace.connect(account2).buy(collection.address, id, account1.address, buyAmmount, options);

    // check token balance
    expect(await collection.balanceOf(account2.address, id)).to.equal(buyAmmount);
    expect((await marketplace.fixedItems(collection.address, id, account1.address))[0]).to.equal(amount - buyAmmount);
  });

  it("Should re putOnSale", async function() {
    const [id, amount, price] = [0, 6, ethers.utils.parseEther('10')];
    //Account1: Put on sale 6
    await marketplace.connect(account1).putOnSale(collection.address, id, amount, price);

    //Account2: buy token 4
    const buyAmmount = 4;
    let options = { value: ethers.utils.parseEther("40") }
    await marketplace.connect(account2).buy(collection.address, id, account1.address, buyAmmount, options);

    //Account2: resale token 3
    const resaleAmmount = 3;
    const newPrice = ethers.utils.parseEther('5');
    await collection.connect(account2).setApprovalForAll(marketplace.address, true);
    await marketplace.connect(account2).putOnSale(collection.address, id, resaleAmmount, newPrice);

    expect((await marketplace.fixedItems(collection.address, id, account1.address))[0]).to.equal(amount - buyAmmount);
    expect((await marketplace.fixedItems(collection.address, id, account2.address))[0]).to.equal(resaleAmmount);

    //Account3: buy token 3 from Account2
    options = { value: ethers.utils.parseEther("15") }
    await marketplace.connect(account3).buy(collection.address, id, account2.address, resaleAmmount, options);

    expect((await marketplace.fixedItems(collection.address, id, account2.address))[0]).to.equal(0);
    expect(await collection.balanceOf(account3.address, id)).to.equal(resaleAmmount);
  });

});
