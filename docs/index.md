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

### `hashTimer(bytes32 rHash) → bytes32, uint256, address, uint256, uint256, bool` (public)



Return detail info of hash-timer locker
Parameters:
- `rHash` is the hash of locker
Returns:
- the origin text of locker
- locked amount
- account with locked token
- locked block height
- unlocked block height
- `true` is issue phase, `false` is destory phase


### `LockedState(bytes32 rHash, uint256 state, bytes32 rOrigin)`



Emitted locker state changed
Parameters:
- `rHash`: index, the hash of locker
- `state`: locker state, 0:issueLock, 1:issueUnlock, 2:issueFetch, 3:destoryLock, 4:destoryUnlock, 5:destoryFetch
- `rOrigin`: the origin text of locker

