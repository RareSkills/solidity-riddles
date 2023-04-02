//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

// To encourage NFT minters to hold their NFTs, the devs are allowing
// buyers to stake their NFT and collect rewards. However, you can only
// stake your NFT one time, so better FOMO stake your NFT to collect
// rewards while you still have the opportunity! To ensure fairness,
// nobody can claim more than half the supply in the contract.
//
// The contract starts with 100 tokens (18 decimals). You start with 1 NFT.
//
// Your goal is to drain all the tokens.

contract RewardToken is ERC20Capped {
    constructor(address depositoor) ERC20("Token", "TK") ERC20Capped(1000e18) {
        // becuz capped is funny https://forum.openzeppelin.com/t/erc20capped-immutable-variables-cannot-be-read-during-contract-creation-time/6174/4
        ERC20._mint(depositoor, 100e18);
    }
}

contract NftToStake is ERC721 {
    constructor(address attacker) ERC721("NFT", "NFT") {
        _mint(attacker, 42);
    }
}

contract Depositoor is IERC721Receiver {
    IERC721 public nft;
    IERC20 public rewardToken;
    uint256 public constant REWARD_RATE = 10e18 / uint256(1 days);
    bool init;

    constructor(IERC721 _nft) {
        nft = _nft;
        alreadyUsed[0] = true;
    }

    struct Stake {
        uint256 depositTime;
        uint256 tokenId;
    }

    mapping(uint256 => bool) public alreadyUsed;
    mapping(address => Stake) public stakes;

    function setRewardToken(IERC20 _rewardToken) external {
        require(!init);
        init = true;
        rewardToken = _rewardToken;
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == address(nft), "wrong NFT");
        require(!alreadyUsed[tokenId], "can only stake once");

        alreadyUsed[tokenId] = true;
        stakes[from] = Stake({depositTime: block.timestamp, tokenId: tokenId});

        return IERC721Receiver.onERC721Received.selector;
    }

    function claimEarnings(uint256 _tokenId) public {
        require(
            stakes[msg.sender].tokenId == _tokenId && _tokenId != 0,
            "not your NFT"
        );
        payout(msg.sender);
        stakes[msg.sender].depositTime = block.timestamp;
    }

    function withdrawAndClaimEarnings(uint256 _tokenId) public {
        require(
            stakes[msg.sender].tokenId == _tokenId && _tokenId != 0,
            "not your NFT"
        );
        payout(msg.sender);
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete stakes[msg.sender];
    }

    function payout(address _a) private {
        uint256 amountToSend = (block.timestamp - stakes[_a].depositTime) *
            REWARD_RATE;

        if (amountToSend > 50e18) {
            amountToSend = 50e18;
        }
        if (amountToSend > rewardToken.balanceOf(address(this))) {
            amountToSend = rewardToken.balanceOf(address(this));
        }

        rewardToken.transfer(_a, amountToSend);
    }
}
