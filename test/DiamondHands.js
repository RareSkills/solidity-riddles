const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const { Provider } = require("@ethersproject/abstract-provider");

const NAME = "DiamondHands";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet,funder] = await ethers.getSigners();
        const chickenbonds = await ethers.getContractFactory("ChickenBonds");
        const chickencontract = await chickenbonds.deploy();
        await chickencontract.deployed();
        
        const diamondhands = await ethers.getContractFactory(NAME);
        const diamondcontract = await diamondhands.deploy(chickencontract.address);
        await diamondcontract.deployed();

       

        return { chickencontract, diamondcontract,attackerWallet,funder };
    }

    describe("exploit", async function () {
        let chickencontract, attackerWallet,diamondcontract,funder;
        before(async function () {
            ({ chickencontract,diamondcontract, attackerWallet,funder } = await loadFixture(setup));
            const owners = [  "0x17FaB9bBBF6Ba58aE78750494c919C4CE3C88664",  "0x2b9335B9221F5b7ae630c1DaF3fC2931bee6236F",  "0x7F07984e0a990Aa6e16b20e0af10F7610ED20f7D",  "0x51cA4e70721a14E8382cCC670b77A309E7f1769B",  "0x8CcA1c49789c164c7628087f463c54EED300be0f",  "0xDf3dd2845D71132D7C4ac1cce1F8db1660939146",  "0x7b09f82F2c10f8185e420C69DB54b7C71Ac8a70F",  "0x623aEFdF762435E620a227100ED233929F4deA9B",  "0x4cf67C8c46BF93888D50B30Ba2D1cd38447f96a7",  "0xac360f8ee49413CA84D9222154D62120F9D4D303",  "0xE8A804a378a52931FaFc336746Ae1073A0E2607c",  "0x4289647fCc540F2F906a72E5d30CE39A5FE1d738",  "0xf1053ADBC76D5Ad9e5aebD0241A4E2251ED17f6A",  "0xB7C7A7724e83BD4A658662E9870FfDeb97cCc78A",  "0xE07c2DeDcb5bDf2eec1C6A74eEDab43b3d18De74",  "0xA2812Fb61e8D3558475E717895A39D941B4b9cD5",  "0x929ff22543711D9222b3D21A85b776B7dF1206f9",  "0x4389FfFb1A029Ffd754b2040b9129e31A195fA12",  "0xA251736feEF3304cb4EB175b4f2C7B8d18aBd090"];

           for (let i = 0 ; i < owners.length ; i++){
               await helpers.impersonateAccount(owners[i]);
               let impersonatedSigner = await ethers.getSigner(owners[i]);
               await funder.sendTransaction({
                to:impersonatedSigner.address,
                value:ethers.utils.parseEther("1.1")
               })
               await chickencontract.connect(impersonatedSigner).approve(diamondcontract.address,i+1);
               await diamondcontract.connect(impersonatedSigner).playDiamondHands(i+1,{value:ethers.utils.parseEther("1")});
            } 
        });

        it("conduct your attack here", async function () {
        //    Your attack code goes here
           
        });

       

        after(async function () {
            await helpers.impersonateAccount('0x17FaB9bBBF6Ba58aE78750494c919C4CE3C88664');
               let impersonatedSigner = await ethers.getSigner('0x17FaB9bBBF6Ba58aE78750494c919C4CE3C88664');
               await expect(diamondcontract.connect(impersonatedSigner).loseDiamondHands()).to.be.reverted;
        });
    });
});
