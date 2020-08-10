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
    }
    
    mapping (string => HashTimer) public hashTimers; 
    
    mapping (address => uint256)  public lockAmount; 

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
        //1. check r_hash repeatability

        //1. get current height
        uint256 currentHeight = block.number;

        //2. lock token by r_hash
        hashTimers[r_hash].height = currentHeight;
        hashTimers[r_hash].amount = amount;
        
        //3. publish event
        emit IssueTokenLock(r_hash, amount);
    }

    function IssueUnlock(string memory r_hash, string memory r_origin) public {
        //1. check timer
        require(!_isTimeOut(r_hash));

        //2. check hash
        
        
        //3. save r
        hashTimers[r_hash].origin = r_origin;

        //4. unlock token to user
        uint256 amount = hashTimers[r_hash].amount;
        _mint(msg.sender,amount);   

        //5. publish event
        emit IssueTokenUnlock(r_hash, r_origin);
    }
    
    function IssueFetch(string memory r_hash) public onlyOwner {
        //1. check timer
        require(_isTimeOut(r_hash));

        //
        uint256 amount = hashTimers[r_hash].amount;

        //  publish event
        emit IssueTokenFetch(r_hash, amount);
    }


    function DestoryLock(uint256 amount, string memory r_hash) public {
        //1. basic check     
        //   r_hash repeatability
        
        require(balanceOf(msg.sender)>0);
        
        //1. get current height
        uint256 currentHeight = block.number;
        
        //2. add timerlocker
        hashTimers[r_hash].height = currentHeight;
        hashTimers[r_hash].amount = amount;
        hashTimers[r_hash].user   = msg.sender;
        
        //3. add lock amount
        lockAmount[msg.sender] = lockAmount[msg.sender].add(amount);
        
        //4. publish event
        emit DestoryTokenLock(r_hash, msg.sender, amount);
    }

    function DestoryUnlock(string memory r_hash, string memory r_origin) public onlyOwner {
        //1. check timer
        require(!_isTimeOut(r_hash));

        //2. check hash 
        
        
        //3. save r
        hashTimers[r_hash].origin = r_origin;

        //4. destroy lock token
        address user = hashTimers[r_hash].user;
        uint256 amount = hashTimers[r_hash].amount;
        _burn(user, amount);
        
        //5. sub lock amount
        lockAmount[user] = lockAmount[user].sub(amount);

        //5. publish event
        emit DestoryTokenUnlock(r_hash,r_origin, user, amount);
    }
    
    function DestoryFetch(string memory r_hash) public {
        //1. check timer
        require(_isTimeOut(r_hash));
        
        //2. check user
        require(msg.sender == hashTimers[r_hash].user);

        //3. sub lock amount
        uint256 amount = hashTimers[r_hash].amount;
        lockAmount[msg.sender] = lockAmount[msg.sender].sub(amount);
        
        //4. publish event
        emit  DestoryTokenFetch(r_hash, msg.sender, amount);
    }
    
    
    function _isTimeOut(string memory r_hash) private view returns (bool) {
        uint256 currentHeight = block.number ;
        uint256 originHeight =  hashTimers[r_hash].height;
        return (currentHeight.sub(originHeight) > interval ? true: false);
    }
    
    
    function _isBalanceEnough(address addr, uint256 amount) private view returns (bool){
        uint256 lockBalance = lockAmount[addr];
        uint256 totalBalance = balanceOf(addr);
        return (totalBalance.sub(lockBalance) > amount ? true: false); 
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