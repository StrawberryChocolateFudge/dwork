const { Wallet } = require("@ethersproject/wallet");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { setUpJobTests } = require("./setup");

describe("Job tests", async function () {
  it("assigning workers to job", async function () {
    const { workspace, clientJobs, worker, client } = await setUpJobTests();
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
  });

  it("create and manage the assignment,withdraw funds", async function () {
    const {
      workspace,
      worker,
      client,
      owner: manager,
      clientJobs,
      worker2
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

    expect(job.connect(worker).startWork()).to.emit(job, "WorkStarted");
    //ether must be deposited for the job to start
    expect(
      await client.sendTransaction({ to: job.address, value: 200 })
    ).to.changeEtherBalance(client, -200);
    expect(await job.getbalance()).to.be.equal(200);
    expect(await job.getTotalBalance()).to.be.equal(200);
    expect(job.connect(client).markAccepted()).to.be.reverted;
    expect(job.connect(worker).markDone()).to.emit(job,"WorkDone");

    // lets just mark it accepted now
    expect(job.connect(client).markAccepted()).to.emit(job,"AssignmentAccepted");
    // the withdraws can begin now
        
    expect(job.connect(worker).workerWithdraw()).to.emit(job,"WorkerWithdraw");

    });

    it("assignment disputes",async function(){throw "err";});

  it("Deprecated Job checking", async function () {
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
