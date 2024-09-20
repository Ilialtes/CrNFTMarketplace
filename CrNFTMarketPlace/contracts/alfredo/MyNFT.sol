// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyNFT {
    uint256 public tokenCounter;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs;
    string public name;
    string public symbol;

    constructor() {
        name = "MyNFT";
        symbol = "NFT";
        tokenCounter = 0;
    }

    // Call mintNFT
    // string memory ipfsURI = "ipfs://<your_metadata_hash>";
    // uint256 tokenId = mintNFT(recipientAddress, ipfsURI);
    
    function mintNFT(address recipient, string memory _tokenURI) public returns (uint256) {
        uint256 newItemId = tokenCounter;
        _owners[newItemId] = recipient;
        _balances[recipient] += 1;

        // Associate the token ID with the IPFS URI
        _tokenURIs[newItemId] = _tokenURI;
        
        tokenCounter += 1;
        return newItemId;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenURIs[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from == _owners[tokenId], "Transfer not authorized");
        require(to != address(0), "Invalid address");

        _owners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] += 1;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
}
