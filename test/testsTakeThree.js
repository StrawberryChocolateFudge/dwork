const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { tokenSetup, dividendsSetup, expectRevert } = require("./setup");
const { utils } = ethers;
const { parseEther } = utils;
describe("dwork", async function () {
  it("Crowdsale ", async function () {
    const { dworkcrowdsale, dworktoken, holder1, holder2, owner } =
      await tokenSetup();

    expect(await dworktoken.balanceOf(owner.address)).to.be.equal(
      parseEther("30000000")
    );
    expect(await dworktoken.balanceOf(dworkcrowdsale.address)).to.be.equal(
      parseEther("0")
    );

    //The crowdsale doesnt' work without balance
    expect(
      holder1.sendTransaction({
        to: dworkcrowdsale.address,
        value: ethers.utils.parseEther("1"),
      })
    ).to.reverted;

    // I send 20 million tokens to the crowdsale
    await expect(() =>
      dworktoken.transfer(dworkcrowdsale.address, parseEther("20000000"))
    ).to.changeTokenBalance(dworktoken, dworkcrowdsale, parseEther("20000000"));

    // Confirm the tokens were received
    expect(await dworktoken.balanceOf(dworkcrowdsale.address)).to.be.equal(
      parseEther("20000000")
    );

    // I buy, this time it succeeds
    expect(
      await holder1.sendTransaction({
        to: dworkcrowdsale.address,
        value: parseEther("1"),
      })
    )
      .to.emit(dworkcrowdsale, "TokensPurchased")
      .withArgs(
        holder1.address,
        holder1.address,
        parseEther("1"),
        parseEther("10")
      );

    expect(
      utils.formatEther(await dworktoken.balanceOf(holder1.address))
    ).to.equal("10.0");

    // let's test admin transfer too
    await expect(() =>
      dworkcrowdsale.adminTransfer(parseEther("1"), holder2.address)
    ).to.changeTokenBalance(dworktoken, holder2, parseEther("1"));

    expect(await dworktoken.balanceOf(holder2.address)).to.be.equal(
      parseEther("1")
    );

    //Now owner will burn the tokens
    expect(await dworktoken.totalSupply()).to.equal(parseEther("30000000"));

    await expect(() =>
      dworktoken.connect(owner).burn(parseEther("2000000"))
    ).to.changeTokenBalance(dworktoken, owner, parseEther("-2000000"));

    expect(await dworktoken.balanceOf(owner.address)).to.be.equal(
      parseEther("8000000")
    );

    expect(await dworktoken.totalSupply()).to.equal(parseEther("28000000"));
  });

  it("dividends with a withdraw", async function () {
    const { dworktoken, holder1, holder2, holder3, owner, dividends } =
      await dividendsSetup();
    // I will send some tokens to holder addresses first
    expect(await dworktoken.balanceOf(owner.address)).to.equal(
      parseEther("30000000")
    );
    await expect(() =>
      dworktoken.transfer(holder1.address, parseEther("100"))
    ).to.changeTokenBalance(dworktoken, holder1, parseEther("100"));

    //I send ether to the dividends contract manually now so I dont have to go over the jobs again
    await expect(
      await owner.sendTransaction({
        to: dividends.address,
        value: parseEther("1000"),
      })
    )
      .to.emit(dividends, "Received")
      .withArgs(owner.address, parseEther("1000"));

    //Holder1 can claim some dividends

    //IMPORTANT!! The holder must grant allowence to the dividends contract first
    expect(
      dworktoken
        .connect(holder1)
        .increaseAllowance(dividends.address, parseEther("10"))
    ).to.emit(dworktoken, "Approval");

    await expect(dividends.connect(holder1).claimDividends(parseEther("10")))
      .to.emit(dividends, "Claim")
      .withArgs(holder1.address, parseEther("0.000333"), parseEther("10"));
    //And this transfered 0.000333 to the holder1 address
    expect(await dividends.getTotalBalance()).to.equal(parseEther("1000"));
    // the amount left in the contract is:
    expect(await dividends.getCurrentBalance()).to.equal(
      parseEther("999.999667")
    );
    expect(await dividends.getManagedTokens()).to.equal(parseEther("10"));

    //For 10 more token the next payout, which is pretty close to the previous but litte less
    expect(
      utils.formatEther(await dividends.calculateDividends(parseEther("10")))
    ).to.equal("0.000332999889111");

    // I get the index for the holder1 user
    expect(await dividends.connect(holder1).getCurrentIndex()).to.equal(1);
    let history = await dividends.connect(holder1).getHistory(1);
    expect(history.initialized).to.be.true;
    expect(history.balance).to.be.equal(parseEther("10"));

    // I expect all withdraw to fail at this point
    //I cannot expect this because FU
    await expect(
      dividends.connect(holder1).withdrawToken(1)
    ).to.be.revertedWith("The balance is still locked");

    await mineBlocks(100).then(async () => {
      //After a hundred blocks, the withdraw should work
      //Its gonna be 1 million blocks in the live scenario
      await expect(dividends.connect(holder1).withdrawToken(1))
        .to.emit(dividends, "TokenWithdraw")
        .withArgs(holder1.address, parseEther("10"), 1);
    });
    history = await dividends.connect(holder1).getHistory(1);
    expect(history.balance).to.be.equal(parseEther("10"));
    expect(history.state).to.equal(2);

    history = await dividends.connect(holder1).getHistory(2);
    expect(history.initialized).to.be.false;
  });

  it("dividends with reinvest", async function () {
    const { dworktoken, holder1, holder2, holder3, owner, dividends } =
      await dividendsSetup();

    await expect(() =>
      dworktoken.transfer(holder1.address, parseEther("100"))
    ).to.changeTokenBalance(dworktoken, holder1, parseEther("100"));

    await expect(
      await owner.sendTransaction({
        to: dividends.address,
        value: parseEther("1000"),
      })
    )
      .to.emit(dividends, "Received")
      .withArgs(owner.address, parseEther("1000"));

    await expect(
      dworktoken
        .connect(holder1)
        .increaseAllowance(dividends.address, parseEther("10"))
    ).to.emit(dworktoken, "Approval");

    await expect(dividends.connect(holder1).claimDividends(parseEther("10")))
      .to.emit(dividends, "Claim")
      .withArgs(holder1.address, parseEther("0.000333"), parseEther("10"));

    let { throws, correct } = await expectRevert(() =>
      dividends.connect(holder1).reclaimDividends(1),
      "The balance is still locked"
    );
    expect(throws).to.be.true
    expect(correct).to.equal(true);

    //TODO: THIS BELLOW IS NOT THROWING!! WTF!
    await expect(
      dividends.connect(holder1).reclaimDividends(1)
    ).to.be.revertedWith("The balance is still locked");

    await mineBlocks(100).then(async () => {
      //After a hundred blocks, the reclaim should work
      //Its gonna be 1 million blocks in the live scenario
      await expect(dividends.connect(holder1).reclaimDividends(1))
        .to.emit(dividends, "Reclaim")
        .withArgs(
          holder1.address,
          parseEther("0.0003329998891110"),
          parseEther("10")
        );
    });

    let history = await dividends.connect(holder1).getHistory(1);
    expect(history.balance).to.be.equal(parseEther("10"));
    expect(history.state).to.equal(1);

    history = await dividends.connect(holder1).getHistory(2);
    expect(history.balance).to.be.equal(parseEther("10"));
    expect(history.state).to.equal(0);
  });
});

async function mineBlocks(blockNumber) {
  console.log(`⛏️️`);
  while (blockNumber > 0) {
    blockNumber--;
    await network.provider.request({
      method: "evm_mine",
      params: [],
    });
  }
}
