const { ethers,waffle } = require("hardhat");
const { expect } = require("chai");


async function setUp() {
  const [owner, client, worker,worker2, factoryBoss] = await ethers.getSigners();
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

  const FactoryContractVerifier = await ethers.getContractFactory(
    "FactoryContractVerifier",
    {
      libraries: { WorkSpaceFactoryLib: workspacefactorylib.address },
    }
  );
  const factoryContractVerifier = await FactoryContractVerifier.deploy();
  const factorycontractverifier = await factoryContractVerifier.deployed();
  const WorkSpaceFactory = await ethers.getContractFactory("WorkSpaceFactory", {
    libraries: { WorkSpaceFactoryLib: workspacefactorylib.address },
  });
  const workSpaceFactory = await WorkSpaceFactory.deploy(factoryBoss.address);
  const workspacefactory = await workSpaceFactory.deployed();

  const WorkSpace = await ethers.getContractFactory("WorkSpace", {
    libraries: {
      WorkSpaceLib: workspacelib.address,
      FactoryContractVerifier: factorycontractverifier.address,
    },
  });
  const workSpace = await WorkSpace.deploy();
  const workspace = await workSpace.deployed();

  const Job = await ethers.getContractFactory("Job", {
    libraries: {
      JobLib: joblib.address,
      FactoryContractVerifier: factorycontractverifier.address,
    },
  });
  const jobdeploy = await Job.deploy();
  const job = await jobdeploy.deployed();

  const DLink = await ethers.getContractFactory("DLink");
  const dLink = await DLink.deploy();
  const dlink = await dLink.deployed();

  return {
    workspacefactory,
    workspacemaster: workspace,
    jobmaster: job,
    dlink,
    owner,
    client,
    worker,
    factoryBoss,
    worker2
  };
}

async function addLibrariesAndWorkspace(
  workspacefactory,
  workspace,
  job,
  factoryBoss
) {
  await workspacefactory
    .connect(factoryBoss)
    .setWorkSpaceLibrary(workspace.address)
    .then(async () => {
      await workspacefactory
        .connect(factoryBoss)
        .setJobLibraryAddress(job.address)
        .then(async () => {
          // I createa  workspace here for convenience
          await workspacefactory.createWorkSpace(1, "This is the metadata");
        });
    });
}

async function setUpJobTests() {
  const {
    workspacefactory,
    workspacemaster,
    jobmaster,
    owner,
    client,
    factoryBoss,
    worker,
    worker2
  } = await setUp();
  await addLibrariesAndWorkspace(
    workspacefactory,
    workspacemaster,
    jobmaster,
    factoryBoss
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

  let mockContractHash = await ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("test hash")
  );
  await workspace.noInvites();
  // The manager signs up the client here
  await workspace.registerClient(
    "metadataurl",
    client.address,
    "",
    mockContractHash
  );
  await workspace.registerWorker(
    "metaurl",
    worker.address,
    "",
    mockContractHash
  );
  workspace.connect(client).createJob("This is the metadata");
  const clientJobs = await workspace.clientjobs(client.address);


  return { workspace,clientJobs,worker,client,owner,factoryBoss,workspacefactory,worker2 };
}

module.exports = { setUp, addLibrariesAndWorkspace, setUpJobTests };
