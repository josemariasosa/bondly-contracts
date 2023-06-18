async function main() {

  const DECIMALS = ethers.BigNumber.from(10).pow(18);

  const PROJECT_CREATION_FEE = ethers.utils.parseEther('0.01');
  const MOVEMENT_CREATION_FEE = ethers.BigNumber.from(0.00).mul(DECIMALS);
  const CONRADO_ADDRESS = "0x942AeF058cb15C9b8b89B57B4E607d464ed8Cd33";

  const PROJECT_SLUG_TEST = "bondly-irl-meeting";
  const MOVEMENT_SLUG_TEST = "dinner-pizza";

  const PROJECT_INITIAL_BALANCE_AVAX = ethers.utils.parseEther('0.1');
  const PROJECT_INITIAL_BALANCE_STABLE = ethers.utils.parseEther('240.0');

  // Using USDC mock stable coin.
  const PIZZA_PRICE = ethers.BigNumber.from(199).mul(DECIMALS);

  const [
    alice,
    bob,
    pizzaShop
  ] = await ethers.getSigners();

  const USDToken = await ethers.getContractFactory("Token");
  const Bondly = await ethers.getContractFactory("Bondly");

  console.log("Deploying USDT...");
  const initialSupply = ethers.BigNumber.from(20_000_000).mul(DECIMALS);
  const USDTokenContract = await USDToken.connect(alice).deploy(
    initialSupply,
    "USD Dummy Token",
    "USDT",
    alice.address
  );
  await USDTokenContract.deployed();
  console.log("Done in %s.", USDTokenContract.address);

  console.log("Deploying Bondly...");
  const BondlyContract = await Bondly.connect(alice).deploy(
    [USDTokenContract.address],
    PROJECT_CREATION_FEE,
    MOVEMENT_CREATION_FEE
  );
  await BondlyContract.deployed();
  console.log("Done in %s.", BondlyContract.address);

  console.log("Creating Project");
  const request = await BondlyContract.connect(alice).createProject(
    PROJECT_SLUG_TEST,
    [alice.address, bob.address, CONRADO_ADDRESS],
    2,
    USDTokenContract.address,
    { value: PROJECT_CREATION_FEE }
  );
  console.log(request);
  request.wait();
  console.log("Done.");

  console.log("Funding 🤑 Project");
  await USDTokenContract.connect(alice).approve(
    BondlyContract.address,
    PROJECT_INITIAL_BALANCE_STABLE
  );
  const request2 = await BondlyContract.connect(alice).fundProject(
    PROJECT_SLUG_TEST,
    PROJECT_INITIAL_BALANCE_STABLE,
    { value: PROJECT_INITIAL_BALANCE_AVAX }
  );
  console.log(request2);
  const response = await request2.wait();
  console.log("RESPONSE: ", response);
  console.log("Done.");

  console.log("Creating Movement");
  const request3 = await BondlyContract.connect(bob).createMovement(
    MOVEMENT_SLUG_TEST,
    PROJECT_SLUG_TEST,
    PIZZA_PRICE,
    0,
    pizzaShop.address,
    { value: 0 }
  );
  console.log(request3);
  request3.wait();
  console.log("Done.");

  console.log("Addresses of the deployed contracts:")
  console.log(" - Bondly Address:  %s", BondlyContract.address);
  console.log(" - USDT dummy:  %s", USDTokenContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});