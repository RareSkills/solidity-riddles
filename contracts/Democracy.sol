// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * Democracy NFT: One hodler, one vote!
 *
 * You are the current challenger candidate in the latest "Democracy NFT"
 * election. The project is committed to perfecting fair and democratic
 * on-chain voting in the NFT space. It even pays each hodler to vote!
 *
 * Each NFT hodler can vote for their preferred nominee and the winner will
 * become the new contract owner. The only problem is that the current
 * incumbent has rigged the outcome to ensure that once your vote has been
 * cast, the election will end with them as the winner...
 *
 * Your goal is to drain the contract's entire balance.
 */
contract Democracy is Ownable, ERC721 {
    uint256 public PRICE = 1_000 ether;
    uint256 public TOTAL_SUPPLY_CAP = 10;

    address public incumbent;
    address public challenger;
    mapping(address => bool) public voted;
    mapping(address => uint256) public votes;
    bool public electionCalled = false;

    modifier electionNotYetCalled() {
        require(!electionCalled, "DemocracyNft: Election has ended");
        _;
    }

    modifier contractBalanceIsGreaterThanZero() {
        require(
            address(this).balance > 0,
            "DemocracyNft: Insufficient contract balance"
        );
        _;
    }

    modifier nomineeIsValid(address nominee) {
        require(
            nominee == incumbent || nominee == challenger,
            "DemocracyNft: Must vote for incumbent or challenger"
        );
        _;
    }

    modifier hodlerNotYetVoted() {
        require(!voted[msg.sender], "DemocracyNft: One hodler, one vote");
        _;
    }

    modifier callerIsNotAContract() {
        require(
            tx.origin == msg.sender,
            "DemocracyNft: Feature available to EOAs only"
        );
        _;
    }

    constructor() payable ERC721("Democracy NFT", "DMRCY") {
        incumbent = owner();
    }

    function nominateChallenger(address challenger_) external {
        require(
            challenger == address(0),
            "DemocracyNft: Challenger already nominated"
        );

        challenger = challenger_;

        // Rig the election!
        _rigElection();
    }

    function vote(address nominee)
        external
        contractBalanceIsGreaterThanZero
        electionNotYetCalled
        nomineeIsValid(nominee)
        hodlerNotYetVoted
    {
        // Check NFT balance
        uint256 hodlerNftBalance = balanceOf(msg.sender);
        require(
            hodlerNftBalance > 0,
            "DemocracyNft: Voting only for NFT hodlers"
        );

        // Log votes
        votes[nominee] += hodlerNftBalance;
        voted[msg.sender] = true;

        // Tip hodler for doing their civic duty
        payable(msg.sender).call{value: address(this).balance / 10}("");

        // Once all hodlers have voted, call election
        if (votes[incumbent] + votes[challenger] >= TOTAL_SUPPLY_CAP) {
            _callElection();
        }
    }

    function mint(address to, uint256 tokenId)
        external
        payable
        callerIsNotAContract
        onlyOwner
    {
        require(
            msg.value >= PRICE,
            "DemocracyNft: Insufficient transaction value"
        );

        _mint(to, tokenId);
    }

    function approve(address to, uint256 tokenId)
        public
        override
        callerIsNotAContract
    {
        _approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override callerIsNotAContract {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override callerIsNotAContract {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _safeTransfer(from, to, tokenId, "");
    }

    function withdrawToAddress(address address_) external onlyOwner {
        payable(address_).call{value: address(this).balance}("");
    }

    function _callElection() private {
        electionCalled = true;

        if (votes[challenger] > votes[incumbent]) {
            incumbent = challenger;
            _transferOwnership(challenger);

            challenger = address(0);
        }
    }

    function _rigElection() private {
        // Mint voting tokens to challenger
        _mint(challenger, 0);
        _mint(challenger, 1);

        // Make it look like a close election...
        votes[incumbent] = 5;
        votes[challenger] = 3;
    }
}
