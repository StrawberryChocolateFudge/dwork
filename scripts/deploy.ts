const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  await hre.run("compile");

  const [owner] = await ethers.getSigners();

  // ████████▄   ▄█     █▄   ▄██████▄     ▄████████    ▄█   ▄█▄
  // ███   ▀███ ███     ███ ███    ███   ███    ███   ███ ▄███▀
  // ███    ███ ███     ███ ███    ███   ███    ███   ███▐██▀
  // ███    ███ ███     ███ ███    ███  ▄███▄▄▄▄██▀  ▄█████▀
  // ███    ███ ███     ███ ███    ███ ▀▀███▀▀▀▀▀   ▀▀█████▄
  // ███    ███ ███     ███ ███    ███ ▀███████████   ███▐██▄
  // ███   ▄███ ███ ▄█▄ ███ ███    ███   ███    ███   ███ ▀███▄
  // ████████▀   ▀███▀███▀   ▀██████▀    ███    ███   ███   ▀█▀
  //                                     ███    ███   ▀
  const DWorkToken = await ethers.getContractFactory("DWorkToken");
  const dWorkToken = await DWorkToken.deploy(
    owner.address,
    ethers.utils.parseEther("30000000")
  );
  const dworktoken = await dWorkToken.deployed();

  //  ▄████████    ▄████████  ▄██████▄   ▄█     █▄  ████████▄     ▄████████    ▄████████  ▄█          ▄████████
  // ███    ███   ███    ███ ███    ███ ███     ███ ███   ▀███   ███    ███   ███    ███ ███         ███    ███
  // ███    █▀    ███    ███ ███    ███ ███     ███ ███    ███   ███    █▀    ███    ███ ███         ███    █▀
  // ███         ▄███▄▄▄▄██▀ ███    ███ ███     ███ ███    ███   ███          ███    ███ ███        ▄███▄▄▄
  // ███        ▀▀███▀▀▀▀▀   ███    ███ ███     ███ ███    ███ ▀███████████ ▀███████████ ███       ▀▀███▀▀▀
  // ███    █▄  ▀███████████ ███    ███ ███     ███ ███    ███          ███   ███    ███ ███         ███    █▄
  // ███    ███   ███    ███ ███    ███ ███ ▄█▄ ███ ███   ▄███    ▄█    ███   ███    ███ ███▌    ▄   ███    ███
  // ████████▀    ███    ███  ▀██████▀   ▀███▀███▀  ████████▀   ▄████████▀    ███    █▀  █████▄▄██   ██████████
  //              ███    ███                                                             ▀
  const DWorkCrowdSale = await ethers.getContractFactory("DWorkCrowdSale");
  const crowdsale_deploying = await DWorkCrowdSale.deploy(
    10,
    owner.address,
    dworktoken.address,
    owner.address
  );
  const dworkcrowdsale = await crowdsale_deploying.deployed();
  // ████████▄   ▄█   ▄█    █▄   ▄█  ████████▄     ▄████████ ███▄▄▄▄   ████████▄     ▄████████
  // ███   ▀███ ███  ███    ███ ███  ███   ▀███   ███    ███ ███▀▀▀██▄ ███   ▀███   ███    ███
  // ███    ███ ███▌ ███    ███ ███▌ ███    ███   ███    █▀  ███   ███ ███    ███   ███    █▀
  // ███    ███ ███▌ ███    ███ ███▌ ███    ███  ▄███▄▄▄     ███   ███ ███    ███   ███
  // ███    ███ ███▌ ███    ███ ███▌ ███    ███ ▀▀███▀▀▀     ███   ███ ███    ███ ▀███████████
  // ███    ███ ███  ███    ███ ███  ███    ███   ███    █▄  ███   ███ ███    ███          ███
  // ███   ▄███ ███  ███    ███ ███  ███   ▄███   ███    ███ ███   ███ ███   ▄███    ▄█    ███
  // ████████▀  █▀    ▀██████▀  █▀   ████████▀    ██████████  ▀█   █▀  ████████▀   ▄████████▀

  const DividendsLib = await ethers.getContractFactory("DividendsLib");
  const dividendsLib = await DividendsLib.deploy();
  const dividendslib = await dividendsLib.deployed();
  const Dividends = await ethers.getContractFactory("Dividends", {
    libraries: { DividendsLib: dividendslib.address },
  });
  // The amount of time to wait before the tokens are unlocked.
  // 100 for testing
  const lockTimeInBlocks = 100;
  const dividends_dep = await Dividends.deploy(
    dworktoken.address,
    lockTimeInBlocks
  );
  const dividends = await dividends_dep.deployed();

  //    ▄████████    ▄████████  ▄████████     ███      ▄██████▄     ▄████████ ▄██   ▄
  //   ███    ███   ███    ███ ███    ███ ▀█████████▄ ███    ███   ███    ███ ███   ██▄
  //   ███    █▀    ███    ███ ███    █▀     ▀███▀▀██ ███    ███   ███    ███ ███▄▄▄███
  //  ▄███▄▄▄       ███    ███ ███            ███   ▀ ███    ███  ▄███▄▄▄▄██▀ ▀▀▀▀▀▀███
  // ▀▀███▀▀▀     ▀███████████ ███            ███     ███    ███ ▀▀███▀▀▀▀▀   ▄██   ███
  //   ███          ███    ███ ███    █▄      ███     ███    ███ ▀███████████ ███   ███
  //   ███          ███    ███ ███    ███     ███     ███    ███   ███    ███ ███   ███
  //   ███          ███    █▀  ████████▀     ▄████▀    ▀██████▀    ███    ███  ▀█████▀
  //                                                               ███    ███

  const WorkSpaceFactoryLib = await ethers.getContractFactory(
    "WorkSpaceFactoryLib"
  );
  const workSpacefactioryLib = await WorkSpaceFactoryLib.deploy();
  const workspacefactorylib = await workSpacefactioryLib.deployed();

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
  //Factory is deployed with a 0.5% fee
  const workSpaceFactory = await WorkSpaceFactory.deploy(50);
  const workspacefactory = await workSpaceFactory.deployed();

  //    ▄█     █▄   ▄██████▄     ▄████████    ▄█   ▄█▄    ▄████████    ▄███████▄    ▄████████  ▄████████    ▄████████
  // ███     ███ ███    ███   ███    ███   ███ ▄███▀   ███    ███   ███    ███   ███    ███ ███    ███   ███    ███
  // ███     ███ ███    ███   ███    ███   ███▐██▀     ███    █▀    ███    ███   ███    ███ ███    █▀    ███    █▀
  // ███     ███ ███    ███  ▄███▄▄▄▄██▀  ▄█████▀      ███          ███    ███   ███    ███ ███         ▄███▄▄▄
  // ███     ███ ███    ███ ▀▀███▀▀▀▀▀   ▀▀█████▄    ▀███████████ ▀█████████▀  ▀███████████ ███        ▀▀███▀▀▀
  // ███     ███ ███    ███ ▀███████████   ███▐██▄            ███   ███          ███    ███ ███    █▄    ███    █▄
  // ███ ▄█▄ ███ ███    ███   ███    ███   ███ ▀███▄    ▄█    ███   ███          ███    ███ ███    ███   ███    ███
  //  ▀███▀███▀   ▀██████▀    ███    ███   ███   ▀█▀  ▄████████▀   ▄████▀        ███    █▀  ████████▀    ██████████
  //                          ███    ███   ▀
  const WorkSpaceLib = await ethers.getContractFactory("WorkSpaceLib");
  const workSpaceLib = await WorkSpaceLib.deploy();
  const workspacelib = await workSpaceLib.deployed();
  const WorkSpace = await ethers.getContractFactory("WorkSpace", {
    libraries: {
      WorkSpaceLib: workspacelib.address,
      FactoryContractVerifier: factorycontractverifier.address,
    },
  });
  const workSpace = await WorkSpace.deploy();
  const workspace = await workSpace.deployed();

  //      ▄█  ▄██████▄  ▀█████████▄
  //     ███ ███    ███   ███    ███
  //     ███ ███    ███   ███    ███
  //     ███ ███    ███  ▄███▄▄▄██▀
  //     ███ ███    ███ ▀▀███▀▀▀██▄
  //     ███ ███    ███   ███    ██▄
  //     ███ ███    ███   ███    ███
  // █▄ ▄███  ▀██████▀  ▄█████████▀
  // ▀▀▀▀▀▀

  const JobLib = await ethers.getContractFactory("JobLib");
  const jobLib = await JobLib.deploy();
  const joblib = await jobLib.deployed();

  const Job = await ethers.getContractFactory("Job", {
    libraries: {
      JobLib: joblib.address,
      FactoryContractVerifier: factorycontractverifier.address,
    },
  });
  const jobdeploy = await Job.deploy();
  const job = await jobdeploy.deployed();

  //    ▄█        ▄█  ███▄▄▄▄      ▄█   ▄█▄
  // ███       ███  ███▀▀▀██▄   ███ ▄███▀
  // ███       ███▌ ███   ███   ███▐██▀
  // ███       ███▌ ███   ███  ▄█████▀
  // ███       ███▌ ███   ███ ▀▀█████▄
  // ███       ███  ███   ███   ███▐██▄
  // ███▌    ▄ ███  ███   ███   ███ ▀███▄
  // █████▄▄██ █▀    ▀█   █▀    ███   ▀█▀
  // ▀                          ▀

  const DLink = await ethers.getContractFactory("DLink");
  const dLink = await DLink.deploy();
  const dlink = await dLink.deployed();

  //   ▀█████████▄   ▄██████▄     ▄████████    ▄████████ ████████▄
  //   ███    ███ ███    ███   ███    ███   ███    ███ ███   ▀███
  //   ███    ███ ███    ███   ███    ███   ███    ███ ███    ███
  //  ▄███▄▄▄██▀  ███    ███   ███    ███  ▄███▄▄▄▄██▀ ███    ███
  // ▀▀███▀▀▀██▄  ███    ███ ▀███████████ ▀▀███▀▀▀▀▀   ███    ███
  //   ███    ██▄ ███    ███   ███    ███ ▀███████████ ███    ███
  //   ███    ███ ███    ███   ███    ███   ███    ███ ███   ▄███
  // ▄█████████▀   ▀██████▀    ███    █▀    ███    ███ ████████▀
  //                                        ███    ███
  const BoardLib = await ethers.getContractFactory("BoardLib");
  const boardLib = await BoardLib.deploy();
  const boardlib = await boardLib.deployed();

  const Board = await ethers.getContractFactory("Board", {
    libraries: {
      BoardLib: boardlib.address,
    },
  });
  //The first maintainer is the owner here
  const boardDeploy = await Board.deploy(
    dworktoken.address,
    workspacefactory.address,
    100, //only 100 blocks for a proposal to expire for testing purposes,
    10, // blocks for rate limit
    ethers.utils.parseEther("10000") //The minimum share the proposal creator has to have
  );
  const board = await boardDeploy.deployed();
  console.log(`\nCONTRACTS:`);
  console.log(`DWORK : ${dworktoken.address}`);
  console.log(`CrowdSale : ${dworkcrowdsale.address}`);
  console.log(`Dividends : ${dividends.address}`);
  console.log(`Factory : ${workspacefactory.address}`);
  console.log(`WorkSpace : ${workspace.address}`);
  console.log(`Job : ${job.address}`);
  console.log(`Link : ${dlink.address}`);
  console.log(`Board : ${board.address}`);

  console.log("\nLIBRARIES:");
  console.log(`DividendsLib : ${dividendslib.address}`);
  console.log(`Factorylib : ${workspacefactorylib.address}`);
  console.log(`WorkSpacelib : ${workspacelib.address}`);
  console.log(`Joblib : ${joblib.address}`);
  console.log(`Boardlib : ${boardlib.address}`);
  console.log(`FactoryContractVerifier : ${factorycontractverifier.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
