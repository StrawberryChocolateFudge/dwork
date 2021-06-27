const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { tokenSetup, dividendsSetup, expectRevert, setUp } = require("./setup");
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

    let { throws, correct } = await expectRevert(
      () => dividends.connect(holder1).reclaimDividends(1),
      "The balance is still locked"
    );
    expect(throws).to.be.true;
    expect(correct).to.equal(true);

    //THIS BELLOW WAS WORKING WEIRD
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

    //Im gonna test the withdraw difference function here
    //I confirm the balance is 10

    expect(await dworktoken.balanceOf(dividends.address)).to.be.equal(
      parseEther("10")
    );

    // I send some extra tokens to the contract by "accident";

    await expect(() =>
      dworktoken.transfer(dividends.address, parseEther("1"))
    ).to.changeTokenBalance(dworktoken, dividends, parseEther("1"));

    expect(await dividends.getManagedTokens()).to.equal(parseEther("10"));

    // the owner can reclaim the balance to an address

    await expect(() =>
      dividends.withdrawDifference(holder2.address)
    ).to.changeTokenBalance(dworktoken, holder2, parseEther("1"));
  });

  it("The Board, Fee change and maintainer elect/revoke", async () => {
    const {
      board,
      workspacefactory,
      dividends,
      holder1,
      holder2,
      holder3,
      holder4,
      holder5,
      holder6,
      maintainer,
      owner,
      dworktoken,
    } = await setUp();
    // first thing I need to do is transfer ownership of the factory and dividends to the board
    //Im using less waffle here as it seem buggy sometimes
    await workspacefactory.transferOwnership(board.address);
    expect(await workspacefactory.owner()).to.equal(board.address);
    await dividends.transferOwnership(board.address);
    expect(await dividends.owner()).to.equal(board.address);

    //Now I transfer around dwork token to have shareholders
    expect(await dworktoken.balanceOf(owner.address)).to.be.equal(
      parseEther("30000000")
    );

    await dworktoken.transfer(holder1.address, parseEther("10000"));
    await dworktoken.transfer(holder2.address, parseEther("100"));
    await dworktoken.transfer(holder3.address, parseEther("10"));
    await dworktoken.transfer(holder4.address, parseEther("10000"));
    await dworktoken.transfer(holder5.address, parseEther("10000"));
    await dworktoken.transfer(holder6.address, parseEther("10000"));

    (await dworktoken.transfer) *
      expect(await dworktoken.balanceOf(holder1.address)).to.equal(
        parseEther("10000")
      );
    expect(await dworktoken.balanceOf(holder2.address)).to.equal(
      parseEther("100")
    );
    //the owner is the first maintainer
    expect(await board.isMaintainer(owner.address)).to.be.true;

    //I try to create a proposal now, topic 2 is fee change
    await expect(
      board
        .connect(holder2)
        .createProposal(
          "this is the metadata",
          2,
          0,
          564,
          "0x0000000000000000000000000000000000000000",
          false,
          "0x0000000000000000000000000000000000000000"
        )
    ).to.be.revertedWith("Must have enough shares");
    //THIS IS A FEE CHANGE PROPOSAL
    await expect(
      board
        .connect(holder1)
        .createProposal(
          "this is the metadata",
          2,
          0,
          564,
          "0x0000000000000000000000000000000000000000",
          false,
          "0x0000000000000000000000000000000000000000"
        )
    )
      .to.emit(board, "ProposalCreated")
      .withArgs(holder1.address, "this is the metadata", 2, 0);

    expect(await board.getLastProposalIndex()).to.equal(1);

    //THIS IS A ELECT MAINTAINER PROPOSAL
    await expect(
      board
        .connect(holder4)
        .createProposal(
          "meta for elect",
          3,
          0,
          0,
          maintainer.address,
          false,
          "0x0000000000000000000000000000000000000000"
        )
    )
      .to.emit(board, "ProposalCreated")
      .withArgs(holder4.address, "meta for elect", 3, 0);

    expect(await board.getLastProposalIndex()).to.equal(2);
    //THIS IS A REVOKE MAINTAINER PROPOSAL, REMOVING THE OWNER
    await expect(
      board
        .connect(holder5)
        .createProposal(
          "meta for revoke",
          4,
          0,
          0,
          owner.address,
          false,
          "0x0000000000000000000000000000000000000000"
        )
    )
      .to.emit(board, "ProposalCreated")
      .withArgs(holder5.address, "meta for revoke", 4, 0);

    expect(await board.getLastProposalIndex()).to.equal(3);

    //I will use this to revoke a previously added maintainer
    await expect(
      board
        .connect(holder6)
        .createProposal(
          "meta for revoke maintainer",
          4,
          0,
          0,
          maintainer.address,
          false,
          "0x0000000000000000000000000000000000000000"
        )
    )
      .to.emit(board, "ProposalCreated")
      .withArgs(holder6.address, "meta for revoke maintainer", 4, 0);
    expect(await board.getLastProposalIndex()).to.equal(4);

    // // I need to  have a fee change that succeeds
    await expect(
      board.createProposal(
        "this is the metadata",
        2,
        0,
        230,
        "0x0000000000000000000000000000000000000000",
        false,
        "0x0000000000000000000000000000000000000000"
      )
    )
      .to.emit(board, "ProposalCreated")
      .withArgs(owner.address, "this is the metadata", 2, 0);
    expect(await board.getLastProposalIndex()).to.equal(5);

    // NOW I WILL VOTE ON THE PROPOSALS

    await expect(board.connect(holder1).vote(1, true)).to.be.reverted;
    await expect(board.connect(holder2).vote(1, true))
      .to.emit(board, "Vote")
      .withArgs(holder2.address, 1, true, parseEther("100"));

    await expect(board.connect(holder3).vote(1, true))
      .to.emit(board, "Vote")
      .withArgs(holder3.address, 1, true, parseEther("10"));

    await expect(board.vote(1, false))
      .to.emit(board, "Vote")
      .withArgs(
        owner.address,
        1,
        false,
        await dworktoken.balanceOf(owner.address)
      );

    // I can check the scores now before the voting is closed
    let votes = await board.getVotes(1);
    expect(utils.formatEther(votes[0])).to.be.equal("110.0");
    expect(utils.formatEther(votes[1])).to.be.equal("29959890.0");
    //As you can see the owners vote is worth a lot because of his token balance
    await expect(board.closeVoting(1)).to.be.revertedWith(
      "The proposal didnt expire,yet"
    );

    //Let's vote on other subjects too before I mine blocks
    await expect(board.connect(holder1).vote(2, true)).to.emit(board, "Vote");
    await expect(board.connect(holder2).vote(2, true)).to.emit(board, "Vote");
    await expect(board.connect(holder3).vote(2, true)).to.emit(board, "Vote");
    await expect(board.connect(maintainer).vote(2, false)).to.emit(
      board,
      "Vote"
    );
    //I have 3 votes with it and 1 vote against it

    //The last proposal wants to revoke the maintainer right from the owner
    await expect(board.connect(holder3).vote(3, false)).to.emit(board, "Vote");
    await expect(board.connect(holder2).vote(3, false)).to.emit(board, "Vote");
    //Only gets 2 votes

    //This is for a succesful maintaner role revoking
    await expect(board.connect(holder3).vote(4, true)).to.emit(board, "Vote");
    await expect(board.connect(holder2).vote(4, true)).to.emit(board, "Vote");
    await expect(board.connect(holder4).vote(4, true)).to.emit(board, "Vote");
    await expect(board.connect(holder5).vote(4, true)).to.emit(board, "Vote");

    //This is for a succesful fee change
    await expect(board.connect(holder3).vote(5, true)).to.emit(board, "Vote");
    await expect(board.connect(holder2).vote(5, true)).to.emit(board, "Vote");
    await expect(board.connect(holder4).vote(5, true)).to.emit(board, "Vote");
    await expect(board.connect(holder5).vote(5, true)).to.emit(board, "Vote");

    //NOW I CAN MINE
    await mineBlocks(120).then(async () => {
      //Anyone can close voting

      //I expect the first proposal fails
      await expect(board.closeVoting(1))
        .to.emit(board, "VotingClosed")
        .withArgs(1, false);
      //the second passes
      await expect(board.closeVoting(2))
        .to.emit(board, "VotingClosed")
        .withArgs(2, true);
      // the third one fails
      await expect(board.closeVoting(3))
        .to.emit(board, "VotingClosed")
        .withArgs(3, false);

      //Now I can fulfill one proposal
      await expect(board.fulfillFeeChangeProposal(1)).to.be.revertedWith(
        "Proposal must be accepted"
      );

      await expect(board.fulfillMaintainerChangeProposal(2))
        .to.emit(board, "ProposalFulfilled")
        .withArgs(2, 3, 0);

      //now the maintainer signer should be one too
      await expect(await board.isMaintainer(maintainer.address)).to.be.true;

      //I close voting four
      await expect(board.closeVoting(4))
        .to.emit(board, "VotingClosed")
        .withArgs(4, true);

      await expect(board.closeVoting(5))
        .to.emit(board, "VotingClosed")
        .withArgs(5, true);

      await expect(board.fulfillMaintainerChangeProposal(4))
        .to.emit(board, "ProposalFulfilled")
        .withArgs(4, 4, 0);

      //Now the maintainer is not a maintainer anymore, no no
      await expect(await board.isMaintainer(maintainer.address)).to.be.false;

      //And this will change the fee of the workspace factory!!
      //I didnt have any set
      expect(await workspacefactory.getContractFee()).to.be.equal(0);
      await expect(board.fulfillFeeChangeProposal(5))
        .to.emit(board, "ProposalFulfilled")
        .withArgs(5, 2, 0);

      expect(await workspacefactory.getContractFee()).to.be.equal(230);
    });
  });

  it("the board,development and maintenance tasks", async () => {
    throw "err";
  });

  // it("retesting all requires", async () => {
  //   throw "error";
  // });
});

async function mineBlocks(blockNumber) {
  console.log(`    ⛏️️`);
  while (blockNumber > 0) {
    blockNumber--;
    await network.provider.request({
      method: "evm_mine",
      params: [],
    });
  }
}
