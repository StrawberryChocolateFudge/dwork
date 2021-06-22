// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
import "hardhat/console.sol";

struct JobState {
    address factoryAddress; // The address of the factory,to get the fees
    address workspaceAddress; // The address of the workspace that created the job
    //to get fees and manager address
    address clientAddress; // the address of the client
    address dividendsContract;
    address managerAddress;
    uint256 created;
    bool disabled;
    //There is only one assignment active at a time, the last
    mapping(uint32 => Assignment) assignments;
    uint32 lastAssignment;
    mapping(uint32 => address payable) assignee; // this is like snapshots of assignee data accessed with a hashs
    uint32 lastAssignee;
    string metadataUrl;
    uint32 version;
    uint256 totalBalance;
    uint16 managementFee;
    uint16 contractFee;
}

struct Assignment {
    uint256 created;
    bool initialized; // check if the assignment exists with this
    bool ready; //Ready means work can start, if this is false self destruct is available
    bool startedWork; // marked by the worker, if work started the client or manager cannot add a new worker
    bool done; // done is marked by the worker when he is finished
    uint256 finalPrice; //The final amount that is payed out, determined when the job is DONE
    bool accepted; // marked by the client or the manager depending if there was a dispute and what was the result, when this is true, withdrawals can start to the worker
    bool disputeRequested; //can be requested by the client to ask the manager to help him withdrawz his funds
    bool refundAllowed; //It can be refunded if the client requests a dispute
    uint256 workerPayed; // The amount that was payed to the worker
    uint256 managerPayed; // The amount that was payed to the manager
    uint256 feePayed; // The amount that was payed to the dividends contract
    uint256 refundPayed; // IF THE REFUND IS ALLOWED
}

library JobLib {
    event AssignmentAdded(bool ready);
    event AssignmentReady(bool ready);
    event WorkStarted(uint256 date);
    event DisputeRequested(uint256 date);
    event AssignmentAccepted(uint256 date);
    event WorkDone(uint256 date, uint256 value);

    uint16 constant feeBase = 10000;

    function setStateForInit(
        JobState storage self,
        address _workSpaceAddress,
        address _clientAddress,
        address _managerAddress,
        string calldata metadataUrl,
        uint32 version,
        uint16 contractFee,
        uint16 managementFee,
        address dividendsContract
    ) external {
        self.workspaceAddress = _workSpaceAddress;
        self.clientAddress = _clientAddress;
        self.created = block.timestamp;
        self.disabled = false;
        self.factoryAddress = msg.sender;
        self.metadataUrl = metadataUrl;
        self.version = version;
        self.managementFee = managementFee;
        self.contractFee = contractFee;
        self.managerAddress = _managerAddress;
        self.dividendsContract = dividendsContract;
    }

    function addWorker(JobState storage self, address worker)
        external
        returns (bool)
    {
        require(worker != address(0), "511");
        require(
            self.assignments[self.lastAssignment].startedWork == false,
            "539"
        );
        self.lastAssignee++;
        self.assignee[self.lastAssignee] = payable(worker);
        return true;
    }

    function validatePayouts(JobState storage self, bool refundAllowed)
        internal
        view
        returns (bool)
    {
        if (refundAllowed) {
            return true;
        }
        return
            self.assignments[self.lastAssignment].workerPayed > 0 &&
            self.assignments[self.lastAssignment].managerPayed > 0 &&
            self.assignments[self.lastAssignment].feePayed > 0;
    }

    function addAssignment(JobState storage self, bool ready) external {
        if (self.assignments[self.lastAssignment].initialized) {
            require(
                validatePayouts(
                    self,
                    self.assignments[self.lastAssignment].refundAllowed
                ),
                "540"
            );
            // If the assignment is refunded, the client can decide to not withdraw his money,
            // he can instead create a new assignment and use the funds for that.
            // he can assign a new worker if the new assignment is submitted as not ready.
        }
        self.lastAssignment++;
        self.assignments[self.lastAssignment] = Assignment({
            created: block.timestamp,
            initialized: true,
            ready: ready,
            startedWork: false,
            done: false,
            finalPrice: 0,
            disputeRequested: false,
            accepted: false,
            refundAllowed: false,
            workerPayed: 0,
            managerPayed: 0,
            feePayed: 0,
            refundPayed: 0
        });
    }

    function markReady(JobState storage self) external {
        require(self.assignments[self.lastAssignment].initialized, "541");

        require(self.assignments[self.lastAssignment].ready == false, "542");
        self.assignments[self.lastAssignment].ready = true;
        emit AssignmentReady(true);
    }

    function startWork(JobState storage self) external {
        require(self.assignments[self.lastAssignment].initialized, "543");
        require(self.assignments[self.lastAssignment].ready, "544");
        require(
            self.assignments[self.lastAssignment].startedWork == false,
            "545"
        );
        self.assignments[self.lastAssignment].startedWork = true;
        emit WorkStarted(block.timestamp);
    }

    function markDone(JobState storage self, uint256 balance) external {
        require(self.assignments[self.lastAssignment].startedWork, "546");
        self.assignments[self.lastAssignment].done = true;
        self.assignments[self.lastAssignment].finalPrice = balance;
        emit WorkDone(
            block.timestamp,
            self.assignments[self.lastAssignment].finalPrice
        );
    }

    function disputeRequested(JobState storage self) external {
        self.assignments[self.lastAssignment].disputeRequested = true;
        emit DisputeRequested(block.timestamp);
    }

    function resolveDispute(JobState storage self, bool refundAllowed)
        external
    {
        require(self.assignments[self.lastAssignment].disputeRequested, "547");
        //The manager can turn off the dispute and decide to allow refund or not
        //if the refund is allowed, the dispute state persists
        self.assignments[self.lastAssignment].disputeRequested = refundAllowed;
        self.assignments[self.lastAssignment].refundAllowed = refundAllowed;
    }

    function markAccepted(JobState storage self) external {
        require(self.assignments[self.lastAssignment].done, "548");
        self.assignments[self.lastAssignment].accepted = true;
        emit AssignmentAccepted(block.timestamp);
    }

    function verifyWithdraw(JobState storage self, uint256 balance) external view {
        require(
            balance >=
                self.assignments[self.lastAssignment].finalPrice,
            "527"
        );
        require(
            !iszero(self.assignments[self.lastAssignment].finalPrice),
            "528"
        );
        require(
            iszero(self.assignments[self.lastAssignment].workerPayed),
            "529"
        );
        require(self.assignments[self.lastAssignment].accepted, "530");
    }

   function iszero(uint256 value) internal pure returns (bool) {
        return value == 0;
    }

    function getFees(JobState storage self) external returns (uint256,uint256,uint256){
         // factory fee can be max 1000, which is 10%
        // management fee can be max 4000, which is 40%
        //fee base is 10.000 which is the 100%
        //The worker cannot get less than 50%

        uint256 contractFee = getActualContractFee(self);
        uint256 managementFee = getActualManagementFee(self);
        uint256 workerFee =
            self.assignments[self.lastAssignment].finalPrice -
                contractFee -
                managementFee;
        require(
            contractFee + managementFee + workerFee ==
                self.assignments[self.lastAssignment].finalPrice,
            "532"
        );
        self.assignments[self.lastAssignment].workerPayed = workerFee;
        self.assignments[self.lastAssignment].managerPayed = managementFee;
        self.assignments[self.lastAssignment].feePayed = contractFee;


       return (workerFee,managementFee,contractFee);
    }

        function getActualContractFee(JobState storage self) internal view returns (uint256) {
        return ((self.assignments[self.lastAssignment].finalPrice *
            uint256(self.contractFee)) / uint256(JobLib.feeBase));
    }

    function getActualManagementFee(JobState storage self) internal view returns (uint256) {
        return ((self.assignments[self.lastAssignment].finalPrice *
            uint256(self.managementFee)) / uint256(JobLib.feeBase));
    }



}
