const { expect } = require("chai");
const { ethers } = require("hardhat");
const { tokenSetup } = require("./setup");
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
  });

  it("dividends tests", async function () {
    throw "err";
  });
});
