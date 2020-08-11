// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract QLCToken is ERC20, Ownable {
    using SafeMath for uint256;
    
    struct HashTimer {
        string  origin;        // hash original
        uint256 height;        // lock height
        uint256 amount;        // lock amount
        address user;          // lock address
        bool    isLocked;
        bool    isUnlocked;
    }
    
    mapping (bytes32 => HashTimer) public hashTimers; 
    mapping (address => uint256)  public lockedBalanceOf; 

    event LockedState(bytes32 r_hash, string state, uint256 amount, address user, string r_origin);
    
    uint256  interval = 10 ;  

    constructor() public ERC20("QToken", "qlc") {
        _setupDecimals(8);
        _mint(msg.sender,0);
    }

    function IssueLock(uint256 amount, bytes32 r_hash) public onlyOwner {
        // basic check 
        require(!_isRLocked(r_hash), "hash value is duplicated");

        // add hash-time locker 
        hashTimers[r_hash].height = block.number;
        hashTimers[r_hash].amount = amount;
        
        emit LockedState(r_hash, "IssueLock", amount, address(0), "");
        _setRLocked(r_hash);
    }

    function IssueUnlock(bytes32 r_hash, string memory r_origin) public {
        // basic check 
        require(_isRLocked(r_hash), "can not find locker");
        require(!_isRUnlocked(r_hash), "locker has been unlocked");
        require(!_isTimeOut(r_hash), "locker has been timeout");
        require(_isHashValid(r_hash, r_origin), "hash value is mismatch");
        
        // save r
        hashTimers[r_hash].origin = r_origin;

        // unlock token to user
        uint256 amount = hashTimers[r_hash].amount;
        _mint(msg.sender,amount);   

        emit LockedState(r_hash, "IssueUnlock", amount, msg.sender, r_origin);
        _setRUnlocked(r_hash);
    }
    
    function IssueFetch(bytes32 r_hash) public onlyOwner {
        // basic check
        require(_isRLocked(r_hash) , "can not find locker");
        require(!_isRUnlocked(r_hash), "locker has been unlocked");
        require(_isTimeOut(r_hash), "locker hasn't been timeout yet");
        
        uint256 amount = hashTimers[r_hash].amount;
        emit LockedState(r_hash, "IssueFetch", amount, address(0), "");
        
        hashTimers[r_hash].amount = 0;
        _setRUnlocked(r_hash);
    }


    function DestoryLock(uint256 amount, bytes32 r_hash, address executor) public {
        // basic check     
        require(!_isRLocked(r_hash), "hash value is duplicated");
        require(executor == owner(), "executor must be contract owner");
        require(_isBalanceEnough(msg.sender,amount), "locked amount is more than account balance");
        
        // add time locker
        hashTimers[r_hash].height = block.number;
        hashTimers[r_hash].amount = amount;
        hashTimers[r_hash].user   = msg.sender;
        
        // add user's locked balance
        lockedBalanceOf[msg.sender] = lockedBalanceOf[msg.sender].add(amount);
        
        emit LockedState(r_hash, "DestoryLock", amount, msg.sender, "");
        _setRLocked(r_hash);
    }

    function DestoryUnlock(bytes32 r_hash, string memory r_origin) public onlyOwner {
        // basic check 
        require(_isRLocked(r_hash), "can not find locker");
        require(!_isRUnlocked(r_hash), "locker has been unlocked");
        require(!_isTimeOut(r_hash),  "locker has been timeout");
        require(_isHashValid(r_hash, r_origin), "hash value is mismatch");
        
        // save r
        hashTimers[r_hash].origin = r_origin;

        // destroy lock token
        address user = hashTimers[r_hash].user;
        uint256 amount = hashTimers[r_hash].amount;
        _burn(user, amount);
        
        // sub user's locked balance
        lockedBalanceOf[user] = lockedBalanceOf[user].sub(amount);

        emit LockedState(r_hash, "DestoryUnlock", amount, user, r_origin );
        _setRUnlocked(r_hash);
    }
    
    function DestoryFetch(bytes32 r_hash) public {
        // basic check 
        require(_isRLocked(r_hash), "can not find locker");
        require(!_isRUnlocked(r_hash), "locker has been unlocked");
        require(_isTimeOut(r_hash), "locker hasn't been timeout yet");
        require(msg.sender == hashTimers[r_hash].user, "sender should be the lock account");

        // sub user's locked balance
        uint256 amount = hashTimers[r_hash].amount;
        lockedBalanceOf[msg.sender] = lockedBalanceOf[msg.sender].sub(amount);
        
        emit  LockedState(r_hash, "DestoryFetch", amount, msg.sender, "" );        
        _setRUnlocked(r_hash);
    }
    
    function _isTimeOut(bytes32 r_hash) private view returns (bool) {
        uint256 currentHeight = block.number ;
        uint256 originHeight =  hashTimers[r_hash].height;
        return (currentHeight.sub(originHeight) > interval ? true: false);
    }
    
    function _isBalanceEnough(address addr, uint256 amount) private view returns (bool){
        uint256 lockedBalance = lockedBalanceOf[addr];
        uint256 totalBalance = balanceOf(addr);
        return (totalBalance.sub(lockedBalance) > amount ? true: false); 
    }
    
    function _isRLocked(bytes32 r_hash) private view returns (bool){
        return hashTimers[r_hash].isLocked;
    }
    
    function _isRUnlocked(bytes32 r_hash) private view returns (bool){
        return hashTimers[r_hash].isUnlocked;
    }
    
    function _setRLocked(bytes32 r_hash) private {
        hashTimers[r_hash].isLocked = true;
    } 
    
    function _setRUnlocked(bytes32 r_hash) private {
        hashTimers[r_hash].isUnlocked = true;
    } 
    
    function _isHashValid(bytes32 r_hash, string memory r_origin) private pure returns (bool){
        bytes memory r_bytes = bytes(r_origin);
        bytes32 h = sha256(r_bytes);
        return (h == r_hash ? true: false);
    } 
    
    // Hook that is called before any transfer of tokens. This includes minting and burning.
    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal override { 
    //     require(to != address(0), "ERC20: transfer to the zero address");
    //     require(_isBalanceEnough(from, amount));
    // }
    
    function transfer(address recipient, uint256 amount) public  override returns (bool) {
        require(_isBalanceEnough(msg.sender, amount), "transfer amount exceeds available balance");
        super.transfer(recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount)  public  override returns (bool) {
        require(_isBalanceEnough(sender, amount), "transfer amount exceeds available balance");
        super.transferFrom(sender, recipient, amount);
    }
    
    function isHashValid(bytes32 r_hash, string memory r_origin) public pure returns (bool){
        return _isHashValid(r_hash, r_origin);
    } 

}