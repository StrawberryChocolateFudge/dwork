// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./WorkSpace.sol";
import "./WorkSpaceFactory.sol";
import "./RoleLib.sol";
import "./JobLib.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./FactoryContractVerifier.sol";
import "./IJob.sol";

// import "hardhat/console.sol";

// The job contains the description of the job and works as a refundable escrow.
// The payment is either refounded or split

contract Job is IJob, AccessControl, Initializable, Multicall {
    event Received(address, uint256);
    event AssignmentAdded(bool ready);
    event AssignmentReady(bool ready);
    event AssignmentAccepted(uint256 date);
    event WorkStarted(uint256 date);
    event WorkDone(uint256 date, uint256 value);
    event DisputeRequested(uint256 date);
    event MetadataUrlChange(string url);
    event Withdraw(
        uint32 assignmentIndex,
        uint256 workerFee,
        uint256 managementFee,
        uint256 usageFee
    );
    event Refund(uint32 assignmentIndex, uint256 amount);
    event DisputeResolved(uint32 assignmentIndex,bool refund);
    using JobLib for JobState;
    JobState state;
    bool locked;
    using FactoryContractVerifier for FactoryContractVerifierState;
    FactoryContractVerifierState verifier;

    function initialize(
        address _workSpaceAddress,
        address _clientAddress,
        address _managerAddress,
        string calldata metadataUrl,
        uint32 version,
        uint16 contractFee,
        uint16 managementFee,
        address dividendsContract
    ) external override initializer() {
        require(verifier.checkFactoryBytecode(msg.sender), "523");
        state.setStateForInit(
            _workSpaceAddress,
            _clientAddress,
            _managerAddress,
            metadataUrl,
            version,
            contractFee,
            managementFee,
            dividendsContract
        );
        _setupRole(RoleLib.CLIENT_ROLE, _clientAddress);
        _setupRole(RoleLib.MANAGER_ROLE, _managerAddress);
        _setupRole(RoleLib.WORKSPACE, _workSpaceAddress);
        _setRoleAdmin(RoleLib.WORKER_ROLE, RoleLib.WORKSPACE);
    }

    function addWorker(address workerAddress)
        external
        override
        onlyRole(RoleLib.WORKSPACE)
        returns (bool)
    {
        require(state.disabled == false, "524");
        state.addWorker(workerAddress);
        _setupRole(RoleLib.WORKER_ROLE, workerAddress);
        //renouce the role of the previous worker if there was one
        if (state.lastAssignee - 1 != 0) {
            revokeRole(
                RoleLib.WORKER_ROLE,
                state.assignee[state.lastAssignee - 1]
            );
        }

        return true;
    }

    function addAssignment(bool ready) external onlyRole(RoleLib.CLIENT_ROLE) {
        state.addAssignment(ready);
        emit AssignmentAdded(ready);
    }

    function markReady() external onlyRole(RoleLib.CLIENT_ROLE) {
        state.markReady();
    }

    function startWork() external onlyRole(RoleLib.WORKER_ROLE) {
        require(address(this).balance >= 1 ether, "525");
        state.startWork();
    }

    function markDone() external onlyRole(RoleLib.WORKER_ROLE) {
        state.markDone(address(this).balance);
    }

    function disputeRequest() external onlyRole(RoleLib.CLIENT_ROLE) {
        require(address(this).balance != 0, "526");
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

    function setmetadataUrl(string memory metadataUrl)
        external
        onlyRole(RoleLib.CLIENT_ROLE)
    {
        state.metadataUrl = metadataUrl;
        emit MetadataUrlChange(metadataUrl);
    }

    function getMetadataUrl() external view returns (string memory) {
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

    function getbalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalBalance() external view returns (uint256) {
        return state.totalBalance;
    }

    function withdraw() external {
        require(
            hasRole(RoleLib.MANAGER_ROLE, msg.sender) ||
                hasRole(RoleLib.WORKER_ROLE, msg.sender),
            "509"
        );
        state.verifyWithdraw(address(this).balance);
        require(locked == false, "531");
        locked = true;

        (uint256 workerFee, uint256 managementFee, uint256 contractFee) =
            state.getFees();

        (bool workerPayedSuccess, ) =
            state.assignee[state.lastAssignee].call{value: workerFee}("");
        require(workerPayedSuccess, "533");
        (bool managerPayedSuccess, ) =
            payable(state.managerAddress).call{value: managementFee}("");
        require(managerPayedSuccess, "534");
        (bool dividendsPayedSuccess, ) =
            payable(state.dividendsContract).call{value: contractFee}("");
        require(dividendsPayedSuccess, "535");

        locked = false;
        emit Withdraw(
            state.lastAssignment,
            workerFee,
            managementFee,
            contractFee
        );
    }

    function refund() external onlyRole(RoleLib.CLIENT_ROLE) {
        require(state.assignments[state.lastAssignment].refundAllowed, "536");
        require(locked == false, "531");
        locked = true;
        //The refund sends all the balance to the client address
        emit Refund(state.lastAssignment, address(this).balance);
        (bool refundSuccess, ) =
            payable(state.clientAddress).call{value: address(this).balance}("");
        require(refundSuccess, "537");
        locked = false;
    }

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

    function kill() external onlyRole(RoleLib.CLIENT_ROLE) {
        // the client can selfdestruct the contract if the state is "Not ready" for workers to start work.
        require(state.assignments[state.lastAssignment].ready == false, "538");
        selfdestruct(payable(state.clientAddress));
    }

    function whoAmI() external view returns (string memory) {
        if (hasRole(RoleLib.MANAGER_ROLE, msg.sender)) {
            return "201";
        } else if (hasRole(RoleLib.CLIENT_ROLE, msg.sender)) {
            return "202";
        } else if (hasRole(RoleLib.WORKER_ROLE, msg.sender)) {
            return "203";
        } else {
            return "204";
        }
    }
}
