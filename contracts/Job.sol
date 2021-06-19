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
import "hardhat/console.sol";

// The job contains the description of the job and works as a refundable escrow.
// The payment is either refounded or split

contract Job is AccessControl, Initializable, Multicall {
    event Received(address, uint256);
    event AssignmentAdded(bool ready);
    event AssignmentReady(bool ready);
    event AssignmentAccepted(uint256 date);
    event WorkStarted(uint256 date);
    event WorkDone(uint256 date);
    event DisputeRequested(uint256 date);
    event MetadataUrlChange(string url);
    using JobLib for JobState;
    JobState state;

    using FactoryContractVerifier for FactoryContractVerifierState;
    FactoryContractVerifierState verifier;
    function initialize(
        address _workSpaceAddress,
        address _clientAddress,
        string calldata metadataUrl,
        uint32 version,
        uint8 contractFee,
        address dividendsContract
    ) external initializer() {
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
        state.managementFee = workSpc.fee();
        state.contractFee = contractFee;
        state.dividendsContract = dividendsContract;
        _setupRole(RoleLib.CLIENT_ROLE, _clientAddress);
        _setupRole(RoleLib.MANAGER_ROLE, _managerAddress);
        _setupRole(RoleLib.WORKSPACE, _workSpaceAddress);
        _setRoleAdmin(RoleLib.WORKER_ROLE, RoleLib.WORKSPACE);
    }

    function addWorker(address workerAddress)
        external
        onlyRole(RoleLib.WORKSPACE)
        returns (bool)
    {
        require(state.disabled == false, "The job is disabled");
        state.addWorker(workerAddress);
        _setupRole(RoleLib.WORKER_ROLE, workerAddress);
        console.log("wortker is getting added");
        //renouce the role of the previous worker if there was one
        if (state.lastAssignee - 1 != 0) {
            //TODO: Test this role revoking!
            revokeRole(
                RoleLib.WORKER_ROLE,
                state.assignee[state.lastAssignee - 1]
            );
        }

        return true;
    }

    function addAssignment(bool ready) external onlyRole(RoleLib.CLIENT_ROLE) {
        state.addAssignment(ready);
    }

    function markReady() external onlyRole(RoleLib.CLIENT_ROLE) {
        state.markReady();
    }

    function startWork() external onlyRole(RoleLib.WORKER_ROLE) {
        state.startWork();
    }

    function markDone() external onlyRole(RoleLib.WORKER_ROLE) {
        state.markDone();
        state.assignments[state.lastAssignment].finalPrice = address(this).balance;
    }

    function disputeRequested() external onlyRole(RoleLib.CLIENT_ROLE) {
        require(
            address(this).balance != 0,
            "No need for dispute if there is no balance"
        );
        state.disputeRequested();
    }
    
    function resolveDispute(bool refundAllowed)
        external
        onlyRole(RoleLib.MANAGER_ROLE)
    {
        state.resolveDispute(refundAllowed);
    }

    function markAccepted() external onlyRole(RoleLib.CLIENT_ROLE) {
        state.markAccepted();
    }

    function setmetadataUrl(string memory metadataUrl) external onlyRole(RoleLib.CLIENT_ROLE) {
        state.metadataUrl = metadataUrl;
        emit MetadataUrlChange(metadataUrl);
    }

    function getMetadataUrl() external view returns (string memory){
        return state.metadataUrl;
    }

    function getClient() external view returns (address) {
        return state.clientAddress;
    }

    function getWorker() external view returns (address) {
        return state.assignee[state.lastAssignee];
    }

    function getVersion() external view returns (uint32) {
        return state.version;
    }
    function getbalance() external view returns(uint256){
        return address(this).balance;
    }
    function getTotalBalance() external view returns (uint256){
        return state.totalBalance;
    }


    //TODO: Withdraw funtions


    //TODO: test recieving ether
    receive() external payable {
        if (msg.value > 0) {
            state.totalBalance += msg.value;
        }
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        if (msg.value > 0) {
            state.totalBalance += msg.value;
        }
        emit Received(msg.sender, msg.value);
    }

   function kill() external onlyRole(RoleLib.CLIENT_ROLE){
       // the client can selfdestruct the contract if the state is "Not ready" for workers to work'.
       require(state.assignments[state.lastAssignment].ready != false,"The last assignment must not be active");
       selfdestruct(payable(state.clientAddress));
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
}
