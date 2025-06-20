const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const { expect } = require("chai");

describe("AryContract", function () {
    //deploys contract under owner
    const startTkn = 1;

    async function deployContract() {
        const [owner, account1, account2] = await ethers.getSigners();
        const aryContract = await ethers.deployContract("AryCoin");
        return {owner, account1, account2, aryContract};
    }

    //mints token to given account
    async function mintToAccount(contractParam, acc) {
        const infoStr = ("this is the minted test struct");
        contractParam.mintCoin(infoStr, acc);
    }

    it("Minting should result in a token in account1", async function () {
        const {owner, account1, account2, account3, aryContract} = await loadFixture(deployContract);
        const infoStr = ("this is the minted test struct");
        await aryContract.mintCoin(infoStr, account1);
        expect(await aryContract.ownerOf(startTkn)).to.equal(account1);
    });

    it("Transferring from account1 to account2 should update both accounts", async function(){
        const {owner, account1, account2, aryContract} = await loadFixture(deployContract);
        //mint to account 1
        await mintToAccount(aryContract, account1);
        //calling function from account1 instead of default (owner)
        await aryContract.connect(account1).transferFrom(account1, account2, startTkn);

        var tokenArr = await aryContract.getOwning(account1);
        var tokenArr2 = await aryContract.getOwning(account2);
        tokenArr = getTokensOwned(tokenArr);
        tokenArr2 = getTokensOwned(tokenArr2);

        expect(tokenArr.length).to.equal(0);
        expect(tokenArr2.length).to.equal(1);
        expect(await aryContract.ownerOf(startTkn)).to.equal(account2);
    });

    it("Should not be able to approve more than one other account for a token.", async function() {
        //deploy and mint contract to account 1.
        const {owner, account1, account2, aryContract} = await loadFixture(deployContract);
        //mint to account 1
        await mintToAccount(aryContract, account1);
        
        await aryContract.connect(account1).approve(account2, startTkn);
        //add account 2 as an approved account from account 1.
        
        //try to add owner as an approved account.
        //await aryContract.connect(account1).approve(owner, startTkn); //does not permit, as expected

        //try to remove all access of account 1 tokens from account 2
        await aryContract.connect(account1).setApprovalForAll(account2, false);
        //then, try to add owner as an approved account
        await aryContract.connect(account1).approve(owner, startTkn);

        //then try to transferFrom startTkn from owner to account 2
        await aryContract.transferFrom(account1, account2, startTkn);

        /*end state:
        Account 1:
        - Should not own any tokens
        
        Account 2:
        - Should own one token
        - Should not have any approvals

        Owner:
        - Should not own any tokens
        - Should not have any approvals
        */

        const allAcc1Tokens = await aryContract.getOwning(account1);
        const tokensOwnedAcc1 = await getTokensOwned(allAcc1Tokens);
        expect(tokensOwnedAcc1.length).to.equal(0);

        const allAcc2Tokens = await aryContract.getOwning(account2);
        const tokensOwnedAcc2 = await getTokensOwned(allAcc2Tokens);
        expect(tokensOwnedAcc2.length).to.equal(1);

        const allOwnerTokens = await aryContract.getOwning(owner);
        const tokensOwnedOwner = await getTokensOwned(allOwnerTokens);
        expect(tokensOwnedOwner.length).to.equal(0);

        expect(await aryContract.getApproved(startTkn)).to.equal("0x0000000000000000000000000000000000000000");
        
    });

    function getTokensOwned(tokenArr) {
        const tokens =[];
        for (let i = 0; i < tokenArr.length; i++){
            if (tokenArr[i] != 0) {
                tokens.push(tokenArr[i]);
            }
        }

        return tokens;
    }

});