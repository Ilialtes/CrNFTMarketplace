// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract NFTMarketplace {
    address public owner;
    uint256 public marketplaceFee; // Fee as a percentage (e.g., 1% = 100)

    constructor(uint256 _fee) {
        owner = msg.sender;
        marketplaceFee = _fee;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool isSold;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public currentListingId;

    event NFTListed(uint256 listingId, address seller, address nftContract, uint256 tokenId, uint256 price);
    event NFTPurchased(uint256 listingId, address buyer, uint256 price);

    function listNFT(address nftContract, uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be greater than zero");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); // Transfer NFT to marketplace

        listings[currentListingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            isSold: false
        });

        emit NFTListed(currentListingId, msg.sender, nftContract, tokenId, price);

        currentListingId++;
    }

    function buyNFT(uint256 listingId) public payable {
        Listing storage listing = listings[listingId];
        require(!listing.isSold, "NFT is already sold");
        require(msg.value >= listing.price, "Insufficient payment");

        uint256 fee = (listing.price * marketplaceFee) / 10000;
        uint256 sellerProceeds = listing.price - fee;

        // Transfer fee to marketplace owner
        payable(owner).transfer(fee);
        // Transfer remaining funds to seller
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer NFT to buyer
        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);

        // Mark as sold
        listing.isSold = true;

        emit NFTPurchased(listingId, msg.sender, listing.price);
    }

    function cancelListing(uint256 listingId) public {
        Listing storage listing = listings[listingId];
        require(msg.sender == listing.seller, "Only the seller can cancel the listing");
        require(!listing.isSold, "NFT is already sold");

        // Transfer NFT back to seller
        IERC721(listing.nftContract).transferFrom(address(this), listing.seller, listing.tokenId);

        // Mark the listing as invalid
        listing.isSold = true;
    }

    function setMarketplaceFee(uint256 _fee) public onlyOwner {
        require(_fee >= 0, "Invalid fee");
        marketplaceFee = _fee;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
