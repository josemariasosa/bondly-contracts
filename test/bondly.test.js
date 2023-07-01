const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const {
  deployBondlyFixture,
  basicBondlySetupFixture,
  DECIMALS,
  MOVEMENT_ID_TEST,
  PROJECT_ID_TEST,
  PIZZA_PRICE,
  PROJECT_SLUG_TEST,
  ORGANIZATION_INITIAL_BALANCE,
  MOVEMENT_CREATION_FEE,
  PROJECT_CREATION_FEE,
  PROJECT_INITIAL_BALANCE_AVAX,
  MOVEMENT_SLUG_TEST,
  PROJECT_INITIAL_BALANCE_STABLE,
} = require("./test_setup");

describe("Bondly App - Test Suite for Modular Hackathon 🐷", function () {
  describe("Deployment", function () {
    it("Should be deployed with the correct params.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        owner
      } = await loadFixture(deployBondlyFixture);

      expect(await BondlyContract.projectCreationFee()).to.equal(PROJECT_CREATION_FEE);
      expect(await BondlyContract.movementCreationFee()).to.equal(MOVEMENT_CREATION_FEE);
      expect(await BondlyContract.owner()).to.equal(owner.address);
    });

    it("Should have a correct initial setup.", async function () {
      const {
        BondlyContract
      } = await loadFixture(basicBondlySetupFixture);

      expect(await BondlyContract.getTotalProjects()).to.equal(1);

      expect(
        await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)
      ).to.equal(PROJECT_INITIAL_BALANCE_AVAX);
      expect(
        await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)
      ).to.equal(PROJECT_INITIAL_BALANCE_STABLE);
    });
  });

  describe("Create, approve and reject Movements", function () {
    it("Should create a movement.", async function () {
      const {
        BondlyContract,
        bob,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,    // Amount in STABLE
        0,              // Amount in AVAX 🍒
        pizzaShop.address
      );

      expect(
        await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)
      ).to.equal(PROJECT_INITIAL_BALANCE_AVAX);
      expect(
        await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)
      ).to.equal(PROJECT_INITIAL_BALANCE_STABLE.sub(PIZZA_PRICE));

      expect(await BondlyContract.getTotalMovements()).to.equal(1);
    });

    it("Should approve a movement.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,
        0,
        pizzaShop.address
      );

      await expect(
        BondlyContract.connect(bob).approveMovement(
          MOVEMENT_SLUG_TEST,
          PROJECT_SLUG_TEST
        )
      ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_APPROVED_BY_SAME_USER");

      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(alice).approveMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
    });

    it("Should reject a movement, but after 2nd approval, send the funds.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
        carl,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,
        0,
        pizzaShop.address
      );

      await expect(
        BondlyContract.connect(bob).rejectMovement(
          MOVEMENT_SLUG_TEST,
          PROJECT_SLUG_TEST
        )
      ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_REJECTED_BY_SAME_USER");

      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(alice).rejectMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(carl).approveMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
    });

    it("Should reject a movement altogether and return the funds to the Organization.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
        carl,
        pizzaShop
      } = await loadFixture(basicBondlySetupFixture);

      await BondlyContract.connect(bob).createPayment(
        "Pay for the pizza in the event.",
        "Invoice number: WAP-123423432\nWe love pizza",
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST,
        PIZZA_PRICE,
        0,
        pizzaShop.address
      );

      const projectBalanceAvax = await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST);
      const projectBalanceStable = await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST);

      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(alice).rejectMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
      await BondlyContract.connect(carl).rejectMovement(
        MOVEMENT_SLUG_TEST,
        PROJECT_SLUG_TEST
      );
      expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);

      expect(
        await BondlyContract.getProjectBalanceAvax(PROJECT_SLUG_TEST)
      ).to.equal(
        projectBalanceAvax.add(0)
      );
      expect(
        await BondlyContract.getProjectBalanceStable(PROJECT_SLUG_TEST)
      ).to.equal(
        projectBalanceStable.add(PIZZA_PRICE)
      );
    });
  });

  describe("Funding project", function () {
    it("Should allow funding a project.", async function () {
      const {
        USDTokenContract,
        BondlyContract,
        alice,
        bob,
      } = await loadFixture(basicBondlySetupFixture);

      // console.log("NACIONES UNIDAS");
      // // const result = await BondlyContract.getOwnerProjects(alice.address, 5);
      // const result = await BondlyContract.projectOwners(alice.address, 0);
      // console.log(result);

    });
  });
});