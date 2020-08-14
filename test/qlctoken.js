const QLCToken = artifacts.require("QLCToken");
const chai = require('./helpers/chai');
const { assert } = require('./helpers/chai');

contract('QLCToken', async accounts => {
    it("Owner should have 0 QLCToken initially", function() {
      return QLCToken.deployed().then(function(instance) {
        return instance.balanceOf.call(accounts[0]);
      }).then(function(balance) {
        assert.equal(balance.valueOf(), 0, "Owner should have 0 QLCToken initially");
      });
    });

    it("issueLock", async () => {
      let hash = "0xc65db7f11f4f8e5b3a413c37987727d3cb30a0cf43c3bd2eeb7bb316d0bdfb64"
      let amount = 1000000
      let instance = await QLCToken.deployed();
      await instance.issueLock(hash, amount)
    });

    it("issueLock exception", async () => {
        let hash = "0x77f7ea6da86c94ee8b070eacf6dc9fec37cbe1f27ed0a5225aa81cede6eaba93"
        let amount = 1000000
        let instance = await QLCToken.deployed();
        await instance.issueLock(hash, amount)

        let timer = await instance.hashTimer(hash)
        assert.equal(timer[1], amount, "lock amount");
        assert.equal(timer[5], true, "locked state");
        assert.equal(timer[6], false, "unlocked state");

        await chai.assert.isRejected(instance.issueLock(hash, 1000000) , 'hash value is duplicated');
        await chai.assert.isRejected(instance.issueLock(hash, 1000000, {from: accounts[1]}) , 'Ownable: caller is not the owner');
    });

    it("issueUnLock", async () => {
      let instance = await QLCToken.deployed();
      let rHash = "0xc65db7f11f4f8e5b3a413c37987727d3cb30a0cf43c3bd2eeb7bb316d0bdfb64"
      let rOrigin = "0xb44980807202aff0707cc4eebad4f9e47b4d645cf9f4320653ff62dcd575897b"
      await instance.issueUnlock(rHash, rOrigin,  {from: accounts[1]})
      assert.equal(await instance.balanceOf(accounts[1]), 1000000, "account 1 amount not is incorrect");
      assert.equal(await instance.totalSupply(), 1000000, "total amount not is incorrect"); 

    });

    it("issueUnLock exception", async () => {
      let rHash   = "0x2c91e38273716587e3d33bdcf712b757048e5b7cfcf430f878f012384fdcf674"
      let rOrigin = "0x77f7ea6da86c94ee8b070eacf6dc9fec37cbe1f27ed0a5225aa81cede6eaba93"

      let amount = 1000000
      let instance = await QLCToken.deployed();

      await chai.assert.isRejected(instance.issueUnlock(rHash, rOrigin,  {from: accounts[2]}) , 'can not find locker')

      await instance.issueLock(rHash, amount)

      let rWrongOrigin = "0x9f7f18c7421a77abecafef26824aeda88f09110b396530f356e98141e4d333e5"
      await chai.assert.isRejected(instance.issueUnlock(rHash, rWrongOrigin,  {from: accounts[2]}) , 'hash value is mismatch')
 
      await instance.issueUnlock(rHash, rOrigin,  {from: accounts[2]})
      assert.equal(await instance.balanceOf(accounts[0]), 0,      "account 0 amount not is incorrect");
      assert.equal(await instance.balanceOf(accounts[2]), amount, "account 1 amount not is incorrect");
      
      let timer = await instance.hashTimer(rHash)
      assert.equal(timer[1], amount, "lock amount");
      assert.equal(timer[5], true, "locked state");
      assert.equal(timer[6], true, "unlocked state"); 

      await chai.assert.isRejected(instance.issueUnlock(rHash, rOrigin) , 'locker has been unlocked')
  });
  

  it("issueFetch", async () => {
  })


  it("destoryLock", async () => {
    let instance = await QLCToken.deployed();
    let hash = "0x56e6fa90e0b4eca7f559d9755e58ad623bf1d06209ee88e365e5ca8582419d39"
    let amount = 600000
    await instance.destoryLock(hash, amount, accounts[0], {from: accounts[1]})
  })

  it("destoryLock exception", async () => {
    let instance = await QLCToken.deployed();
    let b = await instance.balanceOf(accounts[2])
    assert.equal(b, 1000000)

    let hash = "0x72f138f8dcc8efeebaaacd666e791cedb2f2df60e8d298e1cfb82e6f5a079600"
    let amount = 600000

    await chai.assert.isRejected(instance.destoryLock(hash, amount, accounts[2]) , 'executor must be contract owner')
    await chai.assert.isRejected(instance.destoryLock(hash, amount+10, accounts[0]) , 'available balance is not enough')

    await instance.destoryLock(hash, amount, accounts[0], {from: accounts[2]})

    let timer = await instance.hashTimer(hash)
    assert.equal(timer[1], amount, "lock amount");
    assert.equal(timer[2], accounts[2], "lock address"); 
    assert.equal(timer[5], true, "locked state");
    assert.equal(timer[6], false, "unlocked state");

    await chai.assert.isRejected(instance.destoryLock(hash, amount, accounts[0]) , 'hash value is duplicated')
  })

  it("destoryUnlock", async () => {
  })

  it("destoryFetch", async () => {
  })




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

