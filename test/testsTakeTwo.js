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

  it("create and manage the assignment", async function () {
    throw "err";
  });

  it("Deprecated Job checking", async function () {
    const { workspace, clientJobs, worker, client, workspacefactory,factoryBoss } =
      await setUpJobTests();
    //I add a worker to the first job
    expect(workspace.addWorker(clientJobs[0], worker.address)).to.emit(
      workspace,
      "AddedWorker"
    );

    let jobaddress = await workspace.clientjobs(client.address);
    const job = await ethers.getContractAt("Job", jobaddress[0], client);
    const jobLibVersion = await workspacefactory.getCurrentJobLibraryVersion();
    const jobInstanceVersion = await job.getVersion();
    expect(jobLibVersion).to.equal(jobInstanceVersion);

    //I can get the versions like above
    // and to trigger deprecation warning, I just set the lib address to something
    await workspacefactory.connect(factoryBoss).setJobLibraryAddress(worker.address);
    const jobLibVersionAgain = await workspacefactory.getCurrentJobLibraryVersion();
    const jobInstanceVersionAgain = await job.getVersion();
    //IF they are not equal, a new job version became available
    expect(jobLibVersionAgain).to.not.equal(jobInstanceVersionAgain);
  });
  it("Sending ether to Job contract", async function () {
    throw "err";
  });

  it("withdrawing ether from  job contract", async function () {
    throw "err";
  });
});
