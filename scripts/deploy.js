async function main() {
  const GOERLI_USDT_TOKEN = "0x509ee0d083ddf8ac028f2a56731412edd63223b9";

  const OrganizationVault = await ethers.getContractFactory("OrganizationVault");
  const [owner] = await ethers.getSigners();

  console.log("Step 1. Deploying OrganizationVault contract...")
  const BondlyContract = await OrganizationVault.connect(owner).deploy(
    GOERLI_USDT_TOKEN
  );

  await BondlyContract.deployed();

  console.log("Addresses of the deployed contracts:")
  console.log(" - OrganizationVault:  %s", BondlyContract.address);
  console.log(" - Goerli USDT Token:  %s", GOERLI_USDT_TOKEN);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});