// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// A community has just minted a new NFT project. To prevent the floor price from dropping
// the community must agree to not sell their NFTs for as long as possible.

// The diamond hands is a game of chicken. Whoever withdraws first loses their Ether deposit
// and must pay the gas to return everyone's NFTs. To prevent a denial of service from the array
// being too long, only 20 NFTs can be deposited.

// To play diamond hands, everyone deposits their NFT into the smart contract, along with 1 Ether.
// If someone withdraws their NFT before the deadline, they lose their 1 Ether deposit and everyone's
// NFTs are transferred back to the original owner, which means the paper hands person must pay the gas
// to return everyone's NFTs, in addition to losing their 1 Ether deposit.

// Maybe there is a way you can protect the floor price and lock everyone's NFT in the contract permanently

/// @author RareSkills
/// @notice A game of chicken to prevent the floor price from dropping
contract DiamondHands {
//////////////////////// Constant  ////////////////////////s
    IERC721 public immutable nft;

    
///////////////////////// Storage ///////////////////////// 
    NFTDeposit[] public deposits;
    bool public gameOver;
    uint public deadline;
    bool public withdrawn;

    struct NFTDeposit {
        address owner;
        uint256 id;
    }

///////////////////////// User Functions /////////////////////////

/// @notice call this function to deposit your NFT and 1 Ether
/// @param id the id of the NFT you want to deposit
    function playDiamondHands(uint256 id) external payable {
        unchecked{
        require(!gameOver, "game is over");
        require(msg.value == 1 ether, "you must deposit 1 ether");
        require(deposits.length < 20, "only 20 NFTs can be deposited");
        nft.transferFrom(msg.sender, address(this), id);
        deposits.push(NFTDeposit({owner: msg.sender, id: id}));
        }
    }

    /// @notice call this function to get your NFT back and lose your 1 Ether deposit
    ///         returns everyone's NFT to them
    /// @dev deletes the loser from the array of NFT deposits and transfers everyone's NFTs back to them
    function loseDiamondHands() external {
        bool onlyOwnercanCall;
        unchecked{
        gameOver = true;
        // delete loser
        for (uint i = 0 ; i < deposits.length; ){
            nft.safeTransferFrom(address(this),deposits[i].owner, deposits[i].id);
            if(deposits[i].owner == msg.sender){
                onlyOwnercanCall = true;
                delete deposits[i];
            }
                       
            i++;
        }   
        require(onlyOwnercanCall, "only owner can call this function");
        }
    }

/// @notice Withdraw the 1 Ether deposit after the deadline
/// @dev uses send() to transfer the ether to prevent griefing from infinite loops and revert on receive
    function withdraw() external {
        require(withdrawn == false, "already withdrawn");
        require(block.timestamp > deadline, "Can only withdraw after deadline");
        for(uint i = 0 ; i < deposits.length;i++){
            if(deposits[i].owner !=address(0) ){
                payable((deposits[i].owner)).send(1 ether);
            } 
        }
        withdrawn = true;
    }

//////////////////////////// Constructor //////////////////////////

   /// @dev constructor
   /// @param _nft the address of the NFT contract
    constructor(IERC721 _nft) {
        nft = _nft;
        deadline = block.timestamp + 1 days;
        
    }

}