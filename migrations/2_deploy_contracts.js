var M = artifacts.require('nftMarketV2.sol');
var NFT = artifacts.require('testNFT.sol');
var DAI = artifacts.require('testDai.sol');
module.exports = function(deployer) {
  deployer.deploy(M);
  deployer.deploy(NFT);
  deployer.deploy(DAI);
};
