pragma solidity 0.7.0;

// This contract has a vulnerability where user funds can be stolen, exploit it.
// Author: Michael Amadi. twitter.com/AmadiMichaels, github.com/AmadiMichael
contract NAME_SERVICE_BANK {
    bytes32 private constant KECCAK_0X = keccak256(abi.encode(new bytes(0)));

    struct SubscriptionDuration {
        uint256 start;
        uint256 end;
    }

    mapping(address => string) public usernameOf; // maps an address to a username string
    mapping(string => address) public addressOf; // maps a string to an address
    mapping(string => SubscriptionDuration) internal usernameSubscriptionDuration; // future feature: maps a string to its current subscription start and end in a fixed array of length = 2
    mapping(string => bool) public isUsedUsername; // tracks if a string username is currently mapped
    mapping(string => uint256) internal _balanceOf; // tracks the balanceOf a string username

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    /// @notice lets anyone pay 1 ether for a username to use in tracking their balance
    /// @param newUsername new username
    /// @param obfuscationDegree (if username is < 31 bytes) how long extra the length should be
    /// @param _usernameSubscriptionDuration duration of subscription
    ///        index 0: Duration End
    ///        index 1: Duration Start
    /// @dev reverts if username is currently taken
    ///      if msg.value != 1 ether
    ///      if total length of username is greater than 31 bytes, this is done to enable all names to be stored in one slot
    ///      if subscriptionStart is > block.timestamp
    ///      if subscriptionEnd <= subscriptionStart or if subscriptionEnd < block.timestamp
    ///      if newUsername is == "" (empty string)
    ///      if this is not user's first username(ie if oldusername != ""), if newUsername == oldUsername
    function setUsername(
        string memory newUsername,
        uint256 obfuscationDegree,
        uint256[2] memory _usernameSubscriptionDuration
    ) public payable {
        require(msg.value == 1 ether, "Flat fee for subcription of username is 1 ether");
        require(bytes(newUsername).length + obfuscationDegree <= 31, "Max name size is 31 bytes");
        require(_usernameSubscriptionDuration[1] <= block.timestamp, "Start time must be now or earlier");
        require(
            _usernameSubscriptionDuration[0] > _usernameSubscriptionDuration[1] &&
                _usernameSubscriptionDuration[0] > block.timestamp,
            "Invalid subscription end"
        );

        // cache last username and its hash
        string memory lastUsername = usernameOf[msg.sender];
        bytes32 lastUsernameHash = keccak256(abi.encode(lastUsername));

        // make last username available if its not empty username
        if (lastUsernameHash != KECCAK_0X) isUsedUsername[lastUsername] = false;

        // revert if old username is already being used
        require(!isUsedUsername[newUsername], "User name is used");
        usernameOf[msg.sender] = newUsername;

        // obfuscate the name
        for (uint256 i; i < obfuscationDegree; ++i) {
            bytes(usernameOf[msg.sender]).push();
        }

        // cache new username and its hash
        string memory _newUsername = usernameOf[msg.sender];
        bytes32 newUsernameHash = keccak256(abi.encode(_newUsername));

        // cannot set `""` (empty bytes/string) as username
        require(newUsernameHash != KECCAK_0X, "Cannot have empty username");
        // cannot set new username to be old username, no waste of gas here anon
        require(lastUsernameHash != newUsernameHash, "New username == old username");

        // reverse map the string name to msg.sender
        addressOf[_newUsername] = msg.sender;
        // set new username as used name
        isUsedUsername[usernameOf[msg.sender]] = true;
        // set subscription duration of new name
        usernameSubscriptionDuration[_newUsername] = SubscriptionDuration({
            end: _usernameSubscriptionDuration[0],
            start: _usernameSubscriptionDuration[1]
        });

        // Migrate balance from old username to new username
        _balanceOf[_newUsername] += _balanceOf[lastUsername];
        delete _balanceOf[lastUsername];

        // send payment to owner
        (bool success, ) = payable(owner).call{value: 1 ether}("");
        require(success, "payment failed");
    }

    function withdraw(uint256 amount) external {
        string memory cacheUsername = usernameOf[msg.sender];
        require(amount <= _balanceOf[cacheUsername], "insufficient balance");
        _balanceOf[cacheUsername] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "withdraw failed");
    }

    function deposit() external payable {
        string memory cacheUsername = usernameOf[msg.sender];
        require(keccak256(abi.encode(cacheUsername)) != KECCAK_0X, "No username for user");
        _balanceOf[cacheUsername] += msg.value;
    }

    function balanceOf(address user) external view returns (uint256) {
        string memory cacheUsername = usernameOf[user];
        return _balanceOf[cacheUsername];
    }

    receive() external payable {
        string memory cacheUsername = usernameOf[msg.sender];
        require(keccak256(abi.encode(cacheUsername)) != keccak256(abi.encode(new bytes(0))), "No username for user");
        _balanceOf[cacheUsername] += msg.value;
    }
}
