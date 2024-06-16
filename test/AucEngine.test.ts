import { AucEngine } from "../typechain-types";
import { loadFixture, ethers, expect } from "./setup";

describe("AucEngine", function () {
    async function deploy() {
        const [owner, seller, buyer] = await ethers.getSigners()

        const Factory = await ethers.getContractFactory("AucEngine", owner);
        const auction: AucEngine = await Factory.deploy();
        await auction.waitForDeployment();

        return { owner, seller, buyer, auction }
    }

    it("sets owner", async function () {
        const { owner, auction } = await loadFixture(deploy);
        const currentOwner = await auction.owner()

        expect(currentOwner).to.eq(owner.address)
    })

    async function getTimestamp(bn: number | null) {
        const block = await ethers.provider.getBlock(bn!);

        return block!.timestamp;
    }

    describe("createAuction", async function () {
        it("creates auction correctly", async function () {
            const { auction } = await loadFixture(deploy)
            const duration = 60
            const tx = await auction.createAuction(
                ethers.parseEther("0.0001"),
                3,
                "fake item",
                duration
            )

            const cAuction = await auction.auctions(0)
            expect(cAuction.item).to.eq("fake item")
            const ts = await getTimestamp(tx.blockNumber)
            expect(cAuction.endsAt).to.eq(ts + duration)
        })
    })

    function delay(ms: number) {
        return new Promise(resolve => setTimeout(resolve, ms))
    }

    describe("buy", function () {
        it("allows to buy", async function () {
            const { seller, auction, buyer } = await loadFixture(deploy)
            await auction.connect(seller).createAuction(
                ethers.parseEther("0.0001"),
                3,
                "fake item",
                60
            )

            this.timeout(5000)
            await delay(1000)

            const buyTx = await auction.connect(buyer).
                buy(0, { value: ethers.parseEther("0.0001") })

            const cAuction = await auction.auctions(0)
            const finalPrice = cAuction.finalPrice

            let feeBigInt: bigint = (finalPrice * BigInt(10)) / BigInt(100);

            await expect(() => buyTx).
                to.changeEtherBalance(
                    seller, finalPrice - feeBigInt
                )

            await expect(buyTx)
                .to.emit(auction, 'AuctionEnded')
                .withArgs(0, finalPrice, buyer.address)

            await expect(
                auction.connect(buyer).
                    buy(0, { value: ethers.parseEther("0.0001") })
            ).to.be.revertedWith('Auction stopped')
        })
    })
})