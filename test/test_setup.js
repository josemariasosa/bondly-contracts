const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const DECIMALS = ethers.BigNumber.from(10).pow(18);
const ORGANIZATION_ID_TEST = "207760f2-fdd3-4397-80cc-a51093ccbf18";
const PROJECT_ID_TEST = "fe2f8dfa-0c6e-4d60-ba62-efc1c1dcd712";
const MOVEMENT_ID_TEST = "7bf23fc6-99be-4c99-b8cd-816bf4c1b263";
const PIZZA_PRICE = ethers.BigNumber.from(199).mul(DECIMALS);

async function deployVaultFixture() {
  // Get the ContractFactory and Signers here.
  const USDToken = await ethers.getContractFactory("Token");
  const OrganizationVault = await ethers.getContractFactory("OrganizationVault");

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

  const OrganizationVaultContract = await OrganizationVault.connect(owner).deploy(
    USDTokenContract.address
  );

  expect(await OrganizationVaultContract.totalOrganizations()).to.equal(0);

  // Fixtures can return anything you consider useful for your tests
  return {
    USDTokenContract,
    OrganizationVaultContract,
    owner,
    alice,
    bob,
    carl,
    pizzaShop
  };
}

async function basicVaultSetupFixture() {
  const {
    USDTokenContract,
    OrganizationVaultContract,
    owner,
    alice,
    bob,
    carl,
    pizzaShop
  } = await loadFixture(deployVaultFixture);

  await expect(
    OrganizationVaultContract.connect(owner).createOrganization(
      ORGANIZATION_ID_TEST,
      [alice.address],
      2
    )
  ).to.be.revertedWith("INCORRECT_APPROVAL_THRESHOLD");

  await OrganizationVaultContract.connect(owner).createOrganization(
    ORGANIZATION_ID_TEST,
    [alice.address, bob.address, carl.address],
    2
  );

  // IMPORTANT: This was used to fix the error with the block mining.
  // await createOrg.wait(1);

  await OrganizationVaultContract.connect(alice).createProject(
    PROJECT_ID_TEST,
    ORGANIZATION_ID_TEST
  );

  await expect(
    OrganizationVaultContract.connect(bob).createMovement(
      MOVEMENT_ID_TEST,
      PROJECT_ID_TEST,
      ORGANIZATION_ID_TEST,
      PIZZA_PRICE,
      pizzaShop.address
    )
  ).to.be.revertedWith("NOT_ENOUGH_ORGANIZATION_FUNDS");

  return {
    USDTokenContract,
    OrganizationVaultContract,
    owner,
    alice,
    bob,
    carl,
    pizzaShop
  };
}

module.exports = {
  deployVaultFixture,
  basicVaultSetupFixture,
  DECIMALS,
  ORGANIZATION_ID_TEST,
  PROJECT_ID_TEST,
  MOVEMENT_ID_TEST,
  PIZZA_PRICE
};