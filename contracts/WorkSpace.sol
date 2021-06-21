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
import "./FactoryContractVerifier.sol";
import "./IWorkSpace.sol";
import "hardhat/console.sol";

contract WorkSpace is IWorkSpace,AccessControl, CloneFactory, Initializable, Multicall {
    event RegistrationSuccess(bytes32 role, address registeredAddress);
    event Moderated(address, bytes32, bool);
    event JobCreated(address);
    event FallbackTriggered(address);
    event AddedWorker(address to, address worker);

    using WorkSpaceLib for WorkSpaceState;
    WorkSpaceState state;

    using FactoryContractVerifier for FactoryContractVerifierState;
    FactoryContractVerifierState verifier;

        function initialize(
        uint16 _fee,
        string memory _metadataUrl,
        address _manager,
        uint256 workSpaceVersion
    ) external initializer() {
        require(verifier.checkFactoryBytecode(msg.sender), "506");
        state.setStateForInit(
            _fee,
            _metadataUrl,
            _manager,
            workSpaceVersion,
            msg.sender
        );
        _setupRole(RoleLib.MANAGER_ROLE, _manager);
    }

    function createJob(string calldata _metadataUrl) external onlyRole(RoleLib.CLIENT_ROLE) {
        require(state.clients[msg.sender].initialized == true, "507");
        require(state.clients[msg.sender].disabled == false, "508");
        WorkSpaceFactory factory = WorkSpaceFactory(state.factoryAddress);
        Job job = Job(payable(factory.createJob(msg.sender,state.managerAddress,_metadataUrl,state.fee)));
        state.clientjobs[msg.sender].push(job);
        emit JobCreated(address(job));
    }

    function addWorker(address to, address workerAddress)
        external
    {
        require(
            hasRole(RoleLib.MANAGER_ROLE, msg.sender) ||
                hasRole(RoleLib.CLIENT_ROLE, msg.sender),
            "509"
        );

        if(hasRole(RoleLib.CLIENT_ROLE, msg.sender)){
      //TODO: test this require condition!
        require(!state.clients[msg.sender].disabled,"Disabled client cannot add worker");

        }
  
        if (hasRole(RoleLib.CLIENT_ROLE, msg.sender)) {
            state.assignWorker(
                to,
                workerAddress,
                RoleLib.CLIENT_ROLE,
                msg.sender
            );
        } else {
            state.assignWorker(
                to,
                workerAddress,
                RoleLib.MANAGER_ROLE,
                msg.sender
            );
        }
    }

    function registerWorker(
        string calldata _metadataUrl,
        address workerAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external returns (Worker memory) {
        require(hasRole(RoleLib.MANAGER_ROLE, workerAddress) == false, "512");
        if (state.managerAddress != msg.sender) {
            require(workerAddress == msg.sender);
        }
        require(state.registrationOpen, "513");
        require(state.workers[msg.sender].initialized == false, "514");

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
        require(hasRole(RoleLib.MANAGER_ROLE, clientAddress) == false, "516");
        if (state.managerAddress != msg.sender) {
            // If it's not the manager sending this transaction then the address has to be the sender
            // It's because a manager can sign up other people.
            require(clientAddress == msg.sender);
        }
        require(state.registrationOpen, "517");
        require(state.clients[msg.sender].initialized == false, "518");
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

    function setFee(uint16 _fee) external onlyRole(RoleLib.MANAGER_ROLE) {
        require(_fee <= 4000,"");
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

    function addWrittenContract(bytes32 contractHash, string memory contractUrl)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.addWrittenContract(contractHash, contractUrl);
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

    function setRegistrationOpen(bool isOpen)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.setRegistrationOpen(isOpen);
    }

    function getWrittenContract(bytes32 contractHash)
        external
        view
        returns (string memory)
    {
        return state.writtenContractUrls[contractHash];
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

    function fee() external view returns (uint16) {
        return state.fee;
    }

    function workers(address _address) external view returns (Worker memory) {
        return state.workers[_address];
    }

    function clientjobs(address _address) external view returns (Job[] memory) {
        return state.clientjobs[_address];
    }

    function workerjobs(address _address) external view returns (Job[] memory) {
        return state.workerjobs[_address];
    }

    function getRegistrationOpen() external view returns (bool) {
        return state.registrationOpen;
    }

    function getManagerAddress() external view returns (address) {
        return state.managerAddress;
    }

    function getVersion() external view returns (uint256) {
        return (state.workSpaceVersion);
    }

    function getAddresses()
        external
        view
        returns (address[] memory, address[] memory)
    {
        return state.getAddresses();
    }

    fallback() external {
        emit FallbackTriggered(msg.sender);
    }
}
