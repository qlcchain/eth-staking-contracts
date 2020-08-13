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
        await instance.issueLock.call(hash,1000000)

        // let a = await instance.hashTimers.call(hash)
        // console.log(a.toNumber())

    });

    // it("send", async () => {
    //     let account_one = accounts[0];
    //     let account_two = accounts[1];
    
    //     let amount = 10;
    
    //     let instance = await QLCToken.deployed();
    //     let meta = instance;
    
    //     let balance = await meta.getBalance.call(account_one);
    //     let account_one_starting_balance = balance.toNumber();
    
    //     balance = await meta.getBalance.call(account_two);
    //     let account_two_starting_balance = balance.toNumber();
    //     await meta.transfer(account_two, amount);
    
    //     balance = await meta.getBalance.call(account_one);
    //     let account_one_ending_balance = balance.toNumber();
    
    //     balance = await meta.getBalance.call(account_two);
    //     let account_two_ending_balance = balance.toNumber();

    //     console.log(account_one_starting_balance)
    //     console.log(account_one_ending_balance)
    //     console.log(account_two_starting_balance)
    //     console.log(account_two_ending_balance)
    //     console.log(await meta.balanceOf.call(account_one))
    //  });
  
});

// contract('QLCToken', function(accounts) {
//     it("should call a function that depends on a linked library", () => {
//         let meta;
//         let hash = "0x77f7ea6da86c94ee8b070eacf6dc9fec37cbe1f27ed0a5225aa81cede6eaba93"
    
//         return QLCToken.deployed()
//           .then(instance => {
//             meta = instance;
//             return meta.issueLock.call( hash,1000000);
//           })
//           .then(() => {
//              return  meta.balanceOf.call(accounts[0]);
//         }).then((balance) =>{
//             console.log(balance.toNumber())
//         }).then(()=>{
//            return meta.hashTimers.call(hash);
//         }).then((balance) =>{
//             console.log(balance.toNumber())
//         });
//     }); 
// });
