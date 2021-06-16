// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
import "./Job.sol";
import "./RoleLib.sol";
struct WorkSpaceState {
    uint8 fee; // This is the percentage the manager gets per job
    address managerAddress; // This is the address of the manager where he recieves the above fee
    string metadataUrl; // Metadata points to ipfs link, this is the workspace metadata
    
    
    mapping(bytes32 =>string) writtenContractUrls; // The key is the contract hash, the value is the ipfs hash link    


    //clients and workers must agree to one when signing up,
    bytes32 currentWorkerWrittenContractHash; 
    // The current contract index should be the default offered to a client or worker
    bytes32 currentClientWrittenContractHash;
    
    
    
    bytes32 inviteTokenHash;
    bool requireInvite;
    bool registrationOpen;
    //The factory address is the address of the factory creating this,
    //later the fee collector address comes from the .getOwner() function from the factory.
    // That is where the fees can be sent to, to the owner of the factory
    address factoryAddress;
    mapping(address => Worker) workers;
    mapping(address => Client) clients;
    mapping(address => Job[]) clientjobs; // jobs are mapped to the clients address
    //TODO: WORKERJOBS!, TODO: rename above to clientJob!
    mapping(address => Job[]) workerjobs;

    address jobLibraryAddress;
    uint workSpaceVersion;
    uint jobVersion;
    //TODO: Managers cannot see workers and clients so easily without knowing the address
    
}

struct Worker {
    string metadataUrl; // Should be JSON
    bool occupied; // Does the worker have a job now?
    bool disabled; // workers can be disabled by the manager for moderation reasons
    bool initialized;
   
    bytes32 writtenContractHash; // this is passed in, hash is created on front end from a written contract
}

struct Client {
    string metadataUrl; // should be a json, so the front end can match with the worker
    bool disabled; // client can be disabled by manager for any reason
    bool initialized;

   bytes32 writtenContractHash;
}

library WorkSpaceLib {
    event RegistrationSuccess(bytes32 role, address registeredAddress);
    event ModerationResult(bool done);
    event CreateJobCalled(bool reusable, string _metadataUrl);
    event DebugLog(bool log, string msg);

    function registerWorker(
        WorkSpaceState storage self,
        string calldata _metadataUrl,
        address workerAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external {
        if (self.requireInvite) {
            // if the registration required invite, I check the token validity
            require(
                checkInviteTokenValidity(self.inviteTokenHash, inviteToken)
            );
        }
        require(
            !alreadyClientOrWorker(
                self.clients[workerAddress].initialized,
                self.workers[workerAddress].initialized
            ),
            "Client is already registered for something"
        );
        // Anyone can register as a worker if the above require is not triggered

        self.workers[workerAddress] = Worker({
            metadataUrl: _metadataUrl,
            occupied: false,
            disabled: false,
            initialized: true,
            writtenContractHash: _writtenContractHash
        });
        emit RegistrationSuccess(RoleLib.WORKER_ROLE, workerAddress);
    }

    function registerClient(
        WorkSpaceState storage self,
        string calldata _metadataUrl,
        address clientAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external {
        if (self.requireInvite) {
            require(
                checkInviteTokenValidity(self.inviteTokenHash, inviteToken)
            );
        }
        require(
            !alreadyClientOrWorker(
                self.clients[clientAddress].initialized,
                self.workers[clientAddress].initialized
            ),
            "Client is already registered for something"
        );

        self.clients[clientAddress] = Client({
            metadataUrl: _metadataUrl,
            disabled: false,
            initialized: true,
            writtenContractHash: _writtenContractHash
        });
        emit RegistrationSuccess(RoleLib.CLIENT_ROLE, clientAddress);
    }

    // the Recruiter must be able to manage the clients and the workers disabling and allowing them to work again
    function moderateTarget(
        WorkSpaceState storage self,
        address moderatedAddress,
        bytes32 target,
        bool setTo
    ) external returns (bool res) {
        if (target == RoleLib.WORKER_ROLE) {
            Worker memory worker = self.workers[moderatedAddress];
            require(worker.initialized, "Worker is not initialized");
            worker.disabled = setTo;

            self.workers[moderatedAddress] = worker;
            return self.workers[moderatedAddress].disabled;
        } else if (target == RoleLib.CLIENT_ROLE) {
            Client memory client = self.clients[moderatedAddress];

            require(client.initialized, "Client is not initialized");
            client.disabled = setTo;
            self.clients[moderatedAddress] = client;
            return self.clients[moderatedAddress].disabled;
        }
    }


    // The manager can set the fee anytime
    function setFee(WorkSpaceState storage self, uint8 _fee) external {
        self.fee = _fee;
    }

    // The metadata can be changed, it's an ipfs hash
    function setMetadata(
        WorkSpaceState storage self,
        string calldata _metadataUrl
    ) external {
        self.metadataUrl = _metadataUrl;
    }


/////////////////////////////////////////////////////////

    // A manager can add contract urls. these are real written contracts the parties agree to
    function addWrittenContract(
        WorkSpaceState storage self,
        bytes32 contractHash,
        string memory contractUrl
    ) external {
        self.writtenContractUrls[contractHash] = contractUrl;
    }

    function setCurrentWorkerContractHash(
        WorkSpaceState storage self,
        bytes32 newHash
    ) external {
        self.currentWorkerWrittenContractHash = newHash;
    }

    function setCurrentClientContractHash(
        WorkSpaceState storage self,
        bytes32 newHash
    ) external {
        self.currentClientWrittenContractHash = newHash;
    }



    function addInviteToken(
        WorkSpaceState storage self,
        string calldata inviteToken
    ) external {
        self.requireInvite = true;
        self.inviteTokenHash = keccak256(abi.encode(inviteToken));
    }

    function noInvites(WorkSpaceState storage self) external {
        self.requireInvite = false;
    }

    function checkInviteTokenValidity(
        bytes32 hashedToken,
        string memory inviteToken
    ) internal pure returns (bool) {
        bytes32 token = keccak256(abi.encode(inviteToken));
        return token == hashedToken;
    }

    function alreadyClientOrWorker(
        bool clientInitialized,
        bool workerInitialized
    ) internal pure returns (bool) {
        if (clientInitialized) {
            return true;
        }
        if (workerInitialized) {
            return true;
        }

        return false;
    }
    function setRegistrationOpen(WorkSpaceState storage self,bool isOpen) external {
        self.registrationOpen = isOpen;
    }
    
}
