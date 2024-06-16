import { Payments } from "../typechain-types";
import { loadFixture, ethers, expect } from "./setup";

describe("Payments", function () {


  async function deploy() {
    const [owner, otherAccount] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("Payments");
    const payments: Payments = await Factory.deploy();
    await payments.waitForDeployment();

    return { owner, otherAccount, payments }
  }

  it("should be deployed", async function () {
    const { payments } = await loadFixture(deploy);

    expect(payments.target).to.be.properAddress;
  });

  it("should have 0 ethers by default", async function () {
    const { payments } = await loadFixture(deploy);

    const balance = await ethers.provider.getBalance(payments.target);
    expect(balance).to.eq(0);
  });

  it("should be possible to send funds", async function () {
    const { owner, otherAccount, payments } = await loadFixture(deploy);

    const sum = 100; // wei
    const msg = "hello from hardhat";

    const tx = await payments.connect(otherAccount).pay(msg, { value: sum });
    const receipt = await tx.wait(1);

    const currentBlock = await ethers.provider.getBlock(
      await ethers.provider.getBlockNumber()
    );

    expect(tx).to.changeEtherBalance(otherAccount, -sum);

    const newPayment = await payments.getPayment(otherAccount.address, 0);

    expect(newPayment.message).to.eq(msg);
    expect(newPayment.amount).to.eq(sum);
    expect(newPayment.from).to.eq(otherAccount.address);
    expect(newPayment.timestamp).to.eq(currentBlock?.timestamp);
  });


});