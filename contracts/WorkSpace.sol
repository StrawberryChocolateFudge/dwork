// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Job.sol";
import "./RoleLib.sol";
import "./WorkSpaceLib.sol";
import "./CloneFactory.sol";
import "./WorkSpaceFactory.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./FactoryContractVerifier.sol";
import "./IWorkSpace.sol";
import "hardhat/console.sol";

contract WorkSpace is
    IWorkSpace,
    AccessControl,
    CloneFactory,
    Initializable,
    Multicall
{
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
    ) external override initializer() {
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

    function createJob(string calldata _metadataUrl)
        external
        override
        onlyRole(RoleLib.CLIENT_ROLE)
    {
        //TODO: maybe if the manager creates the jobs only, that is better ux
        state.verifyCreateJob(msg.sender);
        Job job =
            Job(
                payable(
                    WorkSpaceFactory(state.factoryAddress).createJob(
                        msg.sender,
                        state.managerAddress,
                        _metadataUrl,
                        state.fee
                    )
                )
            );
        state.clientjobs[msg.sender].push(job);
        emit JobCreated(address(job));
    }

    function addWorker(address to, address workerAddress) external override {
        require(to != address(0), "500");
        require(workerAddress != address(0), "500");
        require(
            hasRole(RoleLib.MANAGER_ROLE, msg.sender) ||
                hasRole(RoleLib.CLIENT_ROLE, msg.sender),
            "509"
        );

        if (hasRole(RoleLib.CLIENT_ROLE, msg.sender)) {
            require(!state.clients[msg.sender].disabled, "522");
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
        state.verifyRegisterWorker(msg.sender, workerAddress);
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
        state.verifyRegisterClient(msg.sender, clientAddress);
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
        require(moderatedAddress != address(0),"500");
        return state.moderateTarget(moderatedAddress, target, setTo);
    }

    function setFee(uint16 _fee) external onlyRole(RoleLib.MANAGER_ROLE) {
        state.setFee(_fee);
    }

    function setMetadata(string calldata _metadataUrl)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.setMetadata(_metadataUrl);
    }

    function whoAmI() external view returns (uint256) {
        if (hasRole(RoleLib.MANAGER_ROLE, msg.sender)) {
            return 201;
        } else if (hasRole(RoleLib.CLIENT_ROLE, msg.sender)) {
            return 202;
        } else if (hasRole(RoleLib.WORKER_ROLE, msg.sender)) {
            return 203;
        } else {
            return 204;
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
