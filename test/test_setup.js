const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const DECIMALS = ethers.BigNumber.from(10).pow(18);
const PROJECT_SLUG_TEST = "bondly-irl-meeting";
const MOVEMENT_SLUG_TEST = "dinner-pizza";

// Using USDC mock stable coin.
const PIZZA_PRICE = ethers.BigNumber.from(199).mul(DECIMALS);

const PROJECT_INITIAL_BALANCE_AVAX = ethers.utils.parseEther('10.0');
const PROJECT_INITIAL_BALANCE_STABLE = ethers.utils.parseEther('0.0');

// Fee in AVAX.
const PROJECT_CREATION_FEE = ethers.utils.parseEther('0.01');
const MOVEMENT_CREATION_FEE = ethers.BigNumber.from(0.00).mul(DECIMALS);

async function deployBondlyFixture() {
  // Get the ContractFactory and Signers here.
  const USDToken = await ethers.getContractFactory("Token");
  const Bondly = await ethers.getContractFactory("Bondly");

  const [
    owner,
    alice,
    bob,
    carl,
    pizzaShop
  ] = await ethers.getSigners();

  const initialSupply = ethers.BigNumber.from(20_000_000).mul(DECIMALS);
  const USDTokenContract = await USDToken.connect(owner).deploy(
    initialSupply,
    "USD Dummy Token",
    "USDT",
    owner.address
  );
  await USDTokenContract.deployed();

  const BondlyContract = await Bondly.connect(owner).deploy(
    [USDTokenContract.address],
    PROJECT_CREATION_FEE,
    MOVEMENT_CREATION_FEE
  );
  await BondlyContract.deployed();

  expect(await BondlyContract.getTotalProjects()).to.equal(0);

  // Fixtures can return anything you consider useful for your tests
  return {
    USDTokenContract,
    BondlyContract,
    owner,
    alice,
    bob,
    carl,
    pizzaShop
  };
}

async function basicBondlySetupFixture() {
  const {
    USDTokenContract,
    BondlyContract,
    owner,
    alice,
    bob,
    carl,
    pizzaShop
  } = await loadFixture(deployBondlyFixture);

  await expect(
    BondlyContract.connect(owner).createProject(
      PROJECT_SLUG_TEST,
      [alice.address],
      2,
      USDTokenContract.address,
      { value: 0 }
    )
  ).to.be.revertedWith("Not enough AVAX sent.");

  await expect(
    BondlyContract.connect(owner).createProject(
      PROJECT_SLUG_TEST,
      [alice.address],
      2,
      USDTokenContract.address,
      { value: PROJECT_CREATION_FEE }
    )
  ).to.be.revertedWith("INCORRECT_APPROVAL_THRESHOLD");

  // IMPORTANT: This was used to fix the error with the block mining.
  // await createOrg.wait(1);

  await BondlyContract.connect(alice).createProject(
    PROJECT_SLUG_TEST,
    [alice.address, bob.address, carl.address],
    2,
    USDTokenContract.address,
    { value: PROJECT_CREATION_FEE }
  );

  await expect(
    BondlyContract.connect(bob).createMovement(
      MOVEMENT_SLUG_TEST,
      PROJECT_SLUG_TEST,
      PIZZA_PRICE,
      0,
      pizzaShop.address,
      { value: 0 }
    )
  ).to.be.revertedWith("NOT_ENOUGH_PROJECT_FUNDS");

  expect(await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)).to.equal(0);
  expect(await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)).to.equal(0);
  await USDTokenContract.connect(owner).approve(
    BondlyContract.address,
    PROJECT_INITIAL_BALANCE_STABLE
  );
  await BondlyContract.connect(owner).fundProject(
    PROJECT_SLUG_TEST,
    PROJECT_INITIAL_BALANCE_STABLE,
    { value: PROJECT_INITIAL_BALANCE_AVAX }
  );

  return {
    USDTokenContract,
    BondlyContract,
    owner,
    alice,
    bob,
    carl,
    pizzaShop
  };
}

module.exports = {
  deployBondlyFixture,
  basicBondlySetupFixture,
  DECIMALS,
  PROJECT_SLUG_TEST,
  MOVEMENT_SLUG_TEST,
  PIZZA_PRICE,
  PROJECT_INITIAL_BALANCE_AVAX,
  PROJECT_INITIAL_BALANCE_STABLE,
  PROJECT_CREATION_FEE,
  MOVEMENT_CREATION_FEE,
};