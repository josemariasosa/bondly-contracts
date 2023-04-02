const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const { deployVaultFixture, basicVaultSetupFixture, DECIMALS } = require("./test_setup");

describe("Organization Vault - King of Devs 🧠", function () {
  describe("Deployment", function () {
    it("Should be deployed with the correct params.", async function () {
      const {
        USDTokenContract,
        OrganizationVaultContract,
        owner
      } = await loadFixture(deployVaultFixture);

      expect(await OrganizationVaultContract.owner()).to.equal(owner.address);
      expect(await OrganizationVaultContract.baseToken()).to.equal(USDTokenContract.address);
    });

    it("Should have a correct initial setup.", async function () {
    const {
        USDTokenContract,
        OrganizationVaultContract,
        owner,
        alice,
        bob,
        carl,
        pizzaShop
      } = await loadFixture(basicVaultSetupFixture);

      expect(await OrganizationVaultContract.totalOrganizations()).to.equal(1);
      expect(await OrganizationVaultContract.totalProjects()).to.equal(1);
    });
  });
});