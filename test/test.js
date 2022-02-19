
const { expect } = require("chai");
const { ethers } = require("hardhat");

// const addr1 = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
// const addr2 = '0x70997970c51812dc3a010c7d01b50e0d17dc79c8';

const tokenURI = "https://gateway.pinata.cloud/ipfs/Qme21raX3959cmSnKmHtUedmTT1SKBpWCJ8xxFjeTAFy7i";

describe("NineFoxNFT", function() {

    let nft;
    let addr1, addr2;

    async function resetState() {

        [addr1, addr2] = await ethers.getSigners();

        const Nft = await ethers.getContractFactory("NineFoxNFT");
        nft = await Nft.deploy();
        await nft.deployed();
    }

    async function mintNFT(address, tokenURI) {
        const tx = await nft.connect(address).mintNFT(address.address, tokenURI, {
            gasLimit: 500_000,
        });
    }

    async function ownerOf(tokenID) {
        return (await nft.ownerOf(tokenID)).toLowerCase();
    }

    async function safeTransferFrom(from, to, tokenID) {
        await nft["safeTransferFrom(address,address,uint256)"](from.address, to.address, tokenID);
    }

    async function stakeFox(from, tokenID) {
        await nft.connect(from).stake(tokenID);
    }

    it("Should allow deploying", async function () {
        await resetState();
        expect(parseInt(await nft.getToken())).to.equal(0);
    });

    it("Should allow minting", async function () {
        await mintNFT(addr1, tokenURI);
        expect(parseInt(await nft.getToken())).to.equal(1);
    });

    it("Should allow transfers of NFTs", async function () {
        await safeTransferFrom(addr1, addr2, 1);

        expect(await ownerOf(1)).to.equal(addr2.address.toLowerCase());
    });

    it("Should allow staking of NFTs", async function() {
        await stakeFox(addr2, 1);

        expect(await ownerOf(1)).to.equal(nft.address.toLowerCase());
    });

    it("Should allow checking of stake rewards", async function() {
        // Mint some NFTs to make the node produce more blocks
        await mintNFT(addr1, tokenURI);
        await mintNFT(addr1, tokenURI);

        const res = await nft.connect(addr2).calculateStakeRewards(1);
        console.log(parseInt(res));
    });
});