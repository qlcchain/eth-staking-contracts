## `Migrations`





### `restricted()`






### `setCompleted(uint256 completed)` (public)





### `upgrade(address newAddress)` (public)








## `QLCToken`

QLCToken contract realizes cross-chain with Nep5 QLC




### `initialize(string name, string symbol)` (public)



Initializes the QLCToken

Parameters:
- `name`: name of the token
- `symbol`: the token symbol

### `mint(uint256 amount, bytes32 nep5Hash, bytes signature)` (public)



mint `amount` token to user
Emits a {Mint} event.

Parameters:
- `amount` mint amount
- `nep5Hash` neo transaction hash
- `signature` owner's signature

### `burn(string nep5Addr, uint256 amount)` (public)



burn `amount` from user
Emits a {Burn} event.

Parameters:
- `nep5Addr` nep5 token receiver address
- `amount` burn amount


### `Mint(address user, bytes32 nep5Hash, uint256 amount)`



Emitted Mint Info
d
Parameters:
- `user`: index, user address
- `nep5Hash`: neo transaction hash
- `amount`: mint amount

### `Burn(address user, string nep5Addr, uint256 amount)`



Emitted Burn Info
d
Parameters:
- `user`: index, user address
- `nep5Hash`: nep5 token receiver address
- `amount`: burn amount

