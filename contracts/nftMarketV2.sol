// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721Holder.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

// @TODO add aave aToken & lendingPool
// IAtoken interface : Github(https://github.com/aave/protocol-v2/blob/ice/mainnet-deployment-03-12-2020/contracts/interfaces/IAToken.sol)

interface IAToken {

  event Mint(address indexed from, uint256 value, uint256 index);
  function mint(address user,uint256 amount,uint256 index) external returns (bool);
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);
  function burn(address user,address receiverOfUnderlying,uint256 amount,uint256 index) external;
  function mintToTreasury(uint256 amount, uint256 index) external;
  function transferOnLiquidation(address from, address to, uint256 value) external;
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);
}

// ILendingProtocal interface
// aave lending protocal
// interface ILendingPool {
//     function borrow(
//         address asset,
//         uint256 amount,
//         uint256 interestRateMode,
//         uint16 referralCode,
//         address onBehalfOf
//      ) external;
      
//     function repay(
//         address asset,
//         uint256 amount,
//         uint256 rateMode,
//         address onBehalfOf
//       ) external returns (uint256);
// }

contract nftMarketV2 {
    using SafeMath for uint256;

    struct erc721Offer {
        address lender; // origin owner
        address buyer; // future owner
        address asset;
        uint256 amount;
        uint256 lamount;
        bool lend;
        bool claimed;
    }

    event lendUpdated(address tokenAddress, uint256 tokenId);
    // owner( NFT address ) -> tokenId -> lend details
    mapping(address => mapping(uint256 => erc721Offer)) public offerList;

    mapping(uint256 => bool) public offerRepaid;

    function createLoan(address collateralNFT, uint256 tokenId) external payable{
        require(offerList[collateralNFT][tokenId].buyer == address(0), 'Token already lent'); // New Offer
        require(offerList[collateralNFT][tokenId].lend == false, 'Token already lent');
        // need to approve
        IERC721(collateralNFT).safeTransferFrom(msg.sender, address(this), tokenId);
        offerList[collateralNFT][tokenId] = erc721Offer(msg.sender, msg.sender, address(0), 0, 0 , false, false);
        
        emit lendUpdated(collateralNFT, tokenId);
    }

    function cancelLoan(address collateralNFT, uint256 tokenId) external payable{
        require(offerList[collateralNFT][tokenId].lender == msg.sender, 'Token not yours');
        require(offerList[collateralNFT][tokenId].lend == false, 'Token already lent');
        require(offerList[collateralNFT][tokenId].claimed == false, 'Token already claim');

        require(_attemptTransferFrom(collateralNFT, tokenId, msg.sender, address(this)),'Send NFT fail') ;

        offerList[collateralNFT][tokenId] = erc721Offer(address(0), address(0), address(0), 0, 0, false, true);

        emit lendUpdated(collateralNFT, tokenId);
    }

    function askPrice(address wantNFT, uint256 tokenId, address asset,uint256 amount) external {
        require(amount> 0,'amount must > 0');
        require(offerList[wantNFT][tokenId].amount < amount, 'You should pay higher');
        require(offerList[wantNFT][tokenId].claimed == false, 'Token already lent');
        // require(offerList[wantNFT][tokenId].asset == asset, 'Not this token');
        
        offerList[wantNFT][tokenId].asset = asset;
        offerList[wantNFT][tokenId].amount = amount;

        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        offerList[wantNFT][tokenId].buyer = msg.sender;
    }

    function goodDeal(address collateralNFT, uint256 tokenId) external payable {
        // require(offerList[collateralNFT][tokenId].buyer == msg.sender, 'Token not yours');
        require(offerList[collateralNFT][tokenId].lend == false, 'Token already lent');
        require(offerList[collateralNFT][tokenId].claimed == false, 'Token already claim');

        IERC721(collateralNFT).transferFrom(address(this), offerList[collateralNFT][tokenId].buyer, tokenId);
        IERC20(offerList[collateralNFT][tokenId].asset).transferFrom(address(this), msg.sender, offerList[collateralNFT][tokenId].amount);

        offerList[collateralNFT][tokenId] = erc721Offer(address(0), address(0), address(0),0, 0, false, true);
        emit lendUpdated(collateralNFT, tokenId);
    }
    // beta function
    function borrow(address collateralNFT, uint256 tokenId, uint256 amount) external {
        // lendingPool.borrow(token, amount, interestRateModel, 7, msg.sender);
        require(offerList[collateralNFT][tokenId].lender == msg.sender, 'Not you');
        require(offerList[collateralNFT][tokenId].claimed == false, 'Token already claim');
        
        offerList[collateralNFT][tokenId].lamount = amount;
        offerList[collateralNFT][tokenId].lend = true;
    }

    function liqudation(address collateralNFT, uint256 tokenId) external payable{
        require(offerList[collateralNFT][tokenId].lamount > 0,'');
        require(offerList[collateralNFT][tokenId].lend == true, '');
        require(offerList[collateralNFT][tokenId].lend == true, '');
        
        uint256 bPrice = offerList[collateralNFT][tokenId].amount.mul(95).div(100);
        IERC20(offerList[collateralNFT][tokenId].asset).transferFrom(address(this),  offerList[collateralNFT][tokenId].lender, bPrice);
        IERC20(offerList[collateralNFT][tokenId].asset).transferFrom(address(this),  msg.sender, offerList[collateralNFT][tokenId].amount.sub(bPrice));
        offerList[collateralNFT][tokenId] = erc721Offer(address(0), address(0), address(0), 0, 0, false, true);

        emit lendUpdated(collateralNFT, tokenId);

    }
    
    function callofferList(address collateralNFT, uint256 tokenId) public view returns(address){
        return(offerList[collateralNFT][tokenId].lender);
    }

    function _attemptTransferFrom(address _nftContract, uint256 _nftId, address _from, address _recipient) internal returns (bool) {
        _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).approve.selector, address(this), _nftId));
        (bool success, ) = _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).transferFrom.selector, _from, _recipient, _nftId));
        return success;
    }
    
}