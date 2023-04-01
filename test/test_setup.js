const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const DECIMALS = ethers.BigNumber.from(10).pow(18);

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

  console.log("ARE WE EVEN HERE???????")
  await OrganizationVaultContract.connect(owner).createOrganization(
    "207760f2-fdd3-4397-80cc-a51093ccbf18",
    
    [alice.address, bob.address, carl.address],
    // [alice.address],
    // alice.address,
    2
  );
  console.log("OR HERE?")

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
    DECIMALS
};