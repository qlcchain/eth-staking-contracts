const QLCToken = artifacts.require("QLCToken");
// const chai = require('./helpers/chai');
// const { assert } = require('./helpers/chai');
const truffleAssert = require('truffle-assertions');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised);


contract('QLCToken', async accounts => {
    let issueRHash = "0xc65db7f11f4f8e5b3a413c37987727d3cb30a0cf43c3bd2eeb7bb316d0bdfb64"
    let issueROrigin = "0xb44980807202aff0707cc4eebad4f9e47b4d645cf9f4320653ff62dcd575897b"
    let issueAmount = 1000000

    // it("Owner should have 0 QLCToken initially", function() {
    //   return QLCToken.deployed().then(function(instance) {
    //     return instance.balanceOf.call(accounts[0]);
    //   }).then(function(balance) {
    //     assert.equal(balance.valueOf(), 0, "Owner should have 0 QLCToken initially");
    //   });
    // });

    it("basic info", async () => {
      let instance = await QLCToken.deployed();
      assert.equal(await instance.balanceOf(accounts[0]), 0, "Owner should have 0 QLCToken initially"); 
      assert.equal(await instance.owner(), accounts[0], "wrong owner");
      assert.equal(await instance.symbol(), "qlc", "wrong symbol"); 
      assert.equal(await instance.totalSupply(), 0, "wrong totalSupply");  
      assert.equal(await instance.name(), "QLCToken", "wrong name");   
      assert.equal(await instance.decimals(), 8, "wrong decimals");   
    });

    it("issueLock", async () => {
      let instance = await QLCToken.deployed();
      let txResult = await instance.issueLock(issueRHash, issueAmount)

      truffleAssert.eventEmitted(txResult, 'LockedState', (ev) => {
        assert.equal(ev.state, 0, "error state");
        assert.equal(ev.rHash, issueRHash, "error rHash");
        return true
      })

      // check timer
      let timer = await instance.hashTimer(issueRHash)
      assert.equal(timer[1], issueAmount, "lock amount");
      assert.ok(timer[3] > 0 , "locked state");
      assert.ok(timer[4] == 0 , "unlocked state");

      // check balance
      assert.equal(await instance.balanceOf(accounts[1]), 0, "account 1 amount not is incorrect");
      assert.equal(await instance.totalSupply(), issueAmount, "total amount not is incorrect");

    });

    it("issueLock exception", async () => {
        let instance = await QLCToken.deployed();
        await chai.assert.isRejected(instance.issueLock(issueRHash, issueAmount) , 'duplicated hash');
        await chai.assert.isRejected(instance.issueLock('0x0', issueAmount) , 'zero rHash')

        let minAmount = 1
        let reHash = "0xb44980807202aff0707cc4eebad4f9e47b4d645cf9f4320653ff62dcd575897b"
        await chai.assert.isRejected(instance.issueLock(reHash, minAmount-1) , 'too little amount') 
        await chai.assert.isRejected(instance.issueLock(reHash, issueAmount, {from: accounts[1]}) , 'Ownable: caller is not the owner');
    });

    it("issueUnLock", async () => {
      let instance = await QLCToken.deployed();
      let txResult = await instance.issueUnlock(issueRHash, issueROrigin,  {from: accounts[1]})

      truffleAssert.eventEmitted(txResult, 'LockedState', (ev) => {
        assert.equal(ev.state, 1, "error state");
        assert.equal(ev.rHash, issueRHash, "error rHash");
        return true
      })

      // check balance
      assert.equal(await instance.balanceOf(accounts[1]), issueAmount, "account 1 amount not is incorrect");
      assert.equal(await instance.totalSupply(), issueAmount, "total amount not is incorrect");
      
      // check timer
      let timer = await instance.hashTimer(issueRHash)
      assert.equal(timer[0], issueROrigin, "lock origin"); 
      assert.equal(timer[1], issueAmount, "lock amount");
      assert.ok(timer[3] > 0 , "locked state");
      assert.ok(timer[4] > 0 , "unlocked state");
    });

    let issueRHashEx   = "0x2c91e38273716587e3d33bdcf712b757048e5b7cfcf430f878f012384fdcf674"

    it("issueUnLock exception", async () => {
      let instance = await QLCToken.deployed();
      await chai.assert.isRejected(instance.issueUnlock(issueRHashEx, issueROrigin,  {from: accounts[2]}) , 'hash not locked')
      await chai.assert.isRejected(instance.issueUnlock(issueRHash, issueROrigin,  {from: accounts[2]}) , 'hash has unlocked')

      await instance.issueLock(issueRHashEx, issueAmount)
      await chai.assert.isRejected(instance.issueUnlock(issueRHashEx, issueROrigin,  {from: accounts[2]}) , 'hash mismatch')
    });

    it("issueFetch", async () => {
        let instance = await QLCToken.deployed()
        await chai.assert.isRejected(instance.issueFetch(issueRHashEx), 'not timeout')
        await chai.assert.isRejected(instance.issueFetch(issueRHashEx, {from: accounts[1]}), 'Ownable: caller is not the owner')
        let tRash = "0x24b0ffae9c605da524ab5d208a110e44ce186c7338ef437a1145aa7171c3770f"
        await chai.assert.isRejected(instance.issueFetch(tRash), 'hash not locked')
        await chai.assert.isRejected(instance.issueFetch(issueRHash),  'hash has unlocked')
        // let a = await instance.getHeight()
        // console.log(a.toNumber())
        // Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 1000* 9 * 5);
        // await new Promise(resolve => setTimeout(resolve, 1000 * 30))
        for (let i = 0; i < 12; i++) {
          await instance.approve(accounts[4], 1, {from: accounts[1]}) // add height
        }
        let txResult = await instance.issueFetch(issueRHashEx) 

        truffleAssert.eventEmitted(txResult, 'LockedState', (ev) => {
          assert.equal(ev.state, 2, "error state");
          assert.equal(ev.rHash, issueRHashEx, "error rHash");
          return true
        })
 
        // check timer
        let timer = await instance.hashTimer(issueRHashEx)
        assert.equal(timer[0], 0x0, "lock origin")
        assert.equal(timer[1], issueAmount, "lock amount")
        assert.ok(timer[3] > 0 , "locked state")
        assert.ok(timer[4] > 0 , "unlocked state")
    })


    let destoryRHash = "0xcabd59462f2932b25753e4a4fa1ddf766c46589dd70486bf4d99c39b3d23560a"
    let destoryROrigin = "0x9f7f18c7421a77abecafef26824aeda88f09110b396530f356e98141e4d333e5"
    let destoryAmount = 300000
  
    it("destoryLock", async () => {
      let instance = await QLCToken.deployed();
      let txResult = await instance.destoryLock(destoryRHash, destoryAmount, accounts[0], {from: accounts[1]})
  
      truffleAssert.eventEmitted(txResult, 'LockedState', (ev) => {
        assert.equal(ev.state, 3, "error state");
        assert.equal(ev.rHash, destoryRHash, "error rHash");
        return true
      })
  
      // check timer
      let timer = await instance.hashTimer(destoryRHash)
      assert.equal(timer[1], destoryAmount, "lock amount");
      assert.equal(timer[2], accounts[1], "lock account");
      assert.ok(timer[3] > 0 , "locked state");
      assert.ok(timer[4] == 0 , "unlocked state");
  
      // check balance
      assert.equal(await instance.balanceOf(accounts[1]), issueAmount - destoryAmount, "account 1 amount not is incorrect");
      assert.equal(await instance.totalSupply(), issueAmount, "total amount not is incorrect");
    })
  
    it("destoryLock exception", async () => {
      let instance = await QLCToken.deployed();
      let deHash = "0xb44980807202aff0707cc4eebad4f9e47b4d645cf9f4320653ff62dcd575897b"
      await chai.assert.isRejected(instance.destoryLock('0x0', destoryAmount, accounts[0]) , 'zero rHash')
      // await chai.assert.isRejected(instance.destoryLock(deHash, 0, accounts[0]) , 'amount should more than zero') 
      await chai.assert.isRejected(instance.destoryLock(destoryRHash, destoryAmount, accounts[0]) , 'duplicated hash');
      await chai.assert.isRejected(instance.destoryLock(deHash, destoryAmount, accounts[2]) , 'wrong executor')
      // await chai.assert.isRejected(instance.destoryLock(deHash, issueAmount+10, accounts[0]) , 'available balance is not enough')
    })
  
    it("destoryUnlock", async () => {
      let instance = await QLCToken.deployed();
      await instance.approve(accounts[4], 1, {from: accounts[1]}) // add height
      let txResult = await instance.destoryUnlock(destoryRHash, destoryROrigin)
  
      truffleAssert.eventEmitted(txResult, 'LockedState', (ev) => {
        assert.equal(ev.state, 4, "error state");
        assert.equal(ev.rHash, destoryRHash, "error rHash");
        return true
      })
  
      // check balance
      assert.equal(await instance.balanceOf(accounts[1]), issueAmount - destoryAmount, "account 1 amount not is incorrect");
      assert.equal(await instance.totalSupply(), issueAmount - destoryAmount, "total amount not is incorrect");
    
      // check timer
      let timer = await instance.hashTimer(destoryRHash)
      assert.equal(timer[0], destoryROrigin, "lock origin"); 
      assert.equal(timer[1], destoryAmount, "lock amount");
      assert.ok(timer[3] > 0 , "locked state");
      assert.ok(timer[4] > 0 , "unlocked state");
    })
  
    let destoryRHashEx   = "0xd2fde0d1dbc48bcbabd8fc703249cc54821670e2e4ec263dda1e48b9cf11fe3e"
  
    it("destoryUnlock exception", async () => {
      let instance = await QLCToken.deployed();
  
      await chai.assert.isRejected(instance.destoryUnlock(destoryRHashEx, destoryROrigin, {from: accounts[2]}) , 'Ownable: caller is not the owner');
      await chai.assert.isRejected(instance.destoryUnlock(destoryRHashEx, destoryROrigin) , 'hash not locked')
      await chai.assert.isRejected(instance.destoryUnlock(destoryRHash, destoryROrigin) , 'hash has unlocked')
  
      await instance.destoryLock(destoryRHashEx, destoryAmount, accounts[0], {from: accounts[1]})
      await chai.assert.isRejected(instance.destoryUnlock(destoryRHashEx, destoryROrigin) , 'hash mismatch')
    });
  
    it("destoryFetch", async () => {
      let instance = await QLCToken.deployed()
      await chai.assert.isRejected(instance.destoryFetch(destoryRHashEx, {from: accounts[2]}), 'wrong caller')
      let tRash = "0x24b0ffae9c605da524ab5d208a110e44ce186c7338ef437a1145aa7171c3770f"
      await chai.assert.isRejected(instance.destoryFetch(tRash), 'hash not locked')
      await chai.assert.isRejected(instance.destoryFetch(destoryRHash),  'hash has unlocked')
      await chai.assert.isRejected(instance.destoryFetch(destoryRHashEx,{from: accounts[1]}), 'not timeout')
      for (let i = 0; i < 22; i++) {
        await instance.approve(accounts[4], 1, {from: accounts[1]}) // add height
      }
      let txResult = await instance.destoryFetch(destoryRHashEx,{from: accounts[1]}) 
  
      truffleAssert.eventEmitted(txResult, 'LockedState', (ev) => {
        assert.equal(ev.state, 5, "error state");
        assert.equal(ev.rHash, destoryRHashEx, "error rHash");
        return true
      })
  
      // check timer
      let timer = await instance.hashTimer(destoryRHashEx)
      assert.equal(timer[0], 0x0, "lock origin")
      assert.equal(timer[1], destoryAmount, "lock amount")
      assert.ok(timer[3] > 0 , "locked state")
      assert.ok(timer[4] > 0 , "unlocked state")
    })
  
    let trAmount = 100000
  
    it("transaction", async () => {
      let instance = await QLCToken.deployed();
      let oBalancea = await instance.balanceOf(accounts[1])
      await instance.transfer(accounts[4], trAmount, {from: accounts[1]})
      assert.equal(await instance.balanceOf(accounts[1]), oBalancea - trAmount, "account a amount not is incorrect");
      assert.equal(await instance.balanceOf(accounts[4]), trAmount, "account b amount not is incorrect");
    }); 
  
    it("transferFrom", async () => {
      let instance = await QLCToken.deployed();
      let tfAmount = 500
  
      await instance.approve(accounts[5], tfAmount, {from: accounts[4]})
      assert.equal(await instance.allowance(accounts[4], accounts[5]),  tfAmount, "error amount");
  
      await instance.transferFrom(accounts[4], accounts[6], tfAmount, {from: accounts[5]})
      assert.equal(await instance.balanceOf(accounts[4]), trAmount - tfAmount, "account a amount not is incorrect");
      assert.equal(await instance.balanceOf(accounts[6]), tfAmount, "account b amount not is incorrect");
    }); 
  
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

