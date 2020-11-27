const QLCToken = artifacts.require("QLCToken");
const {sha256, solidityPack, hexlify} = require("ethers/utils");
const truffleAssert = require('truffle-assertions');
const chai = require('chai');
const util = require("ethereumjs-util");
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised);


contract('QLCToken', ([alice, bob, carol, james])  => {
    beforeEach(async () => {
      this.instance = await  QLCToken.deployed();
    });

    it("basic info", async () => {
      assert.equal(await this.instance.balanceOf(alice), 0, "Owner should have 0 QLCToken initially"); 
      assert.equal(await this.instance.owner(), alice, "wrong owner");
      assert.equal(await this.instance.symbol(), "QLC", "wrong symbol"); 
      assert.equal(await this.instance.totalSupply(), 0, "wrong totalSupply");  
      assert.equal(await this.instance.name(), "QLCToken", "wrong name");   
      assert.equal(await this.instance.decimals(), 8, "wrong decimals");   
    });

    const mintAmount = 2000000000
    it("mint", async () => {
        const a = web3.eth.accounts.privateKeyToAccount(
          "0x67652fa52357b65255ac38d0ef8997b5608527a7c1d911ecefb8bc184d74e92e"
        );
        const tomKey = a.privateKey;
        const tom = a.address;
        web3.eth.personal.importRawKey(tomKey, "");
        web3.eth.personal.unlockAccount(tom, "", 60000);
 
        console.log("tom address: ", tom)
        console.log("bob address(mint address):", bob)
 
        let nep5Hash = "0x1d3f2eb6d6c73b2c4ca325c8ac18141577761e43abb0154412ef4d36b11ff1b4"
        let packed = solidityPack(
          [ "uint256", "address", "bytes32"],
          [ mintAmount, bob, nep5Hash]
        )
        console.log("encode: ", packed)

        // packed = "0x0000000000000000000000000000000000000000000000000000000005f5e100f17f52151ebef6c7334fad080c5704d77216b7321d3f2eb6d6c73b2c4ca325c8ac18141577761e43abb0154412ef4d36b11ff1b4"
        // const amountPacked =defaultAbiCoder.encode(
        //   [ "uint256"],
        //   [ mintAmount]
        // )
        // packed = amountPacked + bob.slice(2) + nep5Hash.slice(2)
        // console.log("encode: ", packed) 

        const hash = sha256(packed)
        console.log("sha256 hash: ", hash)        

        const priKeyBuf = util.toBuffer(tomKey);
        const {r, s, v} = util.ecsign(Buffer.from(hash.slice(2), "hex"), priKeyBuf);
        const signHex =  "0x" + hexlify(r).slice(2) + hexlify(s).slice(2) + v.toString(16)
        console.log("signature: ", signHex)
       
        const ownerA = await this.instance.owner()
        console.log("now owner is alice", ownerA) 
        await chai.assert.isRejected(this.instance.mint(mintAmount, nep5Hash,  signHex), 'invalid signature');

        await this.instance.transferOwnership(tom)
        const ownerB = await this.instance.owner()
        console.log("now owner is tom  ", ownerB)
       
        await chai.assert.isRejected(this.instance.mint(mintAmount, nep5Hash, signHex) , 'invalid signature');
        const txResult = await this.instance.mint(mintAmount, nep5Hash, signHex, {from: bob})

        truffleAssert.eventEmitted(txResult, 'Mint', (ev) => {
          assert.equal(ev.user, bob, "error user");
          assert.equal(ev.nep5Hash, nep5Hash, "error hash");
          assert.equal(ev.amount, mintAmount, "error amount");
          return true
        })

        assert.equal(await this.instance.balanceOf(bob), mintAmount, "account amount is incorrect");
        assert.equal(await this.instance.totalSupply(), mintAmount, "total amount is incorrect");

        await chai.assert.isRejected(this.instance.mint(mintAmount, nep5Hash, signHex, {from: bob}), 'duplicated hash');
    });



    it("burn", async () => {
         const burnAmount = 200000000
         assert.equal(await this.instance.balanceOf(bob), mintAmount, "account amount is incorrect");        

         const vaildNep5Addr = "AJ5sZeLANhH8t8NwqkRxEuupd6oHB4vJj2"
         const invaildNep5Addr = "AJ5sZeLANhH8t8NwqkRxEuupd6oHB4vJj23"

         const txResult = await this.instance.burn(vaildNep5Addr, burnAmount, {from: bob})
         truffleAssert.eventEmitted(txResult, 'Burn', (ev) => {
           assert.equal(ev.user, bob, "error user");
           assert.equal(ev.nep5Addr, vaildNep5Addr, "error hash");
           assert.equal(ev.amount, burnAmount, "error amount");
           return true
         })
 
         assert.equal(await this.instance.balanceOf(bob), mintAmount - burnAmount, "account amount is incorrect");
         assert.equal(await this.instance.totalSupply(),  mintAmount - burnAmount, "total amount is incorrect");

         await chai.assert.isRejected(this.instance.burn(invaildNep5Addr, burnAmount, {from: bob}), 'invalid nep5 address');
    });

  
    it("transaction", async () => {
      let trAmount = 100000

      let oBalancea = await this.instance.balanceOf(bob)
      await this.instance.transfer(carol, trAmount, {from: bob})
      assert.equal(await this.instance.balanceOf(bob), oBalancea - trAmount, "amount is incorrect");
      assert.equal(await this.instance.balanceOf(carol), trAmount, "amount is incorrect");
    }); 
  
    it("transferFrom", async () => {
      let tfAmount = 500
 
      let oBalancea = await this.instance.balanceOf(bob)
      await this.instance.approve(james, tfAmount, {from: bob})
      assert.equal(await this.instance.allowance(bob, james),  tfAmount, "error amount");
  
      await this.instance.transferFrom(bob, alice, tfAmount, {from: james})
      assert.equal(await this.instance.balanceOf(bob), oBalancea - tfAmount, "amount is incorrect");
      assert.equal(await this.instance.balanceOf(alice), tfAmount, "amount is incorrect");
    }); 
});

