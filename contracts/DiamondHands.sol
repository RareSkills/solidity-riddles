// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

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
    uint public LOCK = 1;

    struct NFTDeposit {
        address owner;
        uint256 id;
    }

    modifier nonReentrant() {
        require(LOCK == 1, "Reentrant call");
        LOCK = 2;
        _;
        LOCK = 1;
    }

    ///////////////////////// User Functions /////////////////////////

    /// @notice call this function to deposit your NFT and 1 Ether
    /// @param id the id of the NFT you want to deposit
    function playDiamondHands(uint256 id) external payable {
        require(!gameOver, "game is over");
        require(msg.value == 1 ether, "you must deposit 1 ether");
        require(deposits.length < 20, "only 20 NFTs can be deposited");
        nft.transferFrom(msg.sender, address(this), id);
        deposits.push(NFTDeposit({owner: msg.sender, id: id}));
    }

    /// @notice call this function to get your NFT back and lose your 1 Ether deposit
    ///         returns everyone's NFT to them
    /// @dev deletes the loser from the array of NFT deposits and transfers everyone's NFTs back to them
    function loseDiamondHands() external nonReentrant {
        bool onlyOwnercanCall;
        uint ownerindex;
        gameOver = true;
        // delete loser
        uint len = deposits.length;
        for (uint i = 0; i < len; i++) {
            nft.safeTransferFrom(address(this), deposits[i].owner, deposits[i].id);

            if (deposits[i].owner == msg.sender) {
                onlyOwnercanCall = true;
                ownerindex = i;
            }
        }
        require(onlyOwnercanCall, "only owner can call this function");
        delete deposits[ownerindex];
    }

    /// @notice Withdraw the 1 Ether deposit after the deadline
    /// @dev uses send() to transfer the ether to prevent griefing from infinite loops and revert on receive
    function withdraw() external {
        require(withdrawn == false, "already withdrawn");
        require(block.timestamp > deadline, "Can only withdraw after deadline");
        for (uint i = 0; i < deposits.length; i++) {
            if (deposits[i].owner != address(0)) {
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

// WINNER WINNER CHICKEN DINNER!!

contract ChickenBonds is ERC721 {
    address[] public owners = [
        0x17FaB9bBBF6Ba58aE78750494c919C4CE3C88664,
        0x2b9335B9221F5b7ae630c1DaF3fC2931bee6236F,
        0x7F07984e0a990Aa6e16b20e0af10F7610ED20f7D,
        0x51cA4e70721a14E8382cCC670b77A309E7f1769B,
        0x8CcA1c49789c164c7628087f463c54EED300be0f,
        0xDf3dd2845D71132D7C4ac1cce1F8db1660939146,
        0x7b09f82F2c10f8185e420C69DB54b7C71Ac8a70F,
        0x623aEFdF762435E620a227100ED233929F4deA9B,
        0x4cf67C8c46BF93888D50B30Ba2D1cd38447f96a7,
        0xac360f8ee49413CA84D9222154D62120F9D4D303,
        0xE8A804a378a52931FaFc336746Ae1073A0E2607c,
        0x4289647fCc540F2F906a72E5d30CE39A5FE1d738,
        0xf1053ADBC76D5Ad9e5aebD0241A4E2251ED17f6A,
        0xB7C7A7724e83BD4A658662E9870FfDeb97cCc78A,
        0xE07c2DeDcb5bDf2eec1C6A74eEDab43b3d18De74,
        0xA2812Fb61e8D3558475E717895A39D941B4b9cD5,
        0x929ff22543711D9222b3D21A85b776B7dF1206f9,
        0x4389FfFb1A029Ffd754b2040b9129e31A195fA12,
        0xA251736feEF3304cb4EB175b4f2C7B8d18aBd090
    ];

    constructor() ERC721("ChickenBonds", "CB") {
        for (uint i; i < owners.length; i++) {
            _mint(owners[i], i + 1);
        }
    }

    function FryChicken(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
