## `Migrations`





### `restricted()`






### `setCompleted(uint256 completed)` (public)





### `upgrade(address newAddress)` (public)








## `QLCToken`



QLC contract.


### `issueLock(bytes32 rHash, uint256 amount)` (public)



Issue `amount` token and locked by `rHash`
Only callable by the Owner.
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker, cannot be the zero.
- `amount` should more than zero.

### `issueUnlock(bytes32 rHash, bytes32 rOrigin)` (public)



Unlock `rHash` locked token by origin text `rOrigin`
Emits a {LockedState} event.
Parameters:
- `rHash` is the hash of locker
- `rOrigin` is the origin text of locker

### `issueFetch(bytes32 rHash)` (public)





### `destoryLock(bytes32 rHash, uint256 amount, address executor)` (public)





### `destoryUnlock(bytes32 rHash, bytes32 rOrigin)` (public)





### `destoryFetch(bytes32 rHash)` (public)





### `hashTimer(bytes32 rHash) → bytes32, uint256, address, uint256, uint256, bool, bool` (public)





### `lockedBalanceOf(address addr) → uint256` (public)





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

### `isHashValid(bytes32 rHash, bytes32 rOrigin) → bool` (public)






### `LockedState(bytes32 rHash, string state, uint256 amount, address user, bytes32 rOrigin)`





