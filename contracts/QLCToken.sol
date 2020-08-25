// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @notice QLCToken contract realizes cross-chain with Nep5 QLC
 */
contract QLCToken  is Initializable, ERC20UpgradeSafe, OwnableUpgradeSafe {
    using SafeMath for uint256;
    
    mapping(bytes32 => bytes32) private _lockedOrigin;
    mapping(bytes32 => uint256) private _lockedAmount;
    mapping(bytes32 => address) private _lockedUser;
    mapping(bytes32 => uint256) private _lockedHeight;
    mapping(bytes32 => uint256) private _unlockedHeight;
    
    uint256 private _issueInterval;
    uint256 private _destoryInterval;
    uint256 private _minAmount;

    /**
     * @dev Emitted locker state changed
     *
     * Parameters:
     * - `rHash`: index, the hash of locker
     * - `state`: locker state, 0:issueLock, 1:issueUnlock, 2:issueFetch, 3:destoryLock, 4:destoryUnlock, 5:destoryFetch
     * - `rOrigin`: the origin text of locker
     */
    event LockedState(bytes32 indexed rHash, uint256 state);

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        _setupDecimals(8);
        _mint(msg.sender, 0);

        _issueInterval = 6;
        _destoryInterval = 10;
        _minAmount = 1;
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
        require(_lockedHeight[rHash] == 0, "duplicated hash"); 

        _mint(address(this), amount);
        
        _lockedAmount[rHash] = amount;
        _lockedHeight[rHash] = block.number;

        emit LockedState(rHash, 0);
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
        uint256 lockedHeight = _lockedHeight[rHash] ;
        require( lockedHeight > 0 && _unlockedHeight[rHash] ==0, "invaild hash");
        require(block.number.sub(lockedHeight) < _issueInterval, "already timeout");
        require(_isHashValid(rHash, rOrigin), "hash mismatch");


        _lockedOrigin[rHash] = rOrigin;
        _lockedUser[rHash] = msg.sender;
        _unlockedHeight[rHash] = block.number;
        
        require(this.transfer(msg.sender, _lockedAmount[rHash]), "transfer fail");        
        emit LockedState(rHash, 1);
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
        uint256 lockedHeight = _lockedHeight[rHash] ;
        require( lockedHeight > 0 && _unlockedHeight[rHash]  ==0, "invaild hash");
        require(block.number.sub(lockedHeight) > _issueInterval, "not timeout");
        
        _burn(address(this), _lockedAmount[rHash]);

        _unlockedHeight[rHash] = block.number;

        emit LockedState(rHash, 2);
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
        require(rHash != 0x0, "zero rHash");
        require( _lockedHeight[rHash]  == 0, "duplicated hash"); 
        require(executor == owner(), "wrong executor");

        require(transfer(address(this), amount), "transfer fail");

        _lockedAmount[rHash] = amount;
        _lockedUser[rHash] = msg.sender;
        _lockedHeight[rHash] = block.number;

        emit LockedState(rHash, 3);
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
        uint256 lockedHeight = _lockedHeight[rHash] ;
        require( lockedHeight > 0 && _unlockedHeight[rHash]  ==0, "invaild hash");
        require(block.number.sub(lockedHeight) < _issueInterval, "already timeout");   
        require(_isHashValid(rHash, rOrigin), "hash mismatch");

        _burn(address(this), _lockedAmount[rHash]);
        
        _lockedOrigin[rHash] = rOrigin;
        _unlockedHeight[rHash] = block.number;

        emit LockedState(rHash, 4);
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
        uint256 lockedHeight = _lockedHeight[rHash] ;
        require( lockedHeight > 0 && _unlockedHeight[rHash]  ==0, "invaild hash");
        require(msg.sender == _lockedUser[rHash], "wrong caller");
        require(block.number.sub(lockedHeight) > _destoryInterval, "not timeout");

        _unlockedHeight[rHash] = block.number;

        require(this.transfer(msg.sender, _lockedAmount[rHash]), "transfer fail");
        emit LockedState(rHash, 5);
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
     */
    function hashTimer(bytes32 rHash)
        public
        view
        returns (
            bytes32,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        return (_lockedOrigin[rHash], _lockedAmount[rHash], _lockedUser[rHash], _lockedHeight[rHash], _unlockedHeight[rHash]);
    }

}