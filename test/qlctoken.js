const QLCToken = artifacts.require("QLCToken");

contract('QLCToken', async accounts => {
    it("Owner should have 0 QLCToken initially", function() {
      return QLCToken.deployed().then(function(instance) {
        return instance.balanceOf.call(accounts[0]);
      }).then(function(balance) {
        assert.equal(balance.valueOf(), 0, "Owner should have 0 QLCToken initially");
      });
    });

    it("issueLock", async () => {
        let instance = await QLCToken.deployed();
        let hash = "0x77f7ea6da86c94ee8b070eacf6dc9fec37cbe1f27ed0a5225aa81cede6eaba93"
        let amount = 1000000
        await instance.issueLock(hash, amount)

        let timer = await instance.hashTimer(hash)

        assert.equal(timer[2], amount, "lock amount");
        assert.equal(timer[4], true, "locked state");
        assert.equal(timer[5], false, "unlocked state");
   
        // chai.assert.isRejected(await instance.issueLock(hash, 1000000) , 'Amount is not valid number');
        // assert.isRejected(await instance.issueLock(hash, 1000000) )
        // await instance.issueLock(hash, 1000000) 

        console.log(timer)

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

