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
  ORGANIZATION_ID_TEST,
  ORGANIZATION_INITIAL_BALANCE,
  MOVEMENT_CREATION_FEE,
  PROJECT_CREATION_FEE
} = require("./test_setup");

describe("Bondly App - ", function () {
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

    //   expect(await BondlyContract.totalOrganizations()).to.equal(1);
    //   expect(await BondlyContract.totalProjects()).to.equal(1);
    //   expect(
    //     await BondlyContract.getOrganizationBalance(ORGANIZATION_ID_TEST)
    //   ).to.equal(ORGANIZATION_INITIAL_BALANCE);
    });
  });

//   describe("Create, approve and reject Movements", function () {
//     it("Should create a movement.", async function () {
//       const {
//         BondlyContract,
//         bob,
//         pizzaShop
//       } = await loadFixture(basicBondlySetupFixture);

//       await BondlyContract.connect(bob).createMovement(
//         MOVEMENT_ID_TEST,
//         PROJECT_ID_TEST,
//         ORGANIZATION_ID_TEST,
//         PIZZA_PRICE,
//         pizzaShop.address
//       );
//       expect(
//         await BondlyContract.getOrganizationBalance(ORGANIZATION_ID_TEST)
//       ).to.equal(ORGANIZATION_INITIAL_BALANCE.sub(PIZZA_PRICE));
//       expect(await BondlyContract.totalMovements()).to.equal(1);
//     });

//     it("Should approve a movement.", async function () {
//       const {
//         USDTokenContract,
//         BondlyContract,
//         alice,
//         bob,
//         pizzaShop
//       } = await loadFixture(basicBondlySetupFixture);

//       await BondlyContract.connect(bob).createMovement(
//         MOVEMENT_ID_TEST,
//         PROJECT_ID_TEST,
//         ORGANIZATION_ID_TEST,
//         PIZZA_PRICE,
//         pizzaShop.address
//       );

//       await expect(
//         BondlyContract.connect(bob).approveMovement(
//           MOVEMENT_ID_TEST,
//           ORGANIZATION_ID_TEST
//         )
//       ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_APPROVED_BY_SAME_USER");

//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
//       await BondlyContract.connect(alice).approveMovement(
//         MOVEMENT_ID_TEST,
//         ORGANIZATION_ID_TEST
//       );
//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
//     });

//     it("Should reject a movement, but after 2nd approval, send the funds.", async function () {
//       const {
//         USDTokenContract,
//         BondlyContract,
//         alice,
//         bob,
//         carl,
//         pizzaShop
//       } = await loadFixture(basicBondlySetupFixture);

//       await BondlyContract.connect(bob).createMovement(
//         MOVEMENT_ID_TEST,
//         PROJECT_ID_TEST,
//         ORGANIZATION_ID_TEST,
//         PIZZA_PRICE,
//         pizzaShop.address
//       );

//       await expect(
//         BondlyContract.connect(bob).rejectMovement(
//           MOVEMENT_ID_TEST,
//           ORGANIZATION_ID_TEST
//         )
//       ).to.be.revertedWith("CANNOT_BE_PROPOSED_AND_REJECTED_BY_SAME_USER");

//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
//       await BondlyContract.connect(alice).rejectMovement(
//         MOVEMENT_ID_TEST,
//         ORGANIZATION_ID_TEST
//       );
//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
//       await BondlyContract.connect(carl).approveMovement(
//         MOVEMENT_ID_TEST,
//         ORGANIZATION_ID_TEST
//       );
//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(PIZZA_PRICE);
//     });

//     it("Should reject a movement altogether and return the funds to the Organization.", async function () {
//       const {
//         USDTokenContract,
//         BondlyContract,
//         alice,
//         bob,
//         carl,
//         pizzaShop
//       } = await loadFixture(basicBondlySetupFixture);

//       await BondlyContract.connect(bob).createMovement(
//         MOVEMENT_ID_TEST,
//         PROJECT_ID_TEST,
//         ORGANIZATION_ID_TEST,
//         PIZZA_PRICE,
//         pizzaShop.address
//       );

//       const organizationBalance = await BondlyContract.getOrganizationBalance(ORGANIZATION_ID_TEST);

//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
//       await BondlyContract.connect(alice).rejectMovement(
//         MOVEMENT_ID_TEST,
//         ORGANIZATION_ID_TEST
//       );
//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
//       await BondlyContract.connect(carl).rejectMovement(
//         MOVEMENT_ID_TEST,
//         ORGANIZATION_ID_TEST
//       );
//       expect(await USDTokenContract.balanceOf(pizzaShop.address)).to.equal(0);
//       expect(
//         await BondlyContract.getOrganizationBalance(ORGANIZATION_ID_TEST)
//       ).to.equal(
//         organizationBalance.add(PIZZA_PRICE)
//       );
//     });
//   });
});