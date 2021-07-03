// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721Holder.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

// interface aToken{
// @TODO add aave aToken & lendingPool
// }
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

contract nftMarketV2 is ERC721Holder {
    using SafeMath for uint256;

    IERC20 public aToken;

    struct ERC721ForLend {
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
    mapping(address => mapping(uint256 => ERC721ForLend)) public lendList;

    function createLoan(address collateralNFT, uint256 tokenId) external payable{
        require(lendList[collateralNFT][tokenId].buyer == address(0), 'Token already lent');
        require(lendList[collateralNFT][tokenId].lend == false, 'Token already lent');
        // need to approve
        IERC721(collateralNFT).transferFrom(msg.sender, address(this), tokenId);
        IERC721(collateralNFT).approve(address(this), tokenId);
        lendList[collateralNFT][tokenId] = ERC721ForLend(msg.sender, msg.sender, address(0), 0, 0 , false, false);
        emit lendUpdated(collateralNFT, tokenId);

    }

    function cancelLoan(address collateralNFT, uint256 tokenId) external{
        require(lendList[collateralNFT][tokenId].buyer == msg.sender, 'Token not yours');
        require(lendList[collateralNFT][tokenId].lend == false, 'Token already lent');
        require(lendList[collateralNFT][tokenId].claimed == false, 'Token already claim');

        IERC721(collateralNFT).transferFrom(address(this), msg.sender, tokenId);

        lendList[collateralNFT][tokenId] = ERC721ForLend(address(0), address(0), address(0), 0, 0, false, true);

        emit lendUpdated(collateralNFT, tokenId);
    }

    function askPrice(address wantNFT, uint256 tokenId, address asset,uint256 amount) external {
        require(amount> 0,'amount must > 0');
        require(lendList[wantNFT][tokenId].amount < amount, 'You should pay higher');
        require(lendList[wantNFT][tokenId].claimed == false, 'Token already lent');
        require(lendList[wantNFT][tokenId].asset == asset, 'Not this token');
        
        lendList[wantNFT][tokenId].amount = amount;

        IERC20(asset).approve(msg.sender, 1e18);
        
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        lendList[wantNFT][tokenId].buyer = msg.sender;
    }

    function goodDeal(address collateralNFT, uint256 tokenId) external {
        // require(lendList[collateralNFT][tokenId].buyer == msg.sender, 'Token not yours');
        require(lendList[collateralNFT][tokenId].lend == false, 'Token already lent');
        require(lendList[collateralNFT][tokenId].claimed == false, 'Token already claim');

        IERC721(collateralNFT).transferFrom(address(this), lendList[collateralNFT][tokenId].buyer, tokenId);
        IERC20(lendList[collateralNFT][tokenId].asset).transferFrom(address(this), msg.sender, lendList[collateralNFT][tokenId].amount);

        lendList[collateralNFT][tokenId] = ERC721ForLend(address(0), address(0), address(0),0, 0, false, true);
        emit lendUpdated(collateralNFT, tokenId);
    }
    // beta function
    function borrow(address collateralNFT, uint256 tokenId, uint256 amount) external {
        // lendingPool.borrow(token, amount, interestRateModel, 7, msg.sender);
        require(lendList[collateralNFT][tokenId].lender == msg.sender, 'Not you');
        require(lendList[collateralNFT][tokenId].claimed == false, 'Token already claim');
        
        lendList[collateralNFT][tokenId].lamount = amount;
        lendList[collateralNFT][tokenId].lend = true;
    }

    function liqudation(address collateralNFT, uint256 tokenId, uint256 amount) external {
        require(lendList[collateralNFT][tokenId].lamount > 0,'');
        require(lendList[collateralNFT][tokenId].lend == true, '');
        require(lendList[collateralNFT][tokenId].lend == true, '');
        IERC721(collateralNFT).transferFrom(address(this), msg.sender, tokenId);
        IERC20(lendList[collateralNFT][tokenId].asset).transferFrom(address(this), msg.sender, lendList[collateralNFT][tokenId].amount - amount);

        lendList[collateralNFT][tokenId] = ERC721ForLend(address(0), address(0), address(0),0, 0, false, true);
        emit lendUpdated(collateralNFT, tokenId);

    }
    
    function calllendlist(address collateralNFT, uint256 tokenId) public view returns(address){
        return(lendList[collateralNFT][tokenId].lender);
    }


}