// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFTMarketplace is Ownable, ReentrancyGuard , Pausable{
    uint256 private  fee;

    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event NFTListed(uint256 indexed tokenId, uint256 price);

    event NFTPurchased(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price,
        uint256 fee
    );

    event Paused();
    event Unpaused();

    struct NFT {
        uint256 tokenId;
        address owner;
        string tokenURI;
    }

    struct Listing {
        uint256 price;
        address seller;
        bool active;
    }

    uint256 public totalSupply;
    mapping(uint256 => NFT) public nfts;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) public ownerTokens;
    mapping(bytes32 => bool) private _tokenURIExists;

    constructor(uint256 _feePercent) Ownable(msg.sender){
        fee = _feePercent;
        _setTotalSupply(0);
    }

    modifier unique_TokenURI(string memory tokenUri) {
        require(
            !_tokenURIExists[keccak256(abi.encodePacked(tokenUri))],
            "Token URI already exists"
        );
        _;
    }

    function _isNotEmptyString(string memory str) internal pure returns (bool) {
        return bytes(str).length > 0;
    }

    function _setTotalSupply(uint256 newNumber) internal {
        totalSupply = newNumber;
    }

    function _incrementTotalSupply() internal {
        totalSupply++;
    }

    function pause() public onlyOwner {
        _pause();
        emit Paused();
    }

    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused();
    }

    function mint(string memory _tokenURI)
        external
        whenNotPaused
        unique_TokenURI(_tokenURI)
    {
        require(_isNotEmptyString(_tokenURI), "Token URI is empty!");

        uint256 newTokenId = totalSupply + 1;

        nfts[newTokenId] = NFT({
            tokenId: newTokenId,
            owner: msg.sender,
            tokenURI: _tokenURI
        });

        ownerTokens[msg.sender].push(newTokenId);

        _tokenURIExists[keccak256(abi.encodePacked(_tokenURI))] = true;

        _incrementTotalSupply();

        emit NFTMinted(msg.sender, newTokenId);
    }

    function listNFT(uint256 _tokenId, uint256 _price) external {
        require(nfts[_tokenId].owner == msg.sender, "Not the owner");
        require(_price > 0, "Price must be greater than zero");

        listings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            active: true
        });

        emit NFTListed(_tokenId, _price);
    }

    function purchaseNFT(uint256 _tokenId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Listing memory listing = listings[_tokenId];

        require(listing.active, "NFT is not for sale");
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 price = listing.price;
        address seller = listing.seller;

        require(seller != address(0), "Seller address is zero");
        require(owner() != address(0), "Owner address is zero");
        require(
            nfts[_tokenId].owner == seller,
            "Seller no longer owns this NFT"
        );

        uint256 feeAmount = (price * fee) / 100;
        uint256 sellerAmount = price - feeAmount;

        nfts[_tokenId].owner = msg.sender;
        _removeTokenFromOwner(seller, _tokenId);
        ownerTokens[msg.sender].push(_tokenId);

        listings[_tokenId].active = false;

        (bool sentToOwner, ) = owner().call{value: feeAmount}("");
        require(sentToOwner, "Failed to send fee to owner");

        (bool sentToSeller, ) = seller.call{value: sellerAmount}("");
        require(sentToSeller, "Failed to send amount to seller");

        uint256 excessAmount = msg.value - price;
        if (excessAmount > 0) {
            (bool refunded, ) = msg.sender.call{value: excessAmount}("");
            require(refunded, "Failed to refund excess amount");
        }
    }

    function _removeTokenFromOwner(address _owner, uint256 _tokenId)
        internal
        whenNotPaused
    {
        uint256[] storage tokens = ownerTokens[_owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    function getOwnerTokens(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerTokens[_owner];
    }

    function getTokenURI(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        return nfts[_tokenId].tokenURI;
    }
}
