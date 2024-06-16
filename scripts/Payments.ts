import hre, { ethers } from "hardhat";

async function main() {
    console.log("DEPLOYING...");
    const [deployer, owner] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("Payments");
    const payments = await Factory.deploy();
    await payments.waitForDeployment();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });