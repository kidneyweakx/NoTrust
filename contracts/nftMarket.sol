// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721Holder.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract nftMarket is ERC721Holder {
    using SafeMath for uint256;
    address _admin;
    constructor() {
        _admin = msg.sender;
     }
    
    IERC721 public testNft; 
    IERC20 public aToken;


    mapping(uint => bool) _nftAvaliable;
    mapping(uint => uint) _nftReturn;
    mapping(uint => address) _nftBorrower;
    mapping(uint => bool) _protocalPermissoin;
    mapping(uint => address) _originOwner;



    function Received(address operator, 
        address from, 
        uint256 tokenId, 
        bytes memory data
    ) public returns(bytes4) {
        ERC721Holder.onERC721Received(operator, from, tokenId, data);
    }

    function lendNft(uint _nftId) public {
        require(msg.sender == testNft.ownerOf(_nftId),"NOT OWNER");

        _originOwner[_nftId] = msg.sender;
        _nftAvaliable[_nftId] = true;

        Received(msg.sender, msg.sender, _nftId, "");

        testNft.approve(_admin, _nftId);
        testNft.transferFrom(msg.sender, address(this), _nftId);
    }

    function borrowNft(uint _borrowNftId, uint _collateralId) public payable {
        require(_nftAvaliable[_borrowNftId] == true, "This NFT is not available to borrow");
        require(msg.sender == testNft.ownerOf(_collateralId), "You are not the owner of the collateral NFT");

        lendNft(_collateralId);

        _nftReturn[_borrowNftId] = block.timestamp + 2 minutes;

        _nftAvaliable[_borrowNftId] = false;

        _nftBorrower[_borrowNftId] = msg.sender;

        testNft.approve(_admin, _borrowNftId);
        testNft.transferFrom(msg.sender, address(this), _borrowNftId);
    }

    function requestRepossessionOfNft(uint _nftId) public {
        require(msg.sender == _originOwner[_nftId], "You are not the true owner of the provided NFT ID");
        require(block.timestamp > _nftReturn[_nftId], "It is too early to reposses NFT");
        require(msg.sender != testNft.ownerOf(_nftId), "You cannot reposses NFT that is in your possesion");

        _protocalPermissoin[_nftId] = true;
    }

   function protocolNftRepossession(uint _nftId) public {
        require(_nftAvaliable[_nftId] == false, "Provided NFT ID has not been borrowed");
        require(msg.sender == _admin, "Function caller is not the protocol creator address");
        require(_protocalPermissoin[_nftId] == true, "Protocol does not have permission to repossess this NFT");

        testNft.transferFrom(testNft.ownerOf(_nftId), _originOwner[_nftId], _nftId);
    }

     function returnNft(uint _nftId) public {
        require(msg.sender == testNft.ownerOf(_nftId), "You are not the borrower of provided NFT");
        require(_nftAvaliable[_nftId] == false, "The provided NFT has been borrowed");
        _nftAvaliable[_nftId] = true;
        testNft.approve(address(this), _nftId);
        Received(msg.sender, msg.sender, _nftId, "");
        testNft.transferFrom(msg.sender, address(this), _nftId);
    }

    function pullNft(uint _nftId) public {
        require(msg.sender == _originOwner[_nftId], "You are not the true owner of provided NFT");
        require(_nftAvaliable[_nftId] == true, "The provided NFT has been borrowed");
        _nftAvaliable[_nftId] = false;
        testNft.transferFrom(address(this), msg.sender, _nftId);
    }

    // view
    function isnftAvaliable(uint _nftId) public view returns (bool) {
        return _nftAvaliable[_nftId];
    }
    
    function ownerOf(uint _tokenId) public view returns (address) {
        return testNft.ownerOf(_tokenId);
    }

    function nftReturn(uint _nftId) public view returns (uint) {
        return _nftReturn[_nftId];
    }

    function nftBorrower(uint _nftId) public view returns (address) {
        return _nftBorrower[_nftId];
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function originOwner(uint _nftId) public view returns (address) {
        return _originOwner[_nftId];
    }

    function currentBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

}
