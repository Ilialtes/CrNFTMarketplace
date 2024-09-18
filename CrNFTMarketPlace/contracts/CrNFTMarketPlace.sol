
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

// 

contract CrNFTMarketPlace {
    struct NFT {
        address owner;
        uint256 price;
        bool isForSale;
    }

    mapping(address => NFT) public nfts;

    mapping(uint256 => NFT) public nftPrices;

    // State variables
    address public owner;
    uint256 public fee; 

    // Events
    event NFTListed(address indexed owner, uint256 price);
    event NFTSold(address indexed buyer, address indexed seller, uint256 price);
    event NFTAuctioned(address indexed seller, uint256 minPrice);
    event NFTStateChanged(address indexed nftOwner, bool isForSale);
    event NFTMinted(address indexed recipient, uint256 price);  


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier isForSale(address nftAddress) {
        require(nfts[nftAddress].isForSale == true, "NFT is not for sale");
        _;
    }

    modifier hasEnoughFunds(uint256 price) {
        require(msg.value >= price, "Insufficient funds to buy NFT");
        _;
    }

    constructor(uint256 _fee) {
        owner = msg.sender;
        fee = _fee;
    }

    function listNFT(uint256 price) public {
        require(nfts[msg.sender].owner == msg.sender, "You do not own this NFT");

        nfts[msg.sender].price = price;
        nfts[msg.sender].isForSale = true;
        nftPrices[price] = nfts[msg.sender];

        emit NFTListed(msg.sender, price);
    }

    function changeState(bool _isForSale) public {
        require(nfts[msg.sender].owner == msg.sender, "Only the NFT owner can change its state");

        nfts[msg.sender].isForSale = _isForSale;

        emit NFTStateChanged(msg.sender, _isForSale);
    }

    function sellNFT(address buyer) public payable isForSale(msg.sender) hasEnoughFunds(nfts[msg.sender].price) {
        uint256 price = nfts[msg.sender].price;
        address seller = msg.sender;

        payable(seller).transfer(price - fee);  
        payable(owner).transfer(fee);           

        nfts[seller].owner = buyer;
        nfts[seller].isForSale = false;

        emit NFTSold(buyer, seller, price);
    }

    function buyNFT(address nftAddress) public payable isForSale(nftAddress) hasEnoughFunds(nfts[nftAddress].price) {
        uint256 price = nfts[nftAddress].price;

        require(msg.value == price, "Incorrect currency value");

        sellNFT(msg.sender);
    }

    function auctionNFT(uint256 minPrice) public {
        require(nfts[msg.sender].owner == msg.sender, "You do not own this NFT");

        emit NFTAuctioned(msg.sender, minPrice);
    }

    function changeNFTPrice(uint256 newPrice) public {
        require(nfts[msg.sender].owner == msg.sender, "Only the NFT owner can change the price");

        nfts[msg.sender].price = newPrice;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function mintNFT(address recipient, uint256 price) public onlyOwner {
        require(nfts[recipient].owner == address(0), "Recipient already owns an NFT");

        nfts[recipient] = NFT({
            owner: recipient,
            price: price,
            isForSale: false
        });

        nftPrices[price] = nfts[recipient];

        emit NFTMinted(recipient, price);
    }
    
    
}