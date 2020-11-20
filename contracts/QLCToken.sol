// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";

/**
 * @notice QLCToken contract realizes cross-chain with Nep5 QLC
 */
contract QLCToken is Initializable, ERC20UpgradeSafe, OwnableUpgradeSafe {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    mapping(bytes32 => uint256) public lockedAmount;
    mapping(address => uint256) public mintAmount;
    mapping(address => uint256) public burnAmount;
    uint256 public minIssueAmount;
    uint256 public minDestroyAmount;
    
    event Mint(address indexed user, bytes32 nep5Hash,  uint256 amount);
    event Burn(address indexed user, string nep5Addr, uint256 amount);

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        _setupDecimals(8);
        _mint(msg.sender, 0);

        minIssueAmount = 10;
        minDestroyAmount = 10;
    }

    function mint(uint256 amount,  bytes32 nep5Hash, bytes memory signature) public {
        require(lockedAmount[nep5Hash] == 0, "duplicated hash");
        require(amount >= minIssueAmount, "too little amount");
        bytes memory rBytes = abi.encodePacked(amount, msg.sender, nep5Hash);
        bytes32 h = sha256(rBytes);	
        require(h.recover(signature) == owner(), "invalid signature");

        _mint(msg.sender, amount);

        lockedAmount[nep5Hash] = amount;
        mintAmount[msg.sender] = mintAmount[msg.sender].add(amount);
        emit Mint(msg.sender, nep5Hash, amount);
    }

    function burn(string memory nep5Addr, uint256 amount) public {
        require(amount >= minDestroyAmount, "too little amount");

        _burn(msg.sender, amount);

        burnAmount[msg.sender] = burnAmount[msg.sender].add(amount);
        emit Burn(msg.sender, nep5Addr, amount);
    }
}
