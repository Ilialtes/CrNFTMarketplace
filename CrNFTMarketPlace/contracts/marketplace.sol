
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;


// NFT stuct - con estado, addres

// Mapping de Address a NFT

// Mapping del precio al struct de NFT *

// *** Funciones
// - sell
// - buy
// - list
// - subasta *
// - changeState
// - conexion con las wallets
// - contructor a un owner
// - fee para el owner
// - change value

// *** Events al cambiar de estado

// *** Require 
// - solo owner puede vender
// - Change sel status
// - comprobar fondos para comprar 
// - comprobar stado de NFT antes de comprar
// - solo el owner puede cambiar precio de nft
// - verificar que sea la misma moneda

contract NFTMarketplace {
    // Struct to represent an NFT
    struct NFT {
        address owner;
        uint256 price;
        bool isForSale;
    }

    // Mapping from an address to an NFT
    mapping(address => NFT) public nfts;

    // Mapping from price to NFT struct
    mapping(uint256 => NFT) public nftPrices;

    // State variables
    address public owner;
    uint256 public fee; // Fee to be paid to the owner for each sale

    // Events
    event NFTListed(address indexed owner, uint256 price);
    event NFTSold(address indexed buyer, address indexed seller, uint256 price);
    event NFTAuctioned(address indexed seller, uint256 minPrice);
    event NFTStateChanged(address indexed nftOwner, bool isForSale);

    // Modifier to restrict function access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Modifier to verify that an NFT is for sale
    modifier isForSale(address nftAddress) {
        require(nfts[nftAddress].isForSale == true, "NFT is not for sale");
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
    }

    // Function to list an NFT for sale
    function listNFT(uint256 price) public {
        require(nfts[msg.sender].owner == msg.sender, "You do not own this NFT");

        // Update the NFT details
        nfts[msg.sender].price = price;
        nfts[msg.sender].isForSale = true;
        nftPrices[price] = nfts[msg.sender];

        emit NFTListed(msg.sender, price);
    }

    // Function to change the sale status of an NFT
    function changeState(bool _isForSale) public {
        require(nfts[msg.sender].owner == msg.sender, "Only the NFT owner can change its state");

        nfts[msg.sender].isForSale = _isForSale;

        emit NFTStateChanged(msg.sender, _isForSale);
    }

    // Function to sell an NFT
    function sellNFT(address buyer) public payable isForSale(msg.sender) hasEnoughFunds(nfts[msg.sender].price) {
        uint256 price = nfts[msg.sender].price;
        address seller = msg.sender;

        // Transfer ownership and funds
        payable(seller).transfer(price - fee);  // Seller receives the price minus fee
        payable(owner).transfer(fee);           // Owner receives the fee

        nfts[seller].owner = buyer;
        nfts[seller].isForSale = false;

        emit NFTSold(buyer, seller, price);
    }

    // Function to buy an NFT
    function buyNFT(address nftAddress) public payable isForSale(nftAddress) hasEnoughFunds(nfts[nftAddress].price) {
        uint256 price = nfts[nftAddress].price;

        // Ensure correct token
        require(msg.value == price, "Incorrect currency value");

        // Transfer the NFT
        sellNFT(msg.sender);
    }

    // Function for auctioning an NFT (for simplicity, we'll assume a minimum price for now)
    function auctionNFT(uint256 minPrice) public {
        require(nfts[msg.sender].owner == msg.sender, "You do not own this NFT");

        emit NFTAuctioned(msg.sender, minPrice);
        // Auction logic can be implemented here
    }

    // Function to change the price of an NFT
    function changeNFTPrice(uint256 newPrice) public {
        require(nfts[msg.sender].owner == msg.sender, "Only the NFT owner can change the price");

        nfts[msg.sender].price = newPrice;
    }

    // Function to withdraw funds for the contract owner
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}