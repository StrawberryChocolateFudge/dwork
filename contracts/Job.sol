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
        state.managementFee = managementFee;
        state.contractFee = contractFee;
        state.managerAddress = _managerAddress;
        state.dividendsContract = dividendsContract;
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
        require(state.disabled == false, "The job is disabled");
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
        require(address(this).balance >= 1 ether, "Minimum balance is 1 ether");
        state.startWork();
    }

    function markDone() external onlyRole(RoleLib.WORKER_ROLE) {
        state.markDone();
        state.assignments[state.lastAssignment].finalPrice = address(this)
            .balance;
        emit WorkDone(
            block.timestamp,
            state.assignments[state.lastAssignment].finalPrice
        );
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
        require(
            address(this).balance >=
                state.assignments[state.lastAssignment].finalPrice,
            "Insufficient balance in contract"
        );
        require(
            !iszero(state.assignments[state.lastAssignment].finalPrice),
            "The final price must not be zero to withdraw funds"
        );
        require(
            iszero(state.assignments[state.lastAssignment].workerPayed),
            "Already got payed"
        );
        require(
            state.assignments[state.lastAssignment].accepted,
            "You are not permitted to withdraw funds"
        );
        require(locked == false, "Not allowed");
        locked = true;
        // factory fee can be max 1000, which is 10%
        // management fee can be max 4000, which is 40%
        //fee base is 10.000 which is the 100%
        //The worker cannot get less than 50%
        
        uint256 contractFee = getActualContractFee();
        uint256 managementFee = getActualManagementFee();
        uint256 workerFee =
            state.assignments[state.lastAssignment].finalPrice -
                contractFee -
                managementFee;
        require(
            contractFee + managementFee + workerFee ==
                state.assignments[state.lastAssignment].finalPrice,
            "oh noes the calculation went wrong"
        );
        state.assignments[state.lastAssignment].workerPayed = workerFee;
        state.assignments[state.lastAssignment].managerPayed = managementFee;
        state.assignments[state.lastAssignment].feePayed = contractFee;        

        (bool workerPayedSuccess, ) =
            state.assignee[state.lastAssignee].call{value: workerFee}("");
        require(
            workerPayedSuccess,
            "Unable to send value to worker, recipient may have reverted"
        );
        (bool managerPayedSuccess, ) =
            payable(state.managerAddress).call{value: managementFee}("");
        require(
            managerPayedSuccess,
            "Unable to send value manager, recipient may have reverted"
        );
        (bool dividendsPayedSuccess, ) =
            payable(state.dividendsContract).call{value: contractFee}("");
        require(
            dividendsPayedSuccess,
            "Unable to send value dividends, recipient may have reverted"
        );
       

        locked = false;
        emit Withdraw(
            state.lastAssignment,
            workerFee,
            managementFee,
            contractFee
        );
    }

    function refund() external onlyRole(RoleLib.CLIENT_ROLE) {
        require(
            state.assignments[state.lastAssignment].refundAllowed,
            "Refund is not allowed"
        );
        require(locked == false, "Not allowed");
        locked = true;
        //The refund sends all the balance to the client address
        (bool refundSuccess, ) =
            payable(state.clientAddress).call{value: address(this).balance}("");
        require(
            refundSuccess,
            "Unable to refund the value, recipient may have reverted"
        );
        locked = false;
    }

    function getActualContractFee() internal view returns (uint256) {
        return ((state.assignments[state.lastAssignment].finalPrice *
            uint256(state.contractFee)) / uint256(JobLib.feeBase));
    }

    function getActualManagementFee() internal view returns (uint256) {
        return ((state.assignments[state.lastAssignment].finalPrice *
            uint256(state.managementFee)) / uint256(JobLib.feeBase));
    }

    function iszero(uint256 value) internal pure returns (bool) {
        return value == 0;
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
        // the client can selfdestruct the contract if the state is "Not ready" for workers to work'.
        require(
            state.assignments[state.lastAssignment].ready != false,
            "The last assignment must not be active"
        );
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
