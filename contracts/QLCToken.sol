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
    
    /**
     * @dev Emitted Mint Info
     *
     * Parameters:
     * - `user`: index, user address
     * - `nep5Hash`: neo transaction hash
     * - `amount`: mint amount
     */
    event Mint(address indexed user, bytes32 nep5Hash, uint256 amount);

    /**
     * @dev Emitted Burn Info
     *
     * Parameters:
     * - `user`: index, user address
     * - `nep5Hash`: nep5 token receiver address
     * - `amount`: burn amount
     */
    event Burn(address indexed user, string nep5Addr, uint256 amount);

    /**
     * @dev Initializes the QLCToken
     *
     * Parameters:
     * - `name`: name of the token
     * - `symbol`: the token symbol
     */
    function initialize(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        _setupDecimals(8);
        _mint(msg.sender, 0);
    }


    /**
     * @dev mint `amount` token to user
     * Emits a {Mint} event.
     *
     * Parameters:
     * - `amount` mint amount
     * - `nep5Hash` neo transaction hash
     * - `signature` owner's signature 
     */
    function mint(uint256 amount, bytes32 nep5Hash, bytes memory signature) public {
        require(lockedAmount[nep5Hash] == 0, "duplicated hash");
        bytes memory rBytes = abi.encodePacked(amount, msg.sender, nep5Hash);
        bytes32 h = sha256(rBytes);	
        require(h.recover(signature) == owner(), "invalid signature");

        _mint(msg.sender, amount);
        lockedAmount[nep5Hash] = amount;
        emit Mint(msg.sender, nep5Hash, amount);
    }

    /**
     * @dev burn `amount` from user
     * Emits a {Burn} event.
     *
     * Parameters:
     * - `nep5Addr` nep5 token receiver address
     * - `amount` burn amount
     */
    function burn(string memory nep5Addr, uint256 amount) public {
        require(bytes(nep5Addr).length == 34, "invalid nep5 address");
        _burn(msg.sender, amount);
        emit Burn(msg.sender, nep5Addr, amount);
    }
}
