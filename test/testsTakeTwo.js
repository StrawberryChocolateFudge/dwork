const { expect } = require("chai");
const { ethers } = require("hardhat");
const { setUpJobTests } = require("./setup");

describe("Job tests", async function () {
  it("assigning workers to job", async function () {
    const { workspace, clientJobs, worker, client, worker2 } =
      await setUpJobTests();
    //I add a worker to the first job
    expect(workspace.addWorker(clientJobs[0], worker.address)).to.emit(
      workspace,
      "AddedWorker"
    );
    const addresses = await workspace.getAddresses();
    //From this bellow, I know the worker address has been added
    expect(addresses[0][0]).to.equal(worker.address);

    // now I get the Job contract and check if it is created
    let jobaddress = await workspace.clientjobs(client.address);
    const job = await ethers.getContractAt("Job", jobaddress[0], client);
    const currentWorkerAddress = await job.getWorker();
    expect(currentWorkerAddress).to.equal(worker.address);
    const CLIENT_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("CLIENT_ROLE")
    );
    //Test if disabled client can create job
    expect(workspace.moderateTarget(client.address, CLIENT_ROLE, true))
      .to.emit(workspace, "Moderated")
      .withArgs(client.address, CLIENT_ROLE, true);

    expect(
      workspace.connect(client).addWorker(clientJobs[0], worker2.address)
    ).to.be.revertedWith("Disabled client cannot add worker");
    //I remove the disabling
    expect(workspace.moderateTarget(client.address, CLIENT_ROLE, false))
      .to.emit(workspace, "Moderated")
      .withArgs(client.address, CLIENT_ROLE, false);
    //and i can add worker again
    expect(workspace.connect(client).addWorker(clientJobs[0], worker2.address))
      .to.emit(workspace, "AddedWorker")
      .withArgs(clientJobs[0], worker2.address);
  });

  it("create and manage the assignment,withdraw funds", async function () {
    const {
      workspace,
      worker,
      client,
      owner: manager,
      clientJobs,
      worker2,
    } = await setUpJobTests();
    expect(clientJobs.length).to.equal(1);
    const jobaddress = await workspace.clientjobs(client.address);
    const job = await ethers.getContractAt("Job", jobaddress[0], client);
    // assignment is created with true so the worker can begin work instantly
    expect(job.connect(client).addAssignment(true))
      .emit(job, "AssignmentAdded")
      .withArgs(true);

    // I test the job metadata
    const meta = "new metadata";
    expect(job.connect(client).setmetadataUrl(meta))
      .to.emit(job, "MetadataUrlChange")
      .withArgs(meta);
    expect(await job.connect(client).getMetadataUrl()).to.equal(meta);

    // I add a worker
    expect(workspace.addWorker(job.address, worker.address))
      .to.emit(workspace, "AddedWorker")
      .withArgs(job.address, worker.address);
    /// the worker starst work, cannot call other functions before
    expect(job.connect(worker).markDone()).to.be.reverted;
    expect(await job.connect(worker).whoAmI()).to.equal("worker");
    //enough ether must be deposited for the job to start

    expect(job.connect(worker).startWork()).to.be.revertedWith(
      "Minimum balance is 1 ether"
    );

    const tx = {
      to: job.address,
      value: ethers.utils.parseEther("1"),
    };

    expect(await client.sendTransaction(tx)).to.changeEtherBalance(
      client,
      ethers.utils.parseEther("-1")
    );
    expect(await job.getbalance()).to.be.equal(ethers.utils.parseEther("1"));
    expect(await job.getTotalBalance()).to.be.equal(
      ethers.utils.parseEther("1")
    );
    expect(job.connect(client).markAccepted()).to.be.reverted;

    //After 1 ether is deposited, the worker can start work
    expect(job.connect(worker).startWork()).to.emit(job, "WorkStarted");

    //testing a require
    expect(workspace.addWorker(job.address, worker.address)).to.be.revertedWith(
      "Cannot assign new worker if work has started"
    );

    //The job can be only accepted after its marked done
    expect(job.connect(client).markAccepted()).to.be.reverted;
    expect(job.connect(worker).markDone()).to.emit(job, "WorkDone");

    // lets just mark it accepted now
    expect(job.connect(client).markAccepted()).to.emit(
      job,
      "AssignmentAccepted"
    );
    // the withdraws can begin now
    // I expect 1% goes to the dividends,20% goes to the manager
    // and 79% is for the worker, fees got set in setup

    expect(job.connect(worker).withdraw())
      .to.emit(job, "Withdraw")
      .withArgs(
        1,
        ethers.utils.parseEther("0.79"),
        ethers.utils.parseEther("0.2"),
        ethers.utils.parseEther("0.01")
      );

    //Reverts with insufficient balance
    expect(job.connect(worker).withdraw()).to.be.reverted;
    //I got too many expects in a block, so I repeat in further tests
  });

  it("create an asssignment with false and add a new worker", async () => {
    const {
      workspace,
      worker,
      client,
      owner: manager,
      clientJobs,
      worker2,
    } = await setUpJobTests();
    const jobaddress = await workspace.clientjobs(client.address);
    const job = await ethers.getContractAt("Job", jobaddress[0], client);
    // assignment is created with true so the worker can begin work instantly
    await job.connect(client).addAssignment(false);
    workspace.addWorker(job.address, worker.address);
    const tx = {
      to: job.address,
      value: ethers.utils.parseEther("1"),
    };
    await client.sendTransaction(tx);
    expect(job.connect(client).markReady());

    await job.connect(worker).startWork();
    expect(job.connect(worker).markDone()).to.emit(job, "WorkDone");
    expect(job.connect(client).markAccepted()).to.emit(
      job,
      "AssignmentAccepted"
    );
    // the withdraws can begin now
    // I expect 1% goes to the dividends,20% goes to the manager
    // and 79% is for the worker, fees got set in setup

    expect(job.connect(worker).withdraw())
      .to.emit(job, "Withdraw")
      .withArgs(
        1,
        ethers.utils.parseEther("0.79"),
        ethers.utils.parseEther("0.2"),
        ethers.utils.parseEther("0.01")
      );
    expect(job.connect(client).addAssignment(false))
      .to.emit(job, "AssignmentAdded")
      .withArgs(false);

    expect(workspace.connect(client).addWorker(job.address, worker2.address))
      .to.emit(workspace, "AddedWorker")
      .withArgs(job.address, worker2.address);
    await client.sendTransaction(tx);
    
    //TESTING THE ROLE REVOKING IN AddWorker() HERE
    expect(job.connect(worker).startWork()).to.be.reverted;
    
    
  });

  // it("assignment with disputes", async function () {
  //   throw "err";
  // });

  it("Job deprecation checking", async function () {
    const {
      workspace,
      clientJobs,
      worker,
      client,
      workspacefactory,
      factoryBoss,
    } = await setUpJobTests();
    let jobaddress = await workspace.clientjobs(client.address);
    const job = await ethers.getContractAt("Job", jobaddress[0], client);
    const jobLibVersion = await workspacefactory.getCurrentJobLibraryVersion();
    const jobInstanceVersion = await job.getVersion();
    expect(jobLibVersion).to.equal(jobInstanceVersion);

    //I can get the versions like above
    // and to trigger deprecation warning, I just set the lib address to something
    await workspacefactory
      .connect(factoryBoss)
      .setJobLibraryAddress(worker.address);
    const jobLibVersionAgain =
      await workspacefactory.getCurrentJobLibraryVersion();
    const jobInstanceVersionAgain = await job.getVersion();
    //IF they are not equal, a new job version became available
    expect(jobLibVersionAgain).to.not.equal(jobInstanceVersionAgain);
  });
});
