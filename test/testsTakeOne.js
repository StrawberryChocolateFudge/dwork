const { expect } = require("chai");
const { ethers } = require("hardhat");
const { setUp, addLibrariesAndWorkspace, setUpJobTests } = require("./setup");

describe("factory and workspace tests", async function () {
  it("Failing to hack the master contracts", async function () {
    const { workspacemaster, workspacefactory, jobmaster } = await setUp();

    expect(
      workspacemaster.initialize(
        0,
        "",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        jobmaster.address,
        1,
        1
      )
    ).to.be.reverted;

    expect(
      workspacemaster.initialize(
        0,
        "",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        jobmaster.address,
        1,
        1
      )
    ).to.be.reverted;
  });

  it("Create workspace", async function () {
    const { workspacefactory, workspacemaster, jobmaster, factoryBoss } =
      await setUp();
    await workspacefactory
      .connect(factoryBoss)
      .setWorkSpaceLibrary(workspacemaster.address);

    expect(await workspacefactory.getWorkSpaceLibrary()).to.equal(
      workspacemaster.address
    );

    await workspacefactory
      .connect(factoryBoss)
      .setJobLibraryAddress(jobmaster.address);
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

  it("Contract fees", async function () {
    const { workspacefactory, factoryBoss } = await setUp();
    let initialContractFee = await workspacefactory.getContractFee();
    expect(initialContractFee).to.be.equal(0);
    expect(workspacefactory.setContractFee(123)).to.be.reverted;
    let ownerAddress = await workspacefactory.getOwner();
    expect(ownerAddress).to.be.equal(factoryBoss.address);
    // the owner is the factoryboss so the bellow calls get rejected
    expect(workspacefactory.setDisabled(true)).to.be.reverted;
    expect(workspacefactory.setContractFee(1)).to.be.reverted;

    expect(
      workspacefactory.connect(factoryBoss).setContractFee(123)
    ).to.be.revertedWith("Fee cannot be higher than 100");
   
    expect(
      workspacefactory.connect(factoryBoss).setContractFee(12)
    ).to.emit(workspacefactory,"ContractFeeChange").withArgs(12);


  });

  it("Workspace metadata", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner, factoryBoss } =
      await setUp();
    await addLibrariesAndWorkspace(
      workspacefactory,
      workspacemaster,
      jobmaster,
      factoryBoss
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

  it("Registration disabling", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner, factoryBoss } =
      await setUp();
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

    expect(await workspace.getRegistrationOpen()).to.be.false;

    await workspace.setRegistrationOpen(true);

    expect(await workspace.getRegistrationOpen()).to.be.true;
  });

  it("Written contracts", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner, factoryBoss } =
      await setUp();
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

  it("Roles and registration", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner, factoryBoss } =
      await setUp();
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

    let myRole = await workspace.whoAmI();
    expect(myRole).to.equal("manager");
    let mockContractHash = await ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("test hash")
    );

    expect(await workspace.requireInvite()).to.be.true;

    // Registering as a client or worker should fail since invite is required but none is set
    // The manager signes up external accounts here
    let clientRegisterFailed = false;

    expect(
      workspace.registerClient(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "",
        mockContractHash
      )
    ).to.be.reverted;

    expect(
      workspace.registerWorker(
        "metaddataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "",
        mockContractHash
      )
    ).to.be.reverted;

    // Now I set the token hash so I can register with an address

    await workspace.addInviteToken("Hazx123sZ");

    expect(
      workspace.registerClient(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "Hazx123sZ",
        mockContractHash
      )
    ).to.emit(workspace, "RegistrationSuccess");

    let client = await workspace.clients(
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0"
    );

    expect(client.initialized).to.be.true;

    // The client cannot register as a worker and vice versa

    expect(
      workspace.registerWorker(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "Hazx123sZ",
        mockContractHash
      )
    ).to.be.reverted;

    //Client tries to register twice

    expect(
      workspace.registerClient(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "Hazx123sZ",
        mockContractHash
      )
    ).to.be.reverted;

    //Turn of invites

    await workspace.noInvites();

    // registering client again, without invite code and new address

    expect(
      workspace.registerWorker(
        "metaurl",
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        "",
        mockContractHash
      )
    ).to.emit(workspace, "RegistrationSuccess");

    // I try to register twice
    expect(
      workspace.registerWorker(
        "metaurl",
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        "",
        mockContractHash
      )
    ).to.be.reverted;

    let addresses = await workspace.getAddresses();
    expect(addresses.length).to.equal(2);
    let workerAddresses = addresses[0];
    let clientAddresses = addresses[1];

    expect(workerAddresses[0]).to.equal(
      "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02"
    );
    expect(clientAddresses[0]).to.equal(
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0"
    );
  });

  it("Workspace fees", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner, factoryBoss } =
      await setUp();
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

    let fee = await workspace.fee();

    expect(fee).to.equal(1);

    await workspace.setFee(8);

    expect(await workspace.fee()).to.equal(8);
  });

  it("Moderation", async function () {
    const { workspacefactory, workspacemaster, jobmaster, owner, factoryBoss } =
      await setUp();
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
    await workspace.registerClient(
      "metadataurl",
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
      "",
      mockContractHash
    );
    await workspace.registerWorker(
      "metadataurl",
      "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
      "",
      mockContractHash
    );
    const WORKER_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("WORKER_ROLE")
    );
    const CLIENT_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("CLIENT_ROLE")
    );
    expect(
      workspace.moderateTarget(
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        WORKER_ROLE,
        true
      )
    ).to.emit(workspace, "Moderated");
    let disabledWorker = await workspace.workers(
      "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02"
    );
    expect(disabledWorker.disabled).to.be.true;

    expect(
      workspace.moderateTarget(
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        CLIENT_ROLE,
        true
      )
    ).to.emit(workspace, "Moderated");
    let disabledClient = await workspace.clients(
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0"
    );
    expect(disabledClient.disabled).to.be.true;
    // now I just set them back
    expect(
      workspace.moderateTarget(
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        WORKER_ROLE,
        false
      )
    ).to.emit(workspace, "Moderated");
    let disabledWorker2 = await workspace.workers(
      "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02"
    );
    expect(disabledWorker2.disabled).to.be.false;
  });

  it("Dlink contract", async function () {
    const { dlink, client } = await setUp();
    const addrArrays = [
      "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
      "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
    ];
    await dlink.connect(client).link(addrArrays);
    const links = await dlink.connect(client).getLinks();
    expect(links).to.have.same.members(addrArrays);
    await dlink.connect(client).link([]);
    const linksAgain = await dlink.connect(client).getLinks();
    expect(linksAgain.length).to.equal(0);
    const counter = await dlink.connect(client).getCounter();
    expect(counter).to.equal(2);
    const historyLinks = await dlink.connect(client).getHistory(1);
    expect(historyLinks).to.have.same.members(addrArrays);

    let failed = false;
    try {
      await dlink.connect(client).getHistory(0);
    } catch (err) {
      failed = true;
    }
    expect(failed).to.be.true;
  });

  it("Client creates a job", async function () {
    const {
      workspacefactory,
      workspacemaster,
      jobmaster,
      owner,
      client,
      factoryBoss,
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

    const clientObj = await workspace.clients(client.address);
    expect(clientObj.initialized).to.be.true;

    // I disable the client and creating a job should throw
    const CLIENT_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("CLIENT_ROLE")
    );
    await workspace.moderateTarget(client.address, CLIENT_ROLE, true);

    expect(workspace.connect(client).createJob("This is the metadata")).to.be
      .reverted;

    await workspace.moderateTarget(client.address, CLIENT_ROLE, false);
    expect(workspace.connect(client).createJob("This is the metadata")).to.emit(
      workspace,
      "JobCreated"
    );
    const clientJobs = await workspace.clientjobs(client.address);
    expect(clientJobs.length).to.equal(1);
  });

  it("Workspace Deprecation checking", async function () {
    // I will create 2 workspaces and then check which one is deprecated from the order
    // This is useful if the users saved a dlink to a workspace, but the workspace got updated
    const {
      workspacefactory,
      workspacemaster,
      jobmaster,
      owner,
      client,
      factoryBoss,
    } = await setUp();
    await addLibrariesAndWorkspace(
      workspacefactory,
      workspacemaster,
      jobmaster,
      factoryBoss
    );
    let workspaceaddressOne = await workspacefactory.getContractAddress(
      owner.address
    );
    const indx1 = await workspacefactory.getCurrentWorkspaceIndex(
      owner.address
    );
    expect(indx1._hex).to.equal("0x01");

    // This create should fail because the libraries have not been updated,
    //There was a workspace creation before in @addLibrariesAndWorkspace
    expect(workspacefactory.createWorkSpace(1, "this is the metadata")).to.be
      .reverted;

    // I set the workspace to a new address, just to increase the index, this is not a valid contractaddr
    await expect(
      workspacefactory
        .connect(factoryBoss)
        .setWorkSpaceLibrary(factoryBoss.address)
    ).to.emit(workspacefactory, "WorkSpaceLibraryVersion");
    // just to increment the index
    await expect(
      workspacefactory
        .connect(factoryBoss)
        .setWorkSpaceLibrary(workspacemaster.address)
    ).to.emit(workspacefactory, "WorkSpaceLibraryVersion");
    // //The next one sets it back

    //   //Create one more, this time it should succeed

    await expect(
      workspacefactory.createWorkSpace(1, "this is the metadata")
    ).to.emit(workspacefactory, "WorkSpaceCreated");
    const indx2 = await workspacefactory.getCurrentWorkspaceIndex(
      owner.address
    );
    expect(indx2._hex).to.equal("0x02");

    let workspaceaddressTwo = await workspacefactory.getContractAddress(
      owner.address
    );

    expect(workspaceaddressOne).to.not.equal(workspaceaddressTwo);

    // from the clients and workers point of view, if they saved the workspace address
    // and it changes, they must get a warning on the front end about deprecation!
    // so I must have a way to check in JS
    const workspaceOne = await ethers.getContractAt(
      "WorkSpace",
      workspaceaddressOne,
      client
    );
    const managerAddress = await workspaceOne.getManagerAddress();
    const currentIndex = await workspacefactory.getCurrentWorkspaceIndex(
      managerAddress
    );
    const currentWorkspace = await workspacefactory.getHistoricWorkspace(
      currentIndex,
      managerAddress
    );
    // and voila we get the current workspace, if its not the same as address one, the address one is deprecated!
    expect(currentWorkspace).to.not.equal(workspaceaddressOne);
    expect(currentWorkspace).to.equal(workspaceaddressTwo);
  });
});
