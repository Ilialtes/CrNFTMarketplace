// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract CrNFTMarketPlace {
    // Struct to represent an NFT
    struct NFT {
        address owner;
        uint256 price;
        bool isForSale;
    }

    // Mapping from tokenId to NFT struct
    mapping(uint256 => NFT) public nfts;

    // Mapping from owner address to array of owned tokenIds
    mapping(address => uint256[]) public ownerNFTs;

    // State variables
    address public owner;
    uint256 public fee; // Fee to be paid to the owner for each sale
    uint256 public currentTokenId; // Counter for generating unique token IDs

    // Events
    event NFTMinted(address indexed recipient, uint256 tokenId, uint256 price);
    event NFTListed(address indexed owner, uint256 tokenId, uint256 price);
    event NFTSold(address indexed buyer, address indexed seller, uint256 tokenId, uint256 price);
    event NFTStateChanged(address indexed nftOwner, uint256 tokenId, bool isForSale);

    // Modifier to restrict function access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Modifier to verify that an NFT is for sale
    modifier isForSale(uint256 tokenId) {
        require(nfts[tokenId].isForSale == true, "NFT is not for sale");
        _;
    }

    // Modifier to check if the sender has enough funds to buy the NFT
    modifier hasEnoughFunds(uint256 price) {
        require(msg.value >= price, "Insufficient funds to buy NFT");
        _;
    }

    // Constructor to initialize the contract with an owner and a fee
    constructor(uint256 _fee) {
        owner = msg.sender;
        fee = _fee;
        currentTokenId = 1;  // Start tokenId from 1
    }

    // Function to mint a new NFT (only owner can mint)
    function mintNFT(address recipient, uint256 price) public onlyOwner {
        uint256 tokenId = currentTokenId;

        // Mint the NFT and set its initial state
        nfts[tokenId] = NFT({
            owner: recipient,
            price: price,
            isForSale: false
        });

        ownerNFTs[recipient].push(tokenId);  // Track the recipient's NFTs

        emit NFTMinted(recipient, tokenId, price);

        currentTokenId++; // Increment the tokenId for the next NFT
    }

    // Function to list an NFT for sale
    function listNFT(uint256 tokenId, uint256 price) public {
        require(nfts[tokenId].owner == msg.sender, "You do not own this NFT");

        // Update the NFT details
        nfts[tokenId].price = price;
        nfts[tokenId].isForSale = true;

        emit NFTListed(msg.sender, tokenId, price);
    }

    // Function to change the sale status of an NFT
    function changeState(uint256 tokenId, bool _isForSale) public {
        require(nfts[tokenId].owner == msg.sender, "Only the NFT owner can change its state");

        nfts[tokenId].isForSale = _isForSale;

        emit NFTStateChanged(msg.sender, tokenId, _isForSale);
    }

    // Function to sell an NFT
    function sellNFT(uint256 tokenId, address buyer) public payable isForSale(tokenId) hasEnoughFunds(nfts[tokenId].price) {
        uint256 price = nfts[tokenId].price;
        address seller = msg.sender;

        // Transfer ownership and funds
        payable(seller).transfer(price - fee);  // Seller receives the price minus fee
        payable(owner).transfer(fee);           // Owner receives the fee

        // Transfer ownership of the NFT
        nfts[tokenId].owner = buyer;
        nfts[tokenId].isForSale = false;

        // Update ownership records
        ownerNFTs[buyer].push(tokenId);
        removeNFTFromOwner(seller, tokenId); // Helper function to remove from seller

        emit NFTSold(buyer, seller, tokenId, price);
    }

    // Function to buy an NFT
    function buyNFT(uint256 tokenId) public payable isForSale(tokenId) hasEnoughFunds(nfts[tokenId].price) {
        uint256 price = nfts[tokenId].price;

        // Ensure correct token
        require(msg.value == price, "Incorrect currency value");

        // Transfer the NFT
        sellNFT(tokenId, msg.sender);
    }

    // Helper function to remove the sold NFT from the seller's list
    function removeNFTFromOwner(address seller, uint256 tokenId) internal {
        uint256[] storage tokens = ownerNFTs[seller];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];  // Replace with the last token
                tokens.pop();  // Remove the last element
                break;
            }
        }
    }

    // Function to
