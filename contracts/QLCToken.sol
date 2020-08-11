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
    
    mapping (string => HashTimer) public hashTimers; 
    
    mapping (address => uint256)  public lockBalanceOf; 

    event IssueTokenLock(string r_hash, uint256 amount);
    event IssueTokenUnlock(string r_hash, string r_origin);
    event IssueTokenFetch(string r_hash,  uint256 amount);
    
    event DestoryTokenLock(string r_hash, address addr,  uint256 amount);
    event DestoryTokenUnlock(string r_hash, string r_origin, address addr, uint256 amount);
    event DestoryTokenFetch(string r_hash, address addr, uint256 amount);
    
    uint256  interval = 10 ;  

    constructor() public ERC20("QToken", "qlc") {
        _setupDecimals(4);
        _mint(msg.sender,0);
    }

    function IssueLock(uint256 amount, string memory r_hash) public onlyOwner {
        // basic check 
        require(!_isRLocked(r_hash));

        // add time locker 
        hashTimers[r_hash].height = block.number;
        hashTimers[r_hash].amount = amount;
        
        emit IssueTokenLock(r_hash, amount);
        _setRLocked(r_hash);
    }

    function IssueUnlock(string memory r_hash, string memory r_origin) public {
        // basic check 
        require(_isRLocked(r_hash));
        require(!_isRUnlocked(r_hash));
        
        require(!_isTimeOut(r_hash));
        
        // check hash
        
        
        // save r
        hashTimers[r_hash].origin = r_origin;

        // unlock token to user
        uint256 amount = hashTimers[r_hash].amount;
        _mint(msg.sender,amount);   

        emit IssueTokenUnlock(r_hash, r_origin);
        _setRUnlocked(r_hash);
    }
    
    function IssueFetch(string memory r_hash) public onlyOwner {
        // basic check
        require(_isRLocked(r_hash));
        require(!_isRUnlocked(r_hash));

        require(_isTimeOut(r_hash));
        
        uint256 amount = hashTimers[r_hash].amount;

        emit IssueTokenFetch(r_hash, amount);
        _setRUnlocked(r_hash);
    }


    function DestoryLock(uint256 amount, string memory r_hash, address addr) public {
        // basic check     
        require(!_isRLocked(r_hash));
        require(addr == owner());
        require(_isBalanceEnough(msg.sender,amount));
        
        // add time locker
        hashTimers[r_hash].height = block.number;
        hashTimers[r_hash].amount = amount;
        hashTimers[r_hash].user   = msg.sender;
        
        // add user's locked balance
        lockBalanceOf[msg.sender] = lockBalanceOf[msg.sender].add(amount);
        
        emit DestoryTokenLock(r_hash, msg.sender, amount);
        _setRLocked(r_hash);
    }

    function DestoryUnlock(string memory r_hash, string memory r_origin) public onlyOwner {
        // check timer
        require(_isRLocked(r_hash));
        require(!_isRUnlocked(r_hash));
        
        require(!_isTimeOut(r_hash));

        // check hash 
        
        
        // save r
        hashTimers[r_hash].origin = r_origin;

        // destroy lock token
        address user = hashTimers[r_hash].user;
        uint256 amount = hashTimers[r_hash].amount;
        _burn(user, amount);
        
        // sub user's locked balance
        lockBalanceOf[user] = lockBalanceOf[user].sub(amount);

        emit DestoryTokenUnlock(r_hash,r_origin, user, amount);
        _setRUnlocked(r_hash);
    }
    
    function DestoryFetch(string memory r_hash) public {
        // basic check 
        require(_isRLocked(r_hash));
        require(!_isRUnlocked(r_hash));
        
        require(_isTimeOut(r_hash));
        
        // check user
        require(msg.sender == hashTimers[r_hash].user);

        // sub user's locked balance
        uint256 amount = hashTimers[r_hash].amount;
        lockBalanceOf[msg.sender] = lockBalanceOf[msg.sender].sub(amount);
        
        emit  DestoryTokenFetch(r_hash, msg.sender, amount);        
        _setRUnlocked(r_hash);
    }
    
    function _isTimeOut(string memory r_hash) private view returns (bool) {
        uint256 currentHeight = block.number ;
        uint256 originHeight =  hashTimers[r_hash].height;
        return (currentHeight.sub(originHeight) > interval ? true: false);
    }
    
    function _isBalanceEnough(address addr, uint256 amount) private view returns (bool){
        uint256 lockBalance = lockBalanceOf[addr];
        uint256 totalBalance = balanceOf(addr);
        return (totalBalance.sub(lockBalance) > amount ? true: false); 
    }
    
    function _isRLocked(string memory r_hash) private view returns (bool){
        return hashTimers[r_hash].isLocked;
    }
    
    function _isRUnlocked(string memory r_hash) private view returns (bool){
        return hashTimers[r_hash].isUnlocked;
    }
    
    function _setRLocked(string memory r_hash) private {
        hashTimers[r_hash].isLocked = true;
    } 
    
    function _setRUnlocked(string memory r_hash) private {
        hashTimers[r_hash].isUnlocked = true;
    } 
   
    function transfer(address recipient, uint256 amount) public  override returns (bool) {
        require(_isBalanceEnough(msg.sender, amount));
        super.transfer(recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public  override returns (bool) {
        require(_isBalanceEnough(sender, amount));
        super.transferFrom(sender, recipient, amount);
    }
}