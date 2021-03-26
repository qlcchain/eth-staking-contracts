// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";

/**
 * @notice QGasToken contract realizes cross-chain with QGas
 */
contract QGasToken is Initializable, ERC20UpgradeSafe, OwnableUpgradeSafe {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    mapping(bytes32 => bytes32) private _lockedOrigin;
    mapping(bytes32 => uint256) private _lockedAmount;
    mapping(bytes32 => address) private _lockedUser;
    mapping(bytes32 => uint256) private _lockedHeight;
    mapping(bytes32 => uint256) private _unlockedHeight;

    uint256 private _issueInterval;
    uint256 private _destoryInterval;
    uint256 private _minIssueAmount;
    uint256 private _minDestroyAmount;

    mapping(bytes32 => uint256) public lockedAmount;

    uint256 public id;
    bool public active;
    modifier isActive {
        require(active == true);
        _;
    }
    /**
     * @dev Emitted Mint Info
     *
     * Parameters:
     * - `user`: index, user address
     * - `qlcHash`: qlc transaction hash
     * - `amount`: mint amount
     */
    event Mint(address indexed user, bytes32 qlcHash, uint256 amount);

    /**
     * @dev Emitted Burn Info
     *
     * Parameters:
     * - `user`: index, user address
     * - `qlcHash`: qgas token receiver address
     * - `amount`: burn amount
     */
    event Burn(address indexed user, string qlcAddr, uint256 amount);

    /**
     * @dev Initializes the QGasToken
     *
     * Parameters:
     * - `name`: name of the token
     * - `symbol`: the token symbol
     */
    function initialize(string memory _name, string memory _symbol, uint256 _id) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        _setupDecimals(8);
        _mint(msg.sender, 0);
        id = _id;
        active = true;
    }


    /**
     * @dev mint `amount` token to user
     * Emits a {Mint} event.
     *
     * Parameters:
     * - `amount` mint amount
     * - `qlcHash` qlc transaction hash
     * - `signature` owner's signature 
     */
    function mint(uint256 amount, bytes32 qlcHash, bytes memory signature) public isActive {
        require(lockedAmount[qlcHash] == 0, "duplicated hash");
        bytes memory rBytes = abi.encodePacked(amount, msg.sender, qlcHash, id);
        bytes32 h = sha256(rBytes);	
        require(h.recover(signature) == owner(), "invalid signature");

       lockedAmount[qlcHash] = amount;
        _mint(msg.sender, amount);
        emit Mint(msg.sender, qlcHash, amount);
    }

    /**
     * @dev burn `amount` from user
     * Emits a {Burn} event.
     *
     * Parameters:
     * - `qlcAddr` qgas token receiver address
     * - `amount` burn amount
     */
    function burn(string memory qlcAddr, uint256 amount) public isActive {
        require(bytes(qlcAddr).length == 64, "invalid qlc address");
        _burn(msg.sender, amount);
        emit Burn(msg.sender, qlcAddr, amount);
    }

    function circuitBraker() public onlyOwner {
        active = !active;
    }
}