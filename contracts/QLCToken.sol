// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


/**
 * @notice QLCToken contract realizes cross-chain with Nep5 QLC
 */
contract QLCToken is ERC20, Ownable {
    using SafeMath for uint256;

    struct HashTimer {
        bytes32 origin;
        uint256 amount;
        address user;
        uint256 lockHeight;
        uint256 unlockHeight;
        bool isIssue;
    }

    mapping(bytes32 => HashTimer) private _hashTimers;
    uint256 private _issueInterval = 6;
    uint256 private _destoryInterval = 10;
    uint256 private _minAmount = 1;

    /**
     * @dev Emitted locker state changed
     *
     * Parameters:
     * - `rHash`: index, the hash of locker
     * - `state`: locker state, 0:issueLock, 1:issueUnlock, 2:issueFetch, 3:destoryLock, 4:destoryUnlock, 5:destoryFetch
     * - `rOrigin`: the origin text of locker
     */
    event LockedState(bytes32 indexed rHash, uint256 state, bytes32 rOrigin);

    constructor() public ERC20("QToken", "qlc") {
        _setupDecimals(8);
        _mint(msg.sender, 0);
    }

    /**
     * @dev Issue `amount` token and locked by `rHash`
     * Only callable by the Owner.
     * Emits a {LockedState} event.
     *
     * Parameters:
     * - `rHash` is the hash of locker, cannot be zero and duplicated
     * - `amount` should not less than `_minAmount`
     */
    function issueLock(bytes32 rHash, uint256 amount) public onlyOwner {
        require(rHash != 0x0, "zero rHash");
        require(amount >= _minAmount, "too little amount");

        HashTimer memory t = _hashTimers[rHash];
        require(t.lockHeight == 0, "duplicated hash"); 

        t.amount = amount;
        t.lockHeight = block.number;
        t.isIssue = true;
        _hashTimers[rHash] = t;
        emit LockedState(rHash, 0, 0x0);
    }

    /**
     * @dev caller provide locker origin text `rOrigin` to unlock token and release to his account
     * `issueUnlock` must be executed after `issueLock` and the interval must less then `_issueInterval`
     *
     * Emits a {LockedState} event.
     *
     * Parameters:
     * - `rHash` is the hash of locker
     * - `rOrigin` is the origin text of locker
     */
    function issueUnlock(bytes32 rHash, bytes32 rOrigin) public {
        HashTimer memory t = _hashTimers[rHash];
        require( t.lockHeight > 0 && t.unlockHeight ==0, "invaild hash");
        require(block.number.sub(t.lockHeight) < _issueInterval, "already timeout");
        require(_isHashValid(rHash, rOrigin), "hash mismatch");

        _mint(msg.sender, t.amount);
        
        t.origin = rOrigin;
        t.user = msg.sender;
        t.unlockHeight = block.number;
        _hashTimers[rHash] = t;
        emit LockedState(rHash, 1, rOrigin);
    }

    /**
     * @dev `issueFetch` must be executed after `issueLock` and the interval must more then `_issueInterval`
     * destory the token locked by `rHash`
     * Only callable by the Owner.
     *
     * Emits a {LockedState} event.
     *
     * Parameters:
     * - `rHash` is the hash of locker
     */
    function issueFetch(bytes32 rHash) public onlyOwner {
        HashTimer memory t = _hashTimers[rHash];
        require( t.lockHeight > 0 && t.unlockHeight ==0, "invaild hash");
        require(block.number.sub(t.lockHeight) > _issueInterval, "not timeout");

        t.amount = 0;
        t.unlockHeight = block.number;
        _hashTimers[rHash] = t;
        emit LockedState(rHash, 2, 0x0);
    }

    /**
     * @dev lock caller's `amount` token by `rHash`
     *
     * Emits a {LockedState} event.
     *
     * Parameters:
     * - `rHash` is the hash of locker, cannot be zero and duplicated
     * - `amount` should more than zero.
     * - `executor` should be owner's address
     */
    function destoryLock(
        bytes32 rHash,
        uint256 amount,
        address executor
    ) public {
        HashTimer memory t = _hashTimers[rHash];
        require(t.lockHeight == 0, "duplicated hash"); 
        require(rHash != 0x0, "zero rHash");
        require(executor == owner(), "wrong executor");

        transfer(address(this), amount);
        
        t.amount = amount;
        t.user = msg.sender;
        t.lockHeight = block.number;
        t.isIssue = false;

        _hashTimers[rHash] = t;
        emit LockedState(rHash, 3, 0x0);
    }

    /**
     * @dev Destory `rHash` locked token by origin text `rOrigin`
     * `destoryUnlock` must be executed after `destoryLock` and the interval must less then `_destoryInterval`
     * Only callable by the Owner.
     *
     * Emits a {LockedState} event.
     *
     * Parameters:
     * - `rHash` is the hash of locker
     * - `rOrigin` is the origin text of locker
     */
    function destoryUnlock(bytes32 rHash, bytes32 rOrigin) public onlyOwner {
        HashTimer memory t = _hashTimers[rHash];
        require( t.lockHeight > 0 && t.unlockHeight ==0, "invaild hash");
        require(block.number.sub(t.lockHeight) < _issueInterval, "already timeout");   
        require(_isHashValid(rHash, rOrigin), "hash mismatch");

        // destroy lock token
        uint256 amount = t.amount;
        _burn(address(this), amount);
        
        t.origin = rOrigin;
        t.unlockHeight = block.number;
        _hashTimers[rHash] = t;
        emit LockedState(rHash, 4, rOrigin);
    }

    /**
     * @dev `destoryFetch` must be executed after `destoryLock` and the interval must more then `_destoryInterval`
     * unlock token and return back to caller
     *
     * Emits a {LockedState} event.
     *
     * Parameters:
     * - `rHash` is the hash of locker
     */
    function destoryFetch(bytes32 rHash) public {
        // basic check
        HashTimer memory t = _hashTimers[rHash];
        require( t.lockHeight > 0 && t.unlockHeight ==0, "invaild hash");
        require(msg.sender == t.user, "wrong caller");
        require(block.number.sub(t.lockHeight) > _destoryInterval, "not timeout");

        uint256 amount = t.amount;
        this.transfer(msg.sender, amount);

        t.unlockHeight = block.number;
        _hashTimers[rHash] = t;
        emit LockedState(rHash, 5,  0x0);
    }

    function _isHashValid(bytes32 rHash, bytes32 rOrigin) private pure returns (bool) {
        bytes memory rBytes = abi.encodePacked(rOrigin);
        bytes32 h = sha256(rBytes);
        return (h == rHash ? true : false);
    }

    /**
     * @dev Return detail info of hash-timer locker
     *
     * Parameters:
     * - `rHash` is the hash of locker
     *
     * Returns:
     * - the origin text of locker
     * - locked amount
     * - account with locked token
     * - locked block height
     * - unlocked block height
     * - `true` is issue phase, `false` is destory phase
     */
    function hashTimer(bytes32 rHash)
        public
        view
        returns (
            bytes32,
            uint256,
            address,
            uint256,
            uint256,
            bool
        )
    {
        HashTimer memory t = _hashTimers[rHash];
        return (t.origin,t.amount,t.user,t.lockHeight,t.unlockHeight,t.isIssue);
    }
}