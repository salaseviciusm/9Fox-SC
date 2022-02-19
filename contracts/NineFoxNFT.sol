//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NineFoxNFT is ERC721URIStorage, Ownable, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct StakedToken {
        address owner;
        uint256 timeStaked;
    }

    struct Attributes {
        uint32 health;
        uint32 strength;
        uint32 defense;
    }

    // Mapping from tokenId to the owner's address
    mapping(uint256 => StakedToken) private _stakedTokens;

    // Mapping from tokenID to the token's attributes
    mapping(uint256 => Attributes) private _tokenAttributes;

    event FoxStaked(address staker, uint256 tokenId);
    event FoxUnstaked(address owner, uint256 tokenId);

    modifier onlyFoxOwnerOrApproved(uint256 tokenId) {
        address owner = ERC721.ownerOf(tokenId);
        address operator = ERC721.getApproved(tokenId);
        require(
            msg.sender == owner || msg.sender == operator,
            "9Fox: Caller is not owner nor approved to this Fox"
        );
        _;
    }

    modifier notAlreadyStaked(uint256 tokenId) {
        address owner = _stakedTokens[tokenId].owner;
        require(owner == address(0), "9Fox: Fox is already staked");
        _;
    }

    modifier staked(uint256 tokenId) {
        address owner = _stakedTokens[tokenId].owner;
        require(owner != address(0), "9Fox: Fox is not being staked");
        _;
    }

    constructor() ERC721("NineFoxTails", "NFT") {}

    function mintNFT(address recipient, string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function mintNFT(
        address recipient,
        string memory tokenURI,
        Attributes memory attributes
    ) public onlyOwner returns (uint256) {
        uint256 tokenID = mintNFT(recipient, tokenURI);

        _tokenAttributes[tokenID] = attributes;
        return tokenID;
    }

    function getAttributes(uint256 tokenID)
        external
        view
        returns (Attributes memory)
    {
        return _tokenAttributes[tokenID];
    }

    function setAttributes(uint256 tokenID, Attributes memory attributes)
        external
        onlyOwner
    {
        _tokenAttributes[tokenID] = attributes;
    }

    function getToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    function stake(uint256 tokenId)
        external
        notAlreadyStaked(tokenId)
        onlyFoxOwnerOrApproved(tokenId)
    {
        ERC721.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function unstake(uint256 tokenId) external onlyFoxOwnerOrApproved(tokenId) {
        address owner = _stakedTokens[tokenId].owner;
        require(owner != address(0), "9Fox: This Fox is not staked");

        ERC721.safeTransferFrom(address(this), owner, tokenId);

        _stakedTokens[tokenId].owner = address(0);

        emit FoxUnstaked(owner, tokenId);
    }

    function calculateStakeRewards(uint256 tokenId)
        external
        view
        staked(tokenId)
        returns (uint256)
    {
        // TODO: only let NFT owner check rewards
        uint256 timeStaked = _stakedTokens[tokenId].timeStaked;
        return (block.timestamp - timeStaked) / 1 days;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Can someone call this method and set themselves to the owner?
        _stakedTokens[tokenId] = StakedToken(from, block.timestamp);
        ERC721.approve(from, tokenId);

        emit FoxStaked(from, tokenId);

        return NineFoxNFT.onERC721Received.selector;
    }
}
