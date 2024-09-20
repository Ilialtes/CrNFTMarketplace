// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract NFTMarketplace {
    address public owner;
    uint256 public fee; 

    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTPurchased(address indexed buyer, uint256 indexed tokenId, uint256 price, uint256 fee);

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

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(uint256 _feePercent) {
        owner = msg.sender;
        fee = _feePercent; 
    }

    function mint(string memory _tokenURI) external {
        uint256 newTokenId = totalSupply + 1;

        nfts[newTokenId] = NFT({
            tokenId: newTokenId,
            owner: msg.sender,
            tokenURI: _tokenURI
        });

        ownerTokens[msg.sender].push(newTokenId);

        totalSupply++;

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

    function purchaseNFT(uint256 _tokenId) external payable {
        Listing memory listing = listings[_tokenId];

        require(listing.active, "NFT is not for sale");
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 price = listing.price;
        address seller = listing.seller;

        uint256 fee2 = (price * fee) / 100;
        uint256 sellerAmount = price - fee2;

        nfts[_tokenId].owner = msg.sender;
        removeTokenFromOwner(seller, _tokenId);
        ownerTokens[msg.sender].push(_tokenId);

        listings[_tokenId].active = false;

        payable(owner).transfer(fee);

        payable(seller).transfer(sellerAmount);

        emit NFTPurchased(msg.sender, _tokenId, price, fee);
    }

    function removeTokenFromOwner(address _owner, uint256 _tokenId) internal {
        uint256[] storage tokens = ownerTokens[_owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenId) {
                tokens[i] = tokens[tokens.length - 1]; 
                tokens.pop(); 
                break;
            }
        }
    }

    function getOwnerTokens(address _owner) external view returns (uint256[] memory) {
        return ownerTokens[_owner];
    }

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return nfts[_tokenId].tokenURI;
    }

}
