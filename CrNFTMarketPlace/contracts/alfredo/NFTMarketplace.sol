// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTMarketplace {
    uint256 public listingFee;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        listingFee = 1;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private marketItems;
    uint256 private itemCounter;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable {
        require(price > 0, "Price must be greater than 0");
        require(msg.value == listingFee, "Listing fee required");

        itemCounter++;
        marketItems[itemCounter] = MarketItem(
            itemCounter,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        MyNFT(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        emit MarketItemCreated(itemCounter, nftContract, tokenId, msg.sender, address(0), price, false);
    }

    function buyMarketItem(uint256 itemId) public payable {
        MarketItem storage item = marketItems[itemId];
        require(item.price == msg.value, "Submit the asking price");
        require(item.sold == false, "Item already sold");

        item.seller.transfer(msg.value);
        MyNFT(item.nftContract).transferFrom(address(this), msg.sender, item.tokenId);
        item.owner = payable(msg.sender);
        item.sold = true;

        payable(owner).transfer(listingFee);
    }

    function fetchUnsoldItems() public view returns (MarketItem[] memory) {
        uint unsoldItemCount = itemCounter;
        uint currentIndex = 0;

        for (uint i = 1; i <= itemCounter; i++) {
            if (marketItems[i].owner == address(0)) {
                unsoldItemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 1; i <= itemCounter; i++) {
            if (marketItems[i].owner == address(0)) {
                items[currentIndex] = marketItems[i];
                currentIndex++;
            }
        }
        return items;
    }
}

interface MyNFT {
    function transferFrom(address from, address to, uint256 tokenId) external;
}
