// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

struct JobState {
    address factoryAddress; // The address of the factory,to get the fees
    address workspaceAddress; // The address of the workspace that created the job
    //to get fees and manager address
    address clientAddress; // the address of the client
    uint256 created;
    bool disabled;
  
    //There is only one assignment active at a time, the last
    mapping(uint256 => Assignment) assignments;
    uint256 lastAssignment;
    mapping(uint256 => address payable) assignee; // this is like snapshots of assignee data accessed with a hashs
    uint256 lastAssignee;
    string metadataUrl;
}

struct Assignment {
    uint256 created;
    bool initialized; // check if the assignment exists with this
    bool startedWork; // marked by the worker, if work started the client or manager cannot add a new worker
    bool done; // done is marked by the worker
    bool disputeRequested; //can be requested by the client to ask the manager to help him withdraw
    bool accepted; // marked by the client or the manager depending if there was and the result of the dispute
    uint payed; // The amount that was payed
}

library JobLib {
    event AssigneeAdded(address _address, uint256 _share);
    uint256 public constant totalShares = 1000000;


    function addWorker(JobState storage self, address worker)
        external
        returns (bool)
    {
        require(worker != address(0), "worker is the zero address");
        //TODO Test triggering the bellow require
        require(self.assignments[self.lastAssignment].startedWork == false,"Cannot assign new worker if work has started");
        self.lastAssignee++;
        self.assignee[self.lastAssignee] = payable(worker);
        return true;
    }




    // Assignment memory _assignment = Assignment({
    //     created: block.timestamp,
    //     initialized : true,
    //     done: false,
    //     disputeRequested : false,
    //     accepted : false
    //     });

    // You can create an assignment without any asssignees

    // if(assignees_.length > 0){
    //   for (uint256 i = 0; i < assignees_.length;i++){
    //    require(share_[i] <= totalShares,"invalid share can be max 1 million");
    //    allSentShares += share_[i];
    //    Assignee memory createdAssignee = _createAssignee(assignees_[i],share_[i]);
    //    bytes32 hashedAssignee = keccak256(abi.encodePacked(self.round,createdAssignee.assigneeAddress));

    //    _assignment.assigneeHashes[i] = hashedAssignee;
    //    self.assignees[hashedAssignee] = createdAssignee;

    //    emit AssigneeAdded(assignees_[i],share_[i]);

    //   }
    //aa  }

    //    require(allSentShares <= totalShares,"the assignees have too many shares");
    //    self.assignments[self.round] = _assignment;
    // }
}
