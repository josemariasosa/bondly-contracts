const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const {
  deployVaultFixture,
  basicVaultSetupFixture,
  DECIMALS,
  MOVEMENT_ID_TEST,
  PROJECT_ID_TEST,
  PIZZA_PRICE,
  ORGANIZATION_ID_TEST,
  ORGANIZATION_INITIAL_BALANCE
} = require("./test_setup");

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
        OrganizationVaultContract
      } = await loadFixture(basicVaultSetupFixture);

      expect(await OrganizationVaultContract.totalOrganizations()).to.equal(1);
      expect(await OrganizationVaultContract.totalProjects()).to.equal(1);
      expect(
        await OrganizationVaultContract.getOrganizationBalance(ORGANIZATION_ID_TEST)
      ).to.equal(ORGANIZATION_INITIAL_BALANCE);
    });
  });

  describe("Create, approve and reject Movements", function () {
    it("Should create a movement.", async function () {
      const {
        OrganizationVaultContract,
        bob,
        pizzaShop
      } = await loadFixture(basicVaultSetupFixture);

      await OrganizationVaultContract.connect(bob).createMovement(
        MOVEMENT_ID_TEST,
        PROJECT_ID_TEST,
        ORGANIZATION_ID_TEST,
        PIZZA_PRICE,
        pizzaShop.address
      );
      expect(
        await OrganizationVaultContract.getOrganizationBalance(ORGANIZATION_ID_TEST)
      ).to.equal(ORGANIZATION_INITIAL_BALANCE.sub(PIZZA_PRICE));
      expect(await OrganizationVaultContract.totalMovements()).to.equal(1);
    });

    it("Should approve a movement.", async function () {
      const {
        USDTokenContract,
        OrganizationVaultContract,
        owner,
        alice,
        bob,
        carl,
        pizzaShop
      } = await loadFixture(basicVaultSetupFixture);

      await OrganizationVaultContract.connect(bob).createMovement(
        MOVEMENT_ID_TEST,
        PROJECT_ID_TEST,
        ORGANIZATION_ID_TEST,
        PIZZA_PRICE,
        pizzaShop.address
      );

      await expect(
        OrganizationVaultContract.connect(bob).approveMovement(
          MOVEMENT_ID_TEST,
          ORGANIZATION_ID_TEST
        )
      ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_APPROVED_BY_SAME_USER");

      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await OrganizationVaultContract.connect(alice).approveMovement(
        MOVEMENT_ID_TEST,
        ORGANIZATION_ID_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
    });
  });
});