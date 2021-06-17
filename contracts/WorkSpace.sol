// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Job.sol";
import "./RoleLib.sol";
import "./WorkSpaceLib.sol";
import "./CloneFactory.sol";
import "./Initializer.sol";
import "./WorkSpaceFactory.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract WorkSpace is AccessControl, CloneFactory,Initializable,Multicall{
    event RegistrationSuccess(bytes32 role, address registeredAddress);
    event Moderated(address,bytes32,bool);

    //TODO: ADD events to tests!!
    event JobCreated();
    event FallbackTriggered(address);
    using WorkSpaceLib for WorkSpaceState;
    WorkSpaceState state;


    function initialize(
        uint8 _fee,
        string memory _metadataUrl,
        address _manager,
        address _jobLibraryAddress,
        uint workSpaceVersion,
        uint jobVersion
    ) external initializer() {
        require(_manager != address(0), "504");
        require(_jobLibraryAddress != address(0), "505");
        state.fee = _fee;
        state.metadataUrl = _metadataUrl;
        state.managerAddress = payable(_manager);
        state.requireInvite = true;
        state.factoryAddress = msg.sender;
        state.jobLibraryAddress = _jobLibraryAddress;
        state.workSpaceVersion = workSpaceVersion;
        state.jobVersion = jobVersion;

        _setupRole(RoleLib.MANAGER_ROLE, _manager);
        // lets call the factory with the msg.sender address, an Abi call to avoid getting called by a non factory
        WorkSpaceFactory factory = WorkSpaceFactory(msg.sender);
        bool isReal = factory.amIAFactory();
        require(isReal,"506");
    }


    function createJob() external onlyRole(RoleLib.CLIENT_ROLE) {
        require(state.clients[msg.sender].initialized == true, "507");
        require(state.clients[msg.sender].disabled == false, "508");
        require(state.lock[msg.sender] == false,"519");
        state.lock[msg.sender] = true;
        
        Job job = Job(payable(createClone(state.jobLibraryAddress)));

        try job.initialize(state.factoryAddress,address(this),msg.sender){
        state.clientjobs[msg.sender].push(job);
        emit JobCreated();
        } catch {
            state.lock[msg.sender] = false;

        }

        state.lock[msg.sender] = false;

    }

     
    // function assignWorkers(address to, address[] calldata workerAddresses,uint[] calldata shares,string calldata _metadataUrl) external {
    //      //TODO: test THIS!
    //      bool isManager = hasRole(RoleLib.MANAGER_ROLE, msg.sender);
    //      bool isClient = hasRole(RoleLib.CLIENT_ROLE,msg.sender);
    //      require(isManager || isClient,"509");
    //      require(workerAddresses.length == shares.length,"510");
    //      //TODO: Lock!


    //      for(uint i = 0;i < workerAddresses.length;i++){
    //       Job job = Job(payable(to));
    //       //require that the worker address exists
    //       //job.createAssignment(a,zs shares_,_metadataUrl);
    //       // add the worker to the worker jobs
    //      }  


     //}
    function registerWorker(
        string calldata _metadataUrl,
        address workerAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external returns (Worker memory) {
        require(workerAddress != address(0), "511");
        require(hasRole(RoleLib.MANAGER_ROLE,workerAddress) == false,"512");
        if (state.managerAddress != msg.sender){
           require(workerAddress == msg.sender);
        } 
        require(state.registrationOpen,"513");
        require(state.workers[msg.sender].initialized == false,"514");

        state.registerWorker(
            _metadataUrl,
            workerAddress,
            inviteToken,
            _writtenContractHash
        );
        _setupRole(RoleLib.WORKER_ROLE, workerAddress);
        return state.workers[workerAddress];
    }

    function registerClient(
        string calldata _metadataUrl,
        address clientAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external returns (Client memory) {
        require(clientAddress != address(0), "515");
        require(hasRole(RoleLib.MANAGER_ROLE,clientAddress) == false,"516");
        if (state.managerAddress != msg.sender){
            // If it's not the manager sending this transaction then the address has to be the sender
            // It's because a manager can sign up other people.
          require(clientAddress == msg.sender);
        } 
        require(state.registrationOpen,"517");
        require(state.clients[msg.sender].initialized == false,"518"); 
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

    function clientjobs(address _address) external view returns (Job[] memory){
        return state.clientjobs[_address];
    }
    function workerjobs(address _address) external view returns (Job[] memory){
        return state.workerjobs[_address];
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

    function getVersions() external view returns (uint,uint){
        return (state.workSpaceVersion,state.jobVersion);
    }

    function getAddresses() external view returns (address[] memory,address[] memory){
        return state.getAddresses();
    }

    fallback() external {
        emit FallbackTriggered(msg.sender);
    }
}
