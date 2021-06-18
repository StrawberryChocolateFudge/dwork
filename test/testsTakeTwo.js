const { expect } = require("chai");
const { ethers } = require("hardhat");
const { setUp, addLibrariesAndWorkspace, setUpJobTests } = require("./setup");

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
  
  it("create and manage the assignment",async function(){
	  
  });

  it("Deprecated Job checking", async function () {
    throw "err";
  });
  it("Sending ether to Job contract", async function () {
    throw "err";
  });
  it("Withdrawing ether from  job contract", async function () {
    throw "err";
  });
});
