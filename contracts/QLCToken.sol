// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


/**
 * @dev QLCToken contract realizes cross-chain with Nep5 QLC
 */
contract QLCToken is ERC20, Ownable {
    using SafeMath for uint256;

    struct HashTimer {
        bytes32 origin; 
        uint256 amount;
        address user;  
        uint256 lockHeight; 
        uint256 unlockHeight;
        bool isLocked;
        bool isUnlocked;
        bool isIssue;
    }

    mapping(bytes32 => HashTimer) private _hashTimers;
    mapping(address => uint256)   private _lockedBalanceOf;
    uint256 private _issueInterval   = 5;
    uint256 private _destoryInterval = 10;
    uint256 private _minAmount = 1;


    /**
     * @dev Emitted locker state changed
     *
     * Parameters:
     * - `rHash`: index, the hash of locker
     * - `state`: locker state
     * - `amount`: locked amount
     * - `user`: account with locked token 
     * - `rOrigin`: the origin text of locker
     */
    event LockedState(bytes32 indexed rHash, string state, uint256 amount, address user, bytes32 rOrigin);

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
        // basic check
        require(rHash != 0x0, "rHash can not be zero");
        require(amount >= _minAmount, "amount should not less than min amount");
        require(!_isRLocked(rHash), "hash value is duplicated");

        // add hash-time locker
        _hashTimers[rHash].amount = amount;
        _hashTimers[rHash].isIssue = true;

        emit LockedState(rHash, "issueLock", amount, address(0), "");
        _setRLocked(rHash);
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
        // basic check
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(!_isTimeOut(rHash, _issueInterval ), "locker has been timeout");
        require(_isHashValid(rHash, rOrigin), "hash value is mismatch");

        // save r
        _hashTimers[rHash].origin = rOrigin;
        _hashTimers[rHash].user = msg.sender;

        // unlock token to user
        uint256 amount = _hashTimers[rHash].amount;
        _mint(msg.sender, amount);

        emit LockedState(rHash, "issueUnlock", amount, msg.sender, rOrigin);
        _setRUnlocked(rHash);
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
        // basic check
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(_isTimeOut(rHash, _issueInterval), "locker hasn't been timeout yet");

        uint256 amount = _hashTimers[rHash].amount;
        emit LockedState(rHash, "issueFetch", amount, address(0), "");

        _hashTimers[rHash].amount = 0;
        _setRUnlocked(rHash);
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
        // basic check
        require(rHash != 0x0, "rHash can not be zero");
        require(amount > 0, "amount should more than zero");
        require(!_isRLocked(rHash), "hash value is duplicated");
        require(executor == owner(), "executor must be contract owner");
        require(_isBalanceEnough(msg.sender, amount), "available balance is not enough");

        // add time locker
        _hashTimers[rHash].amount = amount;
        _hashTimers[rHash].user = msg.sender;
        _hashTimers[rHash].isIssue = false;

        // add user's locked balance
        _lockedBalanceOf[msg.sender] = _lockedBalanceOf[msg.sender].add(amount);

        emit LockedState(rHash, "destoryLock", amount, msg.sender, "");
        _setRLocked(rHash);
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
        // basic check
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(!_isTimeOut(rHash, _destoryInterval), "locker has been timeout");
        require(_isHashValid(rHash, rOrigin), "hash value is mismatch");

        // save r
        _hashTimers[rHash].origin = rOrigin;

        // destroy lock token
        address user = _hashTimers[rHash].user;
        uint256 amount = _hashTimers[rHash].amount;
        _burn(user, amount);

        // sub user's locked balance
        _lockedBalanceOf[user] = _lockedBalanceOf[user].sub(amount);

        emit LockedState(rHash, "destoryUnlock", amount, user, rOrigin);
        _setRUnlocked(rHash);
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
        require(_isRLocked(rHash), "can not find locker");
        require(!_isRUnlocked(rHash), "locker has been unlocked");
        require(_isTimeOut(rHash, _destoryInterval), "locker hasn't been timeout yet");
        require(msg.sender == _hashTimers[rHash].user, "caller must be the lock account");

        // sub user's locked balance
        uint256 amount = _hashTimers[rHash].amount;
        _lockedBalanceOf[msg.sender] = _lockedBalanceOf[msg.sender].sub(amount);

        emit LockedState(rHash, "destoryFetch", amount, msg.sender, "");
        _setRUnlocked(rHash);
    }

    function _isTimeOut(bytes32 rHash, uint256 interval) private view returns (bool) {
        uint256 currentHeight = block.number;
        uint256 originHeight = _hashTimers[rHash].lockHeight;
        return (currentHeight.sub(originHeight) > interval ? true : false);
    }

    function _isBalanceEnough(address addr, uint256 amount) private view returns (bool) {
        uint256 lockedBalance = _lockedBalanceOf[addr];
        uint256 totalBalance = balanceOf(addr);
        return (totalBalance.sub(lockedBalance) > amount ? true : false);
    }

    function _isRLocked(bytes32 rHash) private view returns (bool) {
        return _hashTimers[rHash].isLocked;
    }

    function _isRUnlocked(bytes32 rHash) private view returns (bool) {
        return _hashTimers[rHash].isUnlocked;
    }

    function _setRLocked(bytes32 rHash) private {
        _hashTimers[rHash].isLocked = true;
        _hashTimers[rHash].lockHeight = block.number;
    }

    function _setRUnlocked(bytes32 rHash) private {
        _hashTimers[rHash].isUnlocked = true;
        _hashTimers[rHash].unlockHeight = block.number;
    }

    function _isHashValid(bytes32 rHash, bytes32 rOrigin) private pure returns (bool) {
        // bytes memory rBytes = bytes(rOrigin);
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
        return (
            _hashTimers[rHash].origin,
            _hashTimers[rHash].amount,
            _hashTimers[rHash].user,
            _hashTimers[rHash].lockHeight,
            _hashTimers[rHash].unlockHeight,
            _hashTimers[rHash].isIssue
        );
    }

    /**
     * @dev Return `addr`'s locked balance in destory phase
     *
     * Parameters:
     * - `addr`: erc20 address
     * 
     * Returns:
     * - locked amount
     */
    function lockedBalanceOf(address addr) public view returns (uint256) {
        return _lockedBalanceOf[addr];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Parameters:
     * - `recipient` cannot be the zero address.
     * -  the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_isBalanceEnough(msg.sender, amount), "available balance is not enough");
        super.transfer(recipient, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * Parameters:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * -  the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_isBalanceEnough(sender, amount), "available balance is not enough");
        super.transferFrom(sender, recipient, amount);
    }
}
