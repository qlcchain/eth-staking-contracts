// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract QLCToken is ERC20, Ownable {
    using SafeMath for uint256;

    struct HashTimer {
        bytes32 origin; // hash original
        uint256 height; // lock height
        uint256 amount; // lock amount
        address user; // lock address
        bool isLocked;
        bool isUnlocked;
    }

    mapping(bytes32 => HashTimer) public hashTimers;
    mapping(address => uint256) public lockedBalanceOf;

    event LockedState(bytes32 rHash, string state, uint256 amount, address user, bytes32 rOrigin);

    uint256 private _interval = 10;

    constructor() public ERC20("QToken", "qlc") {
        _setupDecimals(8);
        _mint(msg.sender, 0);
    }

    function issueLock(uint256 amount, bytes32 rHash) public onlyOwner {
        // basic check
        require(!_isRLocked(rHash), "hash value is duplicated");

        // add hash-time locker
        hashTimers[rHash].height = block.number;
        hashTimers[rHash].amount = amount;

        emit LockedState(rHash, "issueLock", amount, address(0), "");
        _setRLocked(rHash);
    }

    function issueUnlock(bytes32 rHash, bytes32 rOrigin) public {
        // basic check
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(!_isTimeOut(rHash), "locker has been timeout");
        require(_isHashValid(rHash, rOrigin), "hash value is mismatch");

        // save r
        hashTimers[rHash].origin = rOrigin;

        // unlock token to user
        uint256 amount = hashTimers[rHash].amount;
        _mint(msg.sender, amount);

        emit LockedState(rHash, "issueUnlock", amount, msg.sender, rOrigin);
        _setRUnlocked(rHash);
    }

    function issueFetch(bytes32 rHash) public onlyOwner {
        // basic check
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(_isTimeOut(rHash), "locker hasn't been timeout yet");

        uint256 amount = hashTimers[rHash].amount;
        emit LockedState(rHash, "issueFetch", amount, address(0), "");

        hashTimers[rHash].amount = 0;
        _setRUnlocked(rHash);
    }

    function destoryLock(
        uint256 amount,
        bytes32 rHash,
        address executor
    ) public {
        // basic check
        require(!_isRLocked(rHash), "hash value is duplicated");
        require(executor == owner(), "executor must be contract owner");
        require(_isBalanceEnough(msg.sender, amount), "available balance is not enough");

        // add time locker
        hashTimers[rHash].height = block.number;
        hashTimers[rHash].amount = amount;
        hashTimers[rHash].user = msg.sender;

        // add user's locked balance
        lockedBalanceOf[msg.sender] = lockedBalanceOf[msg.sender].add(amount);

        emit LockedState(rHash, "destoryLock", amount, msg.sender, "");
        _setRLocked(rHash);
    }

    function destoryUnlock(bytes32 rHash, bytes32 rOrigin) public onlyOwner {
        // basic check
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(!_isTimeOut(rHash), "locker has been timeout");
        require(_isHashValid(rHash, rOrigin), "hash value is mismatch");

        // save r
        hashTimers[rHash].origin = rOrigin;

        // destroy lock token
        address user = hashTimers[rHash].user;
        uint256 amount = hashTimers[rHash].amount;
        _burn(user, amount);

        // sub user's locked balance
        lockedBalanceOf[user] = lockedBalanceOf[user].sub(amount);

        emit LockedState(rHash, "destoryUnlock", amount, user, rOrigin);
        _setRUnlocked(rHash);
    }

    function destoryFetch(bytes32 rHash) public {
        // basic check
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(_isTimeOut(rHash), "locker hasn't been timeout yet");
        require(msg.sender == hashTimers[rHash].user, "sender must be the lock account");

        // sub user's locked balance
        uint256 amount = hashTimers[rHash].amount;
        lockedBalanceOf[msg.sender] = lockedBalanceOf[msg.sender].sub(amount);

        emit LockedState(rHash, "destoryFetch", amount, msg.sender, "");
        _setRUnlocked(rHash);
    }

    function _isTimeOut(bytes32 rHash) private view returns (bool) {
        uint256 currentHeight = block.number;
        uint256 originHeight = hashTimers[rHash].height;
        return (currentHeight.sub(originHeight) > _interval ? true : false);
    }

    function _isBalanceEnough(address addr, uint256 amount) private view returns (bool) {
        uint256 lockedBalance = lockedBalanceOf[addr];
        uint256 totalBalance = balanceOf(addr);
        return (totalBalance.sub(lockedBalance) > amount ? true : false);
    }

    function _isRLocked(bytes32 rHash) private view returns (bool) {
        return hashTimers[rHash].isLocked;
    }

    function _isRUnlocked(bytes32 rHash) private view returns (bool) {
        return hashTimers[rHash].isUnlocked;
    }

    function _setRLocked(bytes32 rHash) private {
        hashTimers[rHash].isLocked = true;
    }

    function _setRUnlocked(bytes32 rHash) private {
        hashTimers[rHash].isUnlocked = true;
    }

    function _isHashValid(bytes32 rHash, bytes32 rOrigin) private pure returns (bool) {
        // bytes memory rBytes = bytes(rOrigin);
        bytes memory rBytes = abi.encodePacked(rOrigin);
        bytes32 h = sha256(rBytes);
        return (h == rHash ? true : false);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_isBalanceEnough(msg.sender, amount), "available balance is not enough");
        super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_isBalanceEnough(sender, amount), "available balance is not enough");
        super.transferFrom(sender, recipient, amount);
    }

    function isHashValid(bytes32 rHash, bytes32 rOrigin) public pure returns (bool) {
        return _isHashValid(rHash, rOrigin);
    }
}
