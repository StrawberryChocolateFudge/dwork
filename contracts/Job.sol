// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./WorkSpace.sol";
import "./WorkSpaceFactory.sol";
import "./RoleLib.sol";
import "./JobLib.sol";
import "./Initializer.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./FactoryContractVerifier.sol";

// The job contains the description of the job and works as a refundable escrow.
// The payment is either refounded or split

contract Job is AccessControl, Initializable, Multicall {
    event Received(address, uint256);

    using JobLib for JobState;
    JobState state;

    using FactoryContractVerifier for FactoryContractVerifierState;
    FactoryContractVerifierState verifier;

    function initialize(address _workSpaceAddress, address _clientAddress,string calldata metadataUrl,uint32 version)
        external
        initializer()
    {
        require(
            verifier.checkFactoryBytecode(msg.sender),
            "The caller is not a workspace"
        );

        state.workspaceAddress = _workSpaceAddress;
        state.clientAddress = _clientAddress;
        state.created = block.timestamp;
        state.disabled = false;
        state.factoryAddress = msg.sender;
        state.metadataUrl = metadataUrl;
        state.version = version;
        WorkSpace workSpc = WorkSpace(_workSpaceAddress);
        address _managerAddress = workSpc.getManagerAddress();
        _setupRole(RoleLib.CLIENT_ROLE, _clientAddress);
        _setupRole(RoleLib.MANAGER_ROLE, _managerAddress);
        _setupRole(RoleLib.WORKSPACE, _workSpaceAddress);
    }

    function addWorker(
        address workerAddress) external onlyRole(RoleLib.WORKSPACE) returns (bool) {
        require(state.disabled == false, "The job is disabled");
        state.addWorker(workerAddress);
        return true;
    }

    // function createAssignment(
    //     address[] memory assignees_,
    //     uint256[] memory shares_,
    //     string memory metadataUrl_
    // ) external {
    //     //  TODO/: TEST:
    //     //Locks!
    //     //  state.createAssignment(assignees_, shares_, metadataUrl_);
    // }

    function getClient() external view returns (address) {
        return state.clientAddress;
    }
    function getWorker() external view returns (address){
        return state.assignee[state.lastAssignee];
    }

    function getVersion() external view returns (uint32){
        return state.version;
    }
    //TODO: test recieving ether
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    //TODO: this contract must call the workspace often for evaluating if the workers or clients are disabled or not

    //function fundJob() external payable onlyRole(CLIENT_ROLE) {
    // This should be used to fund the job, if the job is not reusable, this should throw after calling it once
    //}

    //TODO: most interactions with this contract should be throught the workspace
    // so no direct access with roles, only the workspace role can access it
    // except for public methods

    // // Client can cancel the job, disabling it, refunding the tokens.
    // // If the job has already been assigned, the canceling requires the managers signature also
    // function cancelJobForClient() external onlyRole(CLIENT_ROLE) {}

    // // The manager can assign a client to the worker who can access the jobs this way
    // function assingToClient() external onlyRole(MANAGER_ROLE) {}

    // // The manager can remove a worker from a client, if the worker has jobs in progress, they will now get canceled.
    // function removeFromClient() external onlyRole(MANAGER_ROLE) {}

    // //The worker can take a job, his address is placed in the assignedTo field
    // // TODO calls to this are delegated to the workspace contract

    // function takeJob() external onlyRole(WORKER_ROLE) {}

    // // The worker can mark a job finished, claming the reward.
    // function finishJob() external onlyRole(WORKER_ROLE) {}

    // // The a client can accept the finished job
    // function acceptFinishedJob() external onlyRole(CLIENT_ROLE) {}

    // // The worker can cancel the job without any penalties
    // function cancelJobForWorker() external onlyRole(WORKER_ROLE) {}

    // // The manager can to approve the cancelation
    // function approveCancel() external onlyRole(MANAGER_ROLE) {}

    // function kill()external {
    //    // require that msg sender has a role manager and client
    // }
}
