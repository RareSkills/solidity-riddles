//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/*

$$$$$$$$\                                            $$$$$$$$\                  
$$  _____|                                           $$  _____|                 
$$ |   $$\   $$\  $$$$$$\   $$$$$$\  $$\   $$\       $$ |    $$$$$$\  $$\   $$\ 
$$$$$\ $$ |  $$ |$$  __$$\ $$  __$$\ $$ |  $$ |      $$$$$\ $$  __$$\ \$$\ $$  |
$$  __|$$ |  $$ |$$ |  \__|$$ |  \__|$$ |  $$ |      $$  __|$$ /  $$ | \$$$$  / 
$$ |   $$ |  $$ |$$ |      $$ |      $$ |  $$ |      $$ |   $$ |  $$ | $$  $$<  
$$ |   \$$$$$$  |$$ |      $$ |      \$$$$$$$ |      $$ |   \$$$$$$  |$$  /\$$\ 
\__|    \______/ \__|      \__|       \____$$ |      \__|    \______/ \__/  \__|
                                     $$\   $$ |                                 
                                     \$$$$$$  |                                 
                                      \______/                                  

$$$$$$$$\        $$\                           $$\                 $$\   $$\ $$$$$$$$\ $$$$$$$$\ 
$$  _____|       \__|                          $$ |                $$$\  $$ |$$  _____|\__$$  __|
$$ |    $$$$$$\  $$\  $$$$$$\  $$$$$$$\   $$$$$$$ | $$$$$$$\       $$$$\ $$ |$$ |         $$ |   
$$$$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ $$  __$$ |$$  _____|      $$ $$\$$ |$$$$$\       $$ |   
$$  __|$$ |  \__|$$ |$$$$$$$$ |$$ |  $$ |$$ /  $$ |\$$$$$$\        $$ \$$$$ |$$  __|      $$ |   
$$ |   $$ |      $$ |$$   ____|$$ |  $$ |$$ |  $$ | \____$$\       $$ |\$$$ |$$ |         $$ |   
$$ |   $$ |      $$ |\$$$$$$$\ $$ |  $$ |\$$$$$$$ |$$$$$$$  |      $$ | \$$ |$$ |         $$ |   
\__|   \__|      \__| \_______|\__|  \__| \_______|\_______/       \__|  \__|\__|         \__|   
                                                                                                                                                                                                                                                                                               
*/

// You didn't get on the presale for the FurryFoxFriends NFTs?
// No worries, you can still get one!
contract FurryFoxFriends is ERC721("FurryFoxFriends", "F3"), Ownable2Step {
    using MerkleProof for bytes32;

    bytes32 merkleRoot;
    uint256 totalSupply;
    bool isPublicSale;
    mapping(address => bool) alreadyMinted;
    mapping(bytes32 => bool) alreadyUsedLeaf;

    function openPresale() external onlyOwner {
        isPublicSale = true;
    }

    function setNewMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function presaleMint(bytes32[] calldata proof, bytes32 leaf) external {
        require(MerkleProof.verifyCalldata(proof, merkleRoot, leaf), "not verified");
        require(!alreadyMinted[msg.sender], "already minted");
        require(!alreadyUsedLeaf[leaf], "leaf already used");

        totalSupply++;
        _mint(msg.sender, totalSupply - 1);
    }

    function mint() external {
        require(isPublicSale, "public sale not open");

        totalSupply++;
        _mint(msg.sender, totalSupply - 1);
    }
}
