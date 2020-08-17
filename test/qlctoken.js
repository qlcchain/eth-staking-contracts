const QLCToken = artifacts.require("QLCToken");
const chai = require('./helpers/chai');
const { assert } = require('./helpers/chai');
const { format } = require('prettier');

contract('QLCToken', async accounts => {
    let issueRHash = "0xc65db7f11f4f8e5b3a413c37987727d3cb30a0cf43c3bd2eeb7bb316d0bdfb64"
    let issueROrigin = "0xb44980807202aff0707cc4eebad4f9e47b4d645cf9f4320653ff62dcd575897b"
    let issueAmount = 1000000

    it("Owner should have 0 QLCToken initially", function() {
      return QLCToken.deployed().then(function(instance) {
        return instance.balanceOf.call(accounts[0]);
      }).then(function(balance) {
        assert.equal(balance.valueOf(), 0, "Owner should have 0 QLCToken initially");
      });
    });

    it("issueLock", async () => {
      let instance = await QLCToken.deployed();
      await instance.issueLock(issueRHash, issueAmount)

      // check timer
      let timer = await instance.hashTimer(issueRHash)
      assert.equal(timer[1], issueAmount, "lock amount");
      assert.ok(timer[3] > 0 , "locked state");
      assert.ok(timer[4] == 0 , "unlocked state");
      assert.equal(timer[5], true, "is issue");
    });

    it("issueLock exception", async () => {
        let instance = await QLCToken.deployed();
        await chai.assert.isRejected(instance.issueLock(issueRHash, issueAmount) , 'hash value is duplicated');
        await chai.assert.isRejected(instance.issueLock('0x0', issueAmount) , 'rHash can not be zero')

        let minAmount = 1
        let reHash = "0xb44980807202aff0707cc4eebad4f9e47b4d645cf9f4320653ff62dcd575897b"
        await chai.assert.isRejected(instance.issueLock(reHash, minAmount-1) , 'amount should not less than min amount') 
        await chai.assert.isRejected(instance.issueLock(reHash, issueAmount, {from: accounts[1]}) , 'Ownable: caller is not the owner');
    });

    it("issueUnLock", async () => {
      let instance = await QLCToken.deployed();
      await instance.issueUnlock(issueRHash, issueROrigin,  {from: accounts[1]})

      // check balance
      assert.equal(await instance.balanceOf(accounts[1]), issueAmount, "account 1 amount not is incorrect");
      assert.equal(await instance.totalSupply(), issueAmount, "total amount not is incorrect");
      
      // check timer
      let timer = await instance.hashTimer(issueRHash)
      console.log(timer[3],timer[4])
      assert.equal(timer[0], issueROrigin, "lock origin"); 
      assert.equal(timer[1], issueAmount, "lock amount");
      assert.ok(timer[3] > 0 , "locked state");
      assert.ok(timer[4] > 0 , "unlocked state");
      assert.equal(timer[5], true, "is issue");

    });

    it("issueUnLock exception", async () => {
      let instance = await QLCToken.deployed();
      let rHash   = "0x2c91e38273716587e3d33bdcf712b757048e5b7cfcf430f878f012384fdcf674"
      await chai.assert.isRejected(instance.issueUnlock(rHash, issueROrigin,  {from: accounts[2]}) , 'can not find locker')
      await chai.assert.isRejected(instance.issueUnlock(issueRHash, issueROrigin,  {from: accounts[2]}) , 'locker has been unlocked')

      await instance.issueLock(rHash, issueAmount)
      await chai.assert.isRejected(instance.issueUnlock(rHash, issueROrigin,  {from: accounts[2]}) , 'hash value is mismatch')
  });
  

  // it("issueFetch", async () => {
  // })


  let destoryRHash = "0xcabd59462f2932b25753e4a4fa1ddf766c46589dd70486bf4d99c39b3d23560a"
  let destoryROrigin = "0x9f7f18c7421a77abecafef26824aeda88f09110b396530f356e98141e4d333e5"
  let destoryAmount = 400000

  it("destoryLock", async () => {
    let instance = await QLCToken.deployed();
    await instance.destoryLock(destoryRHash, destoryAmount, accounts[0], {from: accounts[1]})

    // check timer
    let timer = await instance.hashTimer(destoryRHash)
    assert.equal(timer[1], destoryAmount, "lock amount");
    assert.equal(timer[2], accounts[1], "lock account");
    assert.ok(timer[3] > 0 , "locked state");
    assert.ok(timer[4] == 0 , "unlocked state");
    assert.equal(timer[5], false, "is issue");

    // check locked amount
    let lockedAmount = await instance.lockedBalanceOf(accounts[1])
    assert.equal(lockedAmount, destoryAmount, "locked amount"); 
  })

  it("destoryLock exception", async () => {
    let instance = await QLCToken.deployed();
    let deHash = "0xb44980807202aff0707cc4eebad4f9e47b4d645cf9f4320653ff62dcd575897b"
    await chai.assert.isRejected(instance.destoryLock('0x0', destoryAmount, accounts[0]) , 'rHash can not be zero')
    await chai.assert.isRejected(instance.destoryLock(deHash, 0, accounts[0]) , 'amount should more than zero') 
    await chai.assert.isRejected(instance.destoryLock(destoryRHash, destoryAmount, accounts[0]) , 'hash value is duplicated');
    await chai.assert.isRejected(instance.destoryLock(deHash, destoryAmount, accounts[2]) , 'executor must be contract owner')
    await chai.assert.isRejected(instance.destoryLock(deHash, issueAmount+10, accounts[0]) , 'available balance is not enough')
  })

  it("destoryUnlock", async () => {
    let instance = await QLCToken.deployed();
    await instance.destoryUnlock(destoryRHash, destoryROrigin)

    // check balance
    assert.equal(await instance.balanceOf(accounts[1]), issueAmount - destoryAmount, "account 1 amount not is incorrect");
    assert.equal(await instance.totalSupply(), issueAmount - destoryAmount, "total amount not is incorrect");
   
    // check locked amount
    let lockedAmount = await instance.lockedBalanceOf(accounts[1])
    assert.equal(lockedAmount, 0, "locked amount"); 
    
    // check timer
    let timer = await instance.hashTimer(destoryRHash)
    assert.equal(timer[0], destoryROrigin, "lock origin"); 
    assert.equal(timer[1], destoryAmount, "lock amount");
    assert.ok(timer[3] > 0 , "locked state");
    assert.ok(timer[4] > 0 , "unlocked state");
    assert.equal(timer[5], false, "is issue");
  })

  it("destoryUnlock exception", async () => {
    let instance = await QLCToken.deployed();
    let dHash   = "0xd2fde0d1dbc48bcbabd8fc703249cc54821670e2e4ec263dda1e48b9cf11fe3e"

    await chai.assert.isRejected(instance.destoryUnlock(destoryRHash, destoryROrigin, {from: accounts[2]}) , 'Ownable: caller is not the owner');
    await chai.assert.isRejected(instance.destoryUnlock(dHash, destoryROrigin) , 'can not find locker')
    await chai.assert.isRejected(instance.destoryUnlock(destoryRHash, destoryROrigin) , 'locker has been unlocked')

    await instance.destoryLock(dHash, 10, accounts[0], {from: accounts[1]})
    await chai.assert.isRejected(instance.destoryUnlock(dHash, destoryROrigin) , 'hash value is mismatch')
});


  // it("destoryFetch", async () => {
  // })

    // it("send", async () => {
    //     let account_one = accounts[0];
    //     let account_two = accounts[1];
    
    //     let amount = 10;
    
    //     let instance = await QLCToken.deployed();
    //     let meta = instance;
    
    //     let balance = await meta.balanceOf.call(account_one);
    //     let account_one_starting_balance = balance.toNumber();
    
    //     balance = await meta.balanceOf.call(account_two);
    //     let account_two_starting_balance = balance.toNumber();
    //     await meta.transfer(account_two, amount);
    
    //     balance = await meta.balanceOf.call(account_one);
    //     let account_one_ending_balance = balance.toNumber();
    
    //     balance = await meta.balanceOf.call(account_two);
    //     let account_two_ending_balance = balance.toNumber();

    //     console.log(account_one_starting_balance)
    //     console.log(account_one_ending_balance)
    //     console.log(account_two_starting_balance)
    //     console.log(account_two_ending_balance)
    //     console.log(await meta.balanceOf.call(account_one))
    //  });
});

