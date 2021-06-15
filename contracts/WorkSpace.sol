// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Job.sol";
import "./RoleLib.sol";
import "./WorkSpaceLib.sol";
import "./CloneFactory.sol";
import "./Initializer.sol";
import "./WorkSpaceFactory.sol";
contract WorkSpace is AccessControl, CloneFactory,Initializable{
    event RegistrationSuccess(bytes32 role, address registeredAddress);
    event ModerationResult(bool done);
    event CreateJobCalled(bool called,string msg);
    
    using WorkSpaceLib for WorkSpaceState;
    WorkSpaceState state;


    function initialize(
        uint8 _fee,
        string memory _metadataUrl,
        address _manager,
        address _jobLibraryAddress
    ) external initializer() {
        // initializer PROTECTION!
        // lets call the factory with the msg.sender address!
        WorkSpaceFactory factory = WorkSpaceFactory(msg.sender);
        bool isReal = factory.amIAFactory();
        require(isReal,"Caller is not the factory!");
        // the manager must deploy his own contract to match Jobs
        require(_manager != address(0), "_manager is the zero address");
        require(_jobLibraryAddress != address(0), "_jobLibraryAddress is the zero address");

        state.fee = _fee;
        state.metadataUrl = _metadataUrl;
        state.managerAddress = payable(_manager);
        _setupRole(RoleLib.MANAGER_ROLE, _manager);
        state.requireInvite = true;
        state.factoryAddress = msg.sender;
        
        state.jobLibraryAddress = _jobLibraryAddress;
    }


    function createJob() external onlyRole(RoleLib.CLIENT_ROLE) {
        require(state.clients[msg.sender].initialized == true, "The client must be initialized");
        require(state.clients[msg.sender].disabled == false, "Disabled clients cannot create jobs");//TODO: TEST 
        Job job = Job(createClone(state.jobLibraryAddress));
        job.initialize(state.factoryAddress,address(this),msg.sender);
        state.jobs[msg.sender].push(job);
    }

    // TODO: Assign workers to jobs through the workspace!

    function registerWorker(
        string calldata _metadataUrl,
        address workerAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external {
        require(workerAddress != address(0), "workerAddress is the zero address");
        require(hasRole(RoleLib.MANAGER_ROLE,workerAddress) == false,"The manager cannot become a worker.");
        if (state.managerAddress != msg.sender){
           require(workerAddress == msg.sender);
        } 
        require(state.registrationOpen,"Registration is not open");
        require(state.workers[msg.sender].initialized == false,"The worker already signed up");

        state.registerWorker(
            _metadataUrl,
            workerAddress,
            inviteToken,
            _writtenContractHash
        );
        _setupRole(RoleLib.WORKER_ROLE, workerAddress);
    }

    function registerClient(
        string calldata _metadataUrl,
        address clientAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external returns (Client memory) {
        require(clientAddress != address(0), "clientAddress is the zero address");
        require(hasRole(RoleLib.MANAGER_ROLE,clientAddress) == false,"The client cannot become a manager.");
        if (state.managerAddress != msg.sender){
            // If it's not the manager sending this transaction then the address has to be the sender
            // It's because a manager can sign up other people.
          require(clientAddress == msg.sender);
        } 
        
        require(state.registrationOpen,"Registration is not open");
        require(state.clients[msg.sender].initialized == false,"The client already signed up"); 
        state.registerClient(
            _metadataUrl,
            clientAddress, 
            inviteToken,
            _writtenContractHash
        );
        _setupRole(RoleLib.CLIENT_ROLE, clientAddress);
        return state.clients[clientAddress];
    }

    function moderateTarget(
        address moderatedAddress,
        bytes32 target,
        bool setTo
    ) external onlyRole(RoleLib.MANAGER_ROLE) returns (bool) {
        return state.moderateTarget(moderatedAddress, target, setTo);
    }

    function setFee(uint8 _fee) external onlyRole(RoleLib.MANAGER_ROLE) {
        state.setFee(_fee);
    }

    function setMetadata(string calldata _metadataUrl)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.setMetadata(_metadataUrl);
    }

    
    function whoAmI() external view returns (string memory) {
        if (hasRole(RoleLib.MANAGER_ROLE, msg.sender)) {
            return "manager";
        } else if (hasRole(RoleLib.CLIENT_ROLE, msg.sender)) {
            return "client";
        } else if (hasRole(RoleLib.WORKER_ROLE, msg.sender)) {
            return "worker";
        } else {
            return "not registered";
        }
    }

    function addWrittenContract(
        bytes32 contractHash,
        string memory contractUrl)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.addWrittenContract(contractHash,contractUrl);
    }


    function setCurrentWorkerContractHash(bytes32 newHash)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.setCurrentWorkerContractHash(newHash);
    }

    function setCurrentClientContractHash(bytes32 newHash)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.setCurrentClientContractHash(newHash);
    }

    function addInviteToken(string calldata inviteToken)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.addInviteToken(inviteToken);
    }

    function noInvites() external onlyRole(RoleLib.MANAGER_ROLE) {
        state.noInvites();
    }

    function setJobLibraryAddress(address _address) external onlyRole(RoleLib.MANAGER_ROLE){
        state.setJobLibraryAddress(_address);
    }
    function setRegistrationOpen(bool isOpen) external onlyRole(RoleLib.MANAGER_ROLE) {
        state.setRegistrationOpen(isOpen);
    }
    function getWrittenContract(bytes32 contractHash) external view
        returns (string memory)
    {
        return state.writtenContractUrls[contractHash];
    }

    function getJobLibraryAddress() external view returns (address){
        return state.jobLibraryAddress;
    }

    function metadataUrl() external view returns (string memory) {
        return state.metadataUrl;
    }

    function requireInvite() external view returns (bool) {
        return state.requireInvite;
    }

    function currentWorkerContractHash() external view returns (bytes32) {
        return state.currentWorkerWrittenContractHash;
    }

    function currentClientContractHash() external view returns (bytes32) {
        return state.currentClientWrittenContractHash;
    }

    function clients(address _address) external view returns (Client memory) {
        return state.clients[_address];
    }

    function fee() external view returns (uint8) {
        return state.fee;
    }

    function workers(address _address) external view returns (Worker memory) {
        return state.workers[_address];
    }

    function jobs(address _address) external view returns (Job[] memory){
        return state.jobs[_address];
    }

    function getRegistrationOpen() external view returns (bool){
        return state.registrationOpen;
    }
    function getManagerAddress() external view returns (address){
        return state.managerAddress;
    }

    function amIWorkSpace() external pure returns (bool){
        // This is used by the job to call back and ask the sender if he is this contract
        return true;
    }
}
