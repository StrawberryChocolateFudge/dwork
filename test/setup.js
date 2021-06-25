const { ethers, waffle } = require("hardhat");
const { expect } = require("chai");

async function setUp() {
  const [owner, client, worker, worker2, factoryBoss] =
    await ethers.getSigners();
  const DWorkToken = await ethers.getContractFactory("DWorkToken");
  const dWorkToken = await DWorkToken.deploy(
    owner.address,
    ethers.utils.parseEther("30000000")
  );
  const dworktoken = await dWorkToken.deployed();
  const DividendsLib = await ethers.getContractFactory("DividendsLib");
  const dividendsLib = await DividendsLib.deploy();
  const dividendslib = await dividendsLib.deployed();

  const Dividends = await ethers.getContractFactory("Dividends", {
    libraries: { DividendsLib: dividendslib.address },
  });
  const dividends_dep = await Dividends.deploy(dworktoken.address, 100);
  const dividends = await dividends_dep.deployed();

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
    worker2,
    dividends,
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
    worker2,
    dividends,
  } = await setUp();
  await addLibrariesAndWorkspace(
    workspacefactory,
    workspacemaster,
    jobmaster,
    factoryBoss,
    dividends
  );
  //I set the fee to 1% here
  workspacefactory.connect(factoryBoss).setContractFee(100);
  //I add the dividends library address now
  await workspacefactory
    .connect(factoryBoss)
    .setDividendsLibraryAddress(dividends.address);

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
  // 20% fee
  await workspace.setFee(2000);
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

  return {
    workspace,
    clientJobs,
    worker,
    client,
    owner,
    factoryBoss,
    workspacefactory,
    worker2,
  };
}

async function tokenSetup() {
  const [owner, holder1, holder2, holder3] = await ethers.getSigners();
  //30 million tokens are minted, and sold at a rate of 2

  const DWorkToken = await ethers.getContractFactory("DWorkToken");
  const dWorkToken = await DWorkToken.deploy(
    owner.address,
    ethers.utils.parseEther("30000000")
  );
  const dworktoken = await dWorkToken.deployed();
  let dworkcrowdsale;
  await dWorkToken.deployed().then(async (dworktoken) => {
    const DWorkCrowdSale = await ethers.getContractFactory("DWorkCrowdSale");
    await DWorkCrowdSale.deploy(
      10,
      owner.address,
      dworktoken.address,
      owner.address
    ).then(async (dWorkcrowdSale) => {
      dworkcrowdsale = await dWorkcrowdSale.deployed();
    });
  });

  return { dworktoken, dworkcrowdsale, holder1, holder2, holder3, owner };
}

async function dividendsSetup() {
  const { dworktoken, dworkcrowdsale, holder1, holder2, holder3, owner } =
    await tokenSetup();
  const DividendsLib = await ethers.getContractFactory("DividendsLib");
  const dividendsLib = await DividendsLib.deploy();
  const dividendslib = await dividendsLib.deployed();

  const Dividends = await ethers.getContractFactory("Dividends", {
    libraries: { DividendsLib: dividendslib.address },
  });
  //Lets make the cycle now 100 for easy testablility
  const dividends_dep = await Dividends.deploy(dworktoken.address, 100);
  const dividends = await dividends_dep.deployed();

  return { dworktoken, holder1, holder2, holder3, owner, dividends };
}

async function expectRevert(async_callback, errString) {
  let throws = false;
  let err = "";
  try {
    await async_callback();
  } catch (e) {
    throws = true;
    err = e.message;
  }
  return {
    throws,
    correct: err.includes(
      `VM Exception while processing transaction: reverted with reason string '${errString}'`
    ),
  };
}

module.exports = {
  setUp,
  addLibrariesAndWorkspace,
  setUpJobTests,
  tokenSetup,
  dividendsSetup,
  expectRevert,
};
