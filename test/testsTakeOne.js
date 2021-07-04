const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  setUp,
  addLibrariesAndWorkspace,
  setUpJobTests,
  expectRevert,
} = require("./setup");
console.log("BLEEDING EDGE, Hardhat not compatible,yet fully with sol 0.8.6");
describe("factory and workspace tests", async function () {
  it("Failing to hack the master contracts", async function () {
    const { workspacemaster, jobmaster } = await setUp();

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

    await expect(
      workspacefactory.createWorkSpace(5000, "Meta")
    ).to.be.revertedWith("552");

    await expect(workspacefactory.setDisabled(true));

    //  // ERROR 501
    await workspacefactory.setDisabled(true).then(async () => {
      await expect(
        workspacefactory.createWorkSpace(1, "Meta")
      ).to.be.revertedWith("501");
    });

    await workspacefactory.setDisabled(false);

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
    const { workspacefactory, owner, holder1 } = await setUp();
    let initialContractFee = await workspacefactory.getContractFee();
    expect(initialContractFee).to.be.equal(100);
    expect(workspacefactory.connect(holder1).setContractFee(123)).to.be
      .reverted;
    let ownerAddress = await workspacefactory.owner();
    expect(ownerAddress).to.be.equal(owner.address);

    expect(workspacefactory.connect(holder1).setDisabled(true)).to.be.reverted;
    expect(workspacefactory.connect(holder1).setContractFee(1)).to.be.reverted;
    // ERROR 557
    await expectRevert(() => workspacefactory.setContractFee(13), "557");

    //FOR TESTING ERROR 521
    expect(workspacefactory.setContractFee(1230)).to.be.revertedWith("521");
    //set CONTRACT FEE NOW IS ONLY CALLABLE BY THE BOARD!
  });

  it("Workspace metadata", async function () {
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

  it("Registration disabling", async function () {
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

    expect(await workspace.getRegistrationOpen()).to.be.false;

    await workspace.setRegistrationOpen(true);

    expect(await workspace.getRegistrationOpen()).to.be.true;
  });

  it("Written contracts", async function () {
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

  it("Roles and registration", async function () {
    const {
      workspacefactory,
      workspacemaster,
      jobmaster,
      owner,
      holder1,
      holder2,
    } = await setUp();
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
    expect(myRole).to.equal(201);
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
    ).to.be.revertedWith("587");

    expect(
      workspace.registerWorker(
        "metaddataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "",
        mockContractHash
      )
    ).to.be.revertedWith("587");

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
    ).to.be.revertedWith("553");

    //Client tries to register twice

    expect(
      workspace.registerClient(
        "metadataurl",
        "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
        "Hazx123sZ",
        mockContractHash
      )
    ).to.be.revertedWith("554");

    //Turn of invites

    await workspace.noInvites();

    // registering client again, without invite code and new address

    expect(
      workspace.registerWorker("meta", owner.address, "", mockContractHash)
    ).to.be.revertedWith("512");
    //TESTING 500 error
    expect(
      workspace.registerWorker(
        "metaurl",
        "0x0000000000000000000000000000000000000000",
        "",
        mockContractHash
      )
    ).to.be.revertedWith("500");

    //TESTING 549 error
    expect(
      workspace
        .connect(holder1)
        .registerWorker(
          "metaurl",
          "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
          "",
          mockContractHash
        )
    ).to.be.revertedWith("549");

    //
    expect(
      workspace.registerWorker(
        "metaurl",
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        "",
        mockContractHash
      )
    ).to.emit(workspace, "RegistrationSuccess");

    // I try to register twice
    //553 error
    expect(
      workspace.registerWorker(
        "metaurl",
        "0x2D3aEca8f8a18Cb9E7D067D37eD1D538b4d36e02",
        "",
        mockContractHash
      )
    ).to.be.revertedWith("553");

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

    // //TESTING 513 error
    await workspace.setRegistrationOpen(false).then(async () => {
      await expect(
        workspace.registerWorker(
          "metaurl",
          holder1.address,
          "",
          mockContractHash
        )
      ).to.be.revertedWith("513");
      await expect(
        workspace.registerClient("meta", holder2.address, "", mockContractHash)
      ).to.be.revertedWith("517");
      await workspace.setRegistrationOpen(true);
    });

    // TESTING 514
    await workspace
      .connect(holder1)
      .registerWorker("metaurl", holder1.address, "", mockContractHash)
      .then(async () => {
        await expect(
          workspace
            .connect(holder1)
            .registerWorker("metaurl", holder1.address, "", mockContractHash)
        ).to.be.revertedWith("553");
      });

    //TESTING 516
    await expect(
      workspace.registerClient("meta", owner.address, "", mockContractHash)
    ).to.be.revertedWith("516");

    //A 500 error for 0 address
    await expect(
      workspace.registerClient(
        "meta",
        "0x0000000000000000000000000000000000000000",
        "",
        mockContractHash
      )
    ).to.be.revertedWith("500");

    //The 550 error from verify register client
    await expect(
      workspace
        .connect(holder1)
        .registerClient("meta", holder2.address, "", mockContractHash)
    ).to.be.revertedWith("550");

    // The 554 error for registering twice
    await workspace
      .connect(holder2)
      .registerClient("metaurl", holder2.address, "", mockContractHash)
      .then(async () => {
        await expect(
          workspace
            .connect(holder2)
            .registerClient("metaurl", holder2.address, "", mockContractHash)
        ).to.be.revertedWith("554");
      });
  });

  it("Workspace fees", async function () {
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

    let fee = await workspace.fee();

    expect(fee).to.equal(1);

    await workspace.setFee(8);

    expect(await workspace.fee()).to.equal(8);

    await expect(workspace.setFee(5000)).to.be.revertedWith("552");
  });

  it("Moderation", async function () {
    const {
      workspacefactory,
      workspacemaster,
      jobmaster,
      owner,
      worker,
      client,
      holder1,
    } = await setUp();
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

    let mockContractHash = await ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("test hash")
    );
    await workspace.noInvites();

    await workspace.registerClient(
      "metadataurl",
      client.address,
      "",
      mockContractHash
    );

    expect(
      workspace
        .connect(client)
        .registerWorker("metadataurl", worker.address, "", mockContractHash)
    ).to.revertedWith("549");

    await workspace.registerWorker(
      "metadataurl",
      worker.address,
      "",
      mockContractHash
    );

    expect(
      workspace
        .connect(worker)
        .registerClient(
          "metadataurl",
          "0x050e8C2DC9454cA53dA9eFDAD6A93bB00C216Ca0",
          "",
          mockContractHash
        )
    ).to.revertedWith("550");

    const WORKER_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("WORKER_ROLE")
    );
    const CLIENT_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("CLIENT_ROLE")
    );

    //A 500 error
    expect(
      workspace.moderateTarget(
        "0x0000000000000000000000000000000000000000",
        WORKER_ROLE,
        true
      )
    ).to.be.revertedWith("500");
    //A 555 error
    expect(
      workspace.moderateTarget(holder1.address, WORKER_ROLE, true)
    ).to.be.revertedWith("555");
    expect(
      workspace.moderateTarget(holder1.address, CLIENT_ROLE, true)
    ).to.be.revertedWith("556");

    expect(workspace.moderateTarget(worker.address, WORKER_ROLE, true)).to.emit(
      workspace,
      "Moderated"
    );
    let disabledWorker = await workspace.workers(worker.address);
    expect(disabledWorker.disabled).to.be.true;

    expect(workspace.moderateTarget(client.address, CLIENT_ROLE, true)).to.emit(
      workspace,
      "Moderated"
    );
    let disabledClient = await workspace.clients(client.address);
    expect(disabledClient.disabled).to.be.true;
    // now I just set them back
    expect(
      workspace.moderateTarget(worker.address, WORKER_ROLE, false)
    ).to.emit(workspace, "Moderated");
    let disabledWorker2 = await workspace.workers(worker.address);
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
      holder1,
      holder2,
    } = await setUp();
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
    //508 test
    expect(workspace.connect(client).createJob("This is the metadata",client.address)).to.be
      .revertedWith("508");

    await workspace.moderateTarget(client.address, CLIENT_ROLE, false);
    expect(
      workspace
        .connect(client)
        .createJob("This is the metadata", client.address)
    ).to.emit(workspace, "JobCreated");
    const clientJobs = await workspace.clientjobs(client.address);
    expect(clientJobs.length).to.equal(1);
    //ERROR 509
    await expect(
      workspace.connect(holder1).createJob("meta", client.address)
    ).to.be.revertedWith("509");

    //ERROR 558
    await expect(
      workspace.connect(client).createJob("", holder1.address)
    ).to.be.revertedWith("558");

    //A 500 error for zero address
    await expect(
      workspace.createJob("", "0x0000000000000000000000000000000000000000")
    ).to.be.revertedWith("500");

    // A 507 for trying to adda  job to an unknown address
    await expect(workspace.createJob("", holder2.address)).to.be.revertedWith(
      "507"
    );


  });

  it("Workspace Deprecation checking", async function () {
    // I will create 2 workspaces and then check which one is deprecated from the order
    // This is useful if the users saved a dlink to a workspace, but the workspace got updated
    const { workspacefactory, workspacemaster, jobmaster, owner, client } =
      await setUp();
    await addLibrariesAndWorkspace(
      workspacefactory,
      workspacemaster,
      jobmaster
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
    await expect(workspacefactory.setWorkSpaceLibrary(owner.address)).to.emit(
      workspacefactory,
      "WorkSpaceLibraryVersion"
    );
    // just to increment the index
    await expect(
      workspacefactory.setWorkSpaceLibrary(workspacemaster.address)
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
