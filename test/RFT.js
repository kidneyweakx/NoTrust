const {time} = require('@openzeppelin/test-helpers');
const { assert } = require('console');
const M = artifacts.require('nftMarketV2.sol');
const NFT = artifacts.require('testNFT.sol');
const DAI = artifacts.require('testDai.sol');

const DAI_AMOUNT = web3.utils.toWei('100000')
const SPEND_AMOUNT = web3.utils.toWei('1000000000')
const SHARE_AMOUNT = web3.utils.toWei('25000')
contract('nftMarketV2', async addresses =>{
    const [admin, buyer1, buyer2,b3,b4,_] = addresses;

    it('test ', async() => {
        const dai = await DAI.new();
        const nft = await NFT.new('Crypto NFT', 'CNFT');
        const marketplace = await M.new();
        await Promise.all([
            nft.mint(buyer1, 1),
            dai.mint(buyer2, SPEND_AMOUNT),
            dai.approve(marketplace.address, SPEND_AMOUNT, {from: buyer2})
        ])

        // buyer 1 create loan
        await nft.approve(marketplace.address, 1, {from: buyer1})
        // await time.increase(10)     
        await marketplace.createLoan(nft.address, 1, {from: buyer1})
        console.log('>not work') 
        const balanceNFT1 = await nft.balanceOf(marketplace.address);
        assert(balanceNFT1.toString() === web3.utils.toWei('1'))
        // buyer 2 lend dai
        
        await marketplace.askPrice(nft.address, 1, dai.address, DAI_AMOUNT, {from: buyer2});
        // buyer1 say goodDeal
        await marketplace.goodDeal(nft.address, 1)



        const balanceShareb1 = await dai.balanceOf(buyer1);
        assert(balanceShareb1.toString() === DAI_AMOUNT)

        const balanceNFT2 = await nft.balanceOf(buyer2);
        assert(balanceNFT2.toString() === web3.utils.toWei('1'))
    })
})