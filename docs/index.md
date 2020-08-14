## `Migrations`





### `restricted()`






### `setCompleted(uint256 completed)` (public)





### `upgrade(address newAddress)` (public)








## `QLCToken`



QLCToken contract realizes cross-chain with Nep5 QLC


### `issueLock(bytes32 rHash, uint256 amount)` (public)



Issue `amount` token and locked by `rHash`
Only callable by the Owner.
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker, cannot be zero and duplicated 
- `amount` should not less than `_minAmount`

### `issueUnlock(bytes32 rHash, bytes32 rOrigin)` (public)



caller provide locker origin text `rOrigin` to unlock token and release to his account
`issueUnlock` must be executed after `issueLock` and the interval must less then `_issueInterval`
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker
- `rOrigin` is the origin text of locker

### `issueFetch(bytes32 rHash)` (public)



`issueFetch` must be executed after `issueLock` and the interval must more then `_issueInterval`
destory the token locked by `rHash`
Only callable by the Owner. 
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker

### `destoryLock(bytes32 rHash, uint256 amount, address executor)` (public)



lock caller's `amount` token by `rHash`
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker, cannot be zero and duplicated 
- `amount` should more than zero.
- `executor` should be owner's address

### `destoryUnlock(bytes32 rHash, bytes32 rOrigin)` (public)



Destory `rHash` locked token by origin text `rOrigin`
`destoryUnlock` must be executed after `destoryLock` and the interval must less then `_destoryInterval`
Only callable by the Owner. 
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker
- `rOrigin` is the origin text of locker

### `destoryFetch(bytes32 rHash)` (public)



`destoryFetch` must be executed after `destoryLock` and the interval must more then `_destoryInterval`
unlock token and return back to caller
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker

### `hashTimer(bytes32 rHash) → bytes32, uint256, address, uint256, uint256, bool, bool, bool` (public)



Return detail info of hash-timer locker
Parameters:
- `rHash` is the hash of locker

Returns:
- the origin text of locker
- locked amount
- account with locked token 
- locked block height
- unlocked block height
- locked state, true or false
- unlocked state, true or false
- `true` is issue phase, `false` is destory phase

### `lockedBalanceOf(address addr) → uint256` (public)



Return `addr`'s locked balance in destory phase
Parameters:
- `addr`: erc20 address

Returns:
- locked amount

### `transfer(address recipient, uint256 amount) → bool` (public)



Moves `amount` tokens from the caller's account to `recipient`
Returns a boolean value indicating whether the operation succeeded.
Emits a {Transfer} event.
Parameters:
- `recipient` cannot be the zero address.
-  the caller must have a balance of at least `amount`.

### `transferFrom(address sender, address recipient, uint256 amount) → bool` (public)



Moves `amount` tokens from `sender` to `recipient` using the
allowance mechanism. `amount` is then deducted from the caller's
allowance.
Returns a boolean value indicating whether the operation succeeded.
Emits a {Transfer} event.
Parameters:
- `sender` and `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`.
-  the caller must have allowance for ``sender``'s tokens of at least `amount`.


### `LockedState(bytes32 rHash, string state, uint256 amount, address user, bytes32 rOrigin)`



Emitted locker state changed
Parameters:
- `rHash`: index, the hash of locker
- `state`: locker state
- `amount`: locked amount
- `user`: account with locked token 
- `rOrigin`: the origin text of locker

