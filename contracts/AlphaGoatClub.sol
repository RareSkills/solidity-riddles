//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

// Do not use this code in production!
contract AlphaGoatClubPrototypeNFT is ERC721("AlphaGoatClubPrototypeNFT", "AGCNPFT"), Ownable2Step {
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(bytes => bool) public usedSignatures;
    mapping(address => uint256) public commitBlock;
    string _tokenBaseURI = "https://storage.googleapis.com/alpha-goat-club/metadata/goat";

    uint256 constant BLOCK_COMMIT = 5;

    bool public publicSale;
    address public signer;

    modifier alreadyComitted() {
        uint256 _commitBlock = commitBlock[msg.sender];
        require(_commitBlock != 0, "NOT_COMMITED");
        require(block.number >= _commitBlock + BLOCK_COMMIT, "INSUFFICIENT_BLOCKS");
        _;
    }

    constructor() {
        signer = msg.sender;
    }

    function changeSigner(address newAddress) public onlyOwner {
        signer = newAddress;
    }

    /// @notice less of a rug pull, more of a magic carpet ride
    function rugPullURI(string calldata newURI) public onlyOwner {
        _tokenBaseURI = newURI;
    }

    function togglePublicMint() public onlyOwner {
        publicSale = !publicSale;
    }

    /// @notice because bots like to frontrun free nft mints, you need to commit
    ///         and wait 5 blocks. Technically, bots can still copy your tx for
    ///         committing, but this is not a high value mint, so it's fine.
    function commit() external {
        require(commitBlock[msg.sender] == 0, "ALREADY_COMMITED");
        commitBlock[msg.sender] = block.number;
    }

    /// @notice public sale. Only works if public mint is open.
    /// @dev we can't stop you from using separate addresses to mint more NFTs
    ///      so please be a nice whitehat and only mint one.
    function mint(uint256 id) external alreadyComitted {
        require(publicSale, "NOT_PUBLIC_SALE");
        require(!_exists(id), "ALREADY_MINTED");
        commitBlock[msg.sender] = 0;
        _safeMint(msg.sender, id);
    }

    /// @notice only for exclusive buyers. Minting an NFT with id 5 or greater
    ///         won't give you a cool goat.
    /// @dev we can't stop you from using separate addresses to mint more NFTs
    ///      so please be nice whitehat and only mint one.
    function exclusiveBuy(uint256 id, bytes32 hash_, bytes memory signature) external alreadyComitted {
        require(matchAddressSigner(hash_, signature), "DIRECT_MINT_DISALLOWED");
        require(usedSignatures[signature] == false, "SIGNATURE_ALREADY_USED");
        require(!_exists(id), "ALREADY_MINTED");
        usedSignatures[signature] = true;

        commitBlock[msg.sender] = 0;
        _safeMint(msg.sender, id);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));
    }

    function matchAddressSigner(bytes32 hash_, bytes memory signature) private view returns (bool) {
        return signer == hash_.recover(signature);
    }
}
