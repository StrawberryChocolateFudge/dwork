const { stripZeros } = require("@ethersproject/bytes");
const { expect } = require("chai");
const { ethers } = require("hardhat");

async function setUp() {
  const WorkSpaceFactoryLib = await ethers.getContractFactory(
    "WorkSpaceFactoryLib"
  );
  const workSpacefactioryLib = await WorkSpaceFactoryLib.deploy();
  const workspacefactorylib = await workSpacefactioryLib.deployed();
  const WorkSpaceLib = await ethers.getContractFactory("WorkSpaceLib");
  const workSpaceLib = await WorkSpaceLib.deploy();
  const workspacelib = await workSpaceLib.deployed();
  const JobLib = await ethers.getContractFactory("JobLib");
  const jobLib = await JobLib.deploy();
  const joblib = await jobLib.deployed();

  const WorkSpaceFactory = await ethers.getContractFactory("WorkSpaceFactory", {
    libraries: { WorkSpaceFactoryLib: workspacefactorylib.address },
  });
  const workSpaceFactory = await WorkSpaceFactory.deploy(
    "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0"
  );
  const workspacefactory = await workSpaceFactory.deployed();

  const WorkSpace = await ethers.getContractFactory("WorkSpace", {
    libraries: { WorkSpaceLib: workspacelib.address },
  });
  const workSpace = await WorkSpace.deploy();
  const workspace = await workSpace.deployed();

  const Job = await ethers.getContractFactory("Job", {
    libraries: { JobLib: joblib.address },
  });
  const jobdeploy = await Job.deploy();
  const job = await jobdeploy.deployed();

  const DLink = await ethers.getContractFactory("DLink");
  const dLink = await DLink.deploy();
  const dlink = await dLink.deployed();
  const [owner] = await ethers.getSigners();

  return {
    workspacefactory,
    workspacemaster: workspace,
    jobmaster: job,
    dlink,
    owner,
  };
}

async function addLibrariesAndWorkspace(workspacefactory, workspace, job) {
  await workspacefactory.setWorkSpaceLibrary(workspace.address);
  await workspacefactory.setJobLibraryAddress(job.address);
  await workspacefactory.createWorkSpace(1, "This is the metadata");
}

describe("contract tests", async function () {
  it("Tests hacking the master contracts", async function () {
    const { workspacemaster, workspacefactory, jobmaster } = await setUp();

    let failed = false;
    try {
      await workspacemaster.initialize(
        0,
        "",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        jobmaster.address
      );
    } catch (error) {
      failed = true;
    }

    expect(failed).to.be.true;

    let jobInitFailed = false;

    try {
      await jobmaster.initialize(
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0"
      );
    } catch (error) {
      jobInitFailed = true;
    }
    expect(jobInitFailed).to.be.true;
  });

  it("test create workspace", async function () {
    const { workspacefactory, workspacemaster, jobmaster } = await setUp();
    await workspacefactory.setWorkSpaceLibrary(workspacemaster.address);

    expect(await workspacefactory.getWorkSpaceLibrary()).to.equal(
      workspacemaster.address
    );

    await workspacefactory.setJobLibraryAddress(jobmaster.address);
    expect(await workspacefactory.getJobLibraryAddress()).to.equal(
      jobmaster.address
    );

    const [owner] = await ethers.getSigners();

    let isNew = await workspacefactory.addressIsNew(owner.address);
    expect(isNew).to.be.true;
    await workspacefactory.createWorkSpace(1, "This is the metadata");
    let isNewAgain = await workspacefactory.addressIsNew(owner.address);
    expect(isNewAgain).to.be.false;

    let contractAddress = await workspacefactory.getContractAddress(
      owner.address
    );
    expect(contractAddress).to.be.not.equal(owner.address);
    let amountOfWorkSpaces = await workspacefactory.amountOfWorkSpaces();
    expect(amountOfWorkSpaces).to.be.equal(1);
  });

  it("Test contract fees", async function () {
    const { workspacefactory } = await setUp();
    let initialContractFee = await workspacefactory.getContractFee();
    expect(initialContractFee).to.be.equal(0);

    let ownerAddress = await workspacefactory.getOwner();
    expect(ownerAddress).to.be.equal(
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0"
    );

    let cantsetDisabled = false;
    try {
      await workspacefactory.setDisabled(true);
    } catch (error) {
      cantsetDisabled = true;
    }
    expect(cantsetDisabled).to.be.true;

    let cantsetContractFee = false;
    try {
      await workspacefactory.setContractFee(1);
    } catch (error) {
      cantsetContractFee = true;
    }
    expect(cantsetContractFee).to.be.true;
  });

  it("Test workspace metadata", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner } =
      await setUp();
    await addLibrariesAndWorkspace(
      workspacefactory,
      workspacemaster,
      jobmaster
    );
    let workspaceaddress = workspacefactory.getContractAddress(owner.address);
    const workspace = await ethers.getContractAt(
      "WorkSpace",
      workspaceaddress,
      owner
    );

    let metadata = await workspace.metadataUrl();
    expect(metadata).to.equal("This is the metadata");

    let newMetadata = "Bruh, whatever";
    await workspace.setMetadata(newMetadata);
    expect(await workspace.metadataUrl()).to.equal(newMetadata);
  });

  it("Test disabling registration", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner } =
      await setUp();
    await addLibrariesAndWorkspace(
      workspacefactory,
      workspacemaster,
      jobmaster
    );
    let workspaceaddress = workspacefactory.getContractAddress(owner.address);
    const workspace = await ethers.getContractAt(
      "WorkSpace",
      workspaceaddress,
      owner
    );

    expect(await workspace.getRegistrationOpen()).to.be.false;

    await workspace.setRegistrationOpen(true);

    expect(await workspace.getRegistrationOpen()).to.be.true;
  });

  it("test written contracts", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner } =
      await setUp();
    await addLibrariesAndWorkspace(
      workspacefactory,
      workspacemaster,
      jobmaster
    );
    let workspaceaddress = await workspacefactory.getContractAddress(
      owner.address
    );
    const workspace = await ethers.getContractAt(
      "WorkSpace",
      workspaceaddress,
      owner
    );

    let contractHash1 = await ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("the hash of the actual contract")
    );
    let contractHash2 = await ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("the hash of the second contract")
    );

    await workspace.addWrittenContract(
      contractHash1,
      "Some url pointing to ipfs"
    );
    await workspace.addWrittenContract(contractHash2, "Second url");

    await workspace.setCurrentClientContractHash(contractHash1);
    await workspace.setCurrentWorkerContractHash(contractHash2);

    let currentWorkerContractHash = await workspace.currentWorkerContractHash();
    let currentClientContractHash = await workspace.currentClientContractHash();
    expect(currentWorkerContractHash).to.equal(contractHash2);
    expect(currentClientContractHash).to.equal(contractHash1);
  });

  it("test roles and registration", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner } =
      await setUp();
    await addLibrariesAndWorkspace(
      workspacefactory,
      workspacemaster,
      jobmaster
    );
    let workspaceaddress = await workspacefactory.getContractAddress(
      owner.address
    );
    const workspace = await ethers.getContractAt(
      "WorkSpace",
      workspaceaddress,
      owner
    );
    await workspace.setRegistrationOpen(true);

    let myRole = await workspace.whoAmI();
    expect(myRole).to.equal("manager");
    let mockContractHash = await ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("test hash")
    );

    expect(await workspace.requireInvite()).to.be.true;

    // Registering as a client or worker should fail since invite is required but none is set
    // The manager signes up external accounts here
    let clientRegisterFailed = false;
    try {
      await workspace.registerClient(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "",
        mockContractHash
      );
    } catch (error) {
      clientRegisterFailed = true;
    }
    expect(clientRegisterFailed).to.be.true;

    let workerRegisterFailed = false;
    try {
      await workspace.registerWorker(
        "metaddataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "",
        mockContractHash
      );
    } catch (error) {
      workerRegisterFailed = true;
    }
    expect(workerRegisterFailed).to.be.true;

    // Now I set the token hash so I can register with an address

    await workspace.addInviteToken("Hazx123sZ");

    await workspace.registerClient(
      "metadataurl",
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
      "Hazx123sZ",
      mockContractHash
    );

    let client = await workspace.clients(
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0"
    );

    expect(client.initialized).to.be.true;

    // The client cannot register as a worker and vice versa

    let workerRegisterFailed2 = false;
    try {
      await workspace.registerWorker(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "Hazx123sZ",
        mockContractHash
      );
    } catch (error) {
      workerRegisterFailed2 = true;
    }
    expect(workerRegisterFailed2).to.be.true;

    //Client tries to register twice
    let clientCantRegisterTwice = false;
    try {
      await workspace.registerClient(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "Hazx123sZ",
        mockContractHash
      );
    } catch (error) {
      clientCantRegisterTwice = true;
    }
    expect(clientCantRegisterTwice).to.be.true;

    //Turn of invites

    await workspace.noInvites();

    // registering client again, without invite code and new address

    let workerRegisterFailedAgain = false;
    try {
      await workspace.registerWorker(
        "metaurl",
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        "",
        mockContractHash
      );
    } catch (error) {
      workerRegisterFailedAgain = true;
    }
    expect(workerRegisterFailedAgain).to.be.false;
    // I try to register twice
    let workerRegisterFailedAgain2 = false;
    try {
      await workspace.registerWorker(
        "metaurl",
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        "",
        mockContractHash
      );
    } catch (error) {
      workerRegisterFailedAgain2 = true;
    }
    expect(workerRegisterFailedAgain2).to.be.true;
  });


  
});
