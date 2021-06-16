// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;


struct JobState{
    address factoryAddress; // The address of the factory,to get the fees
    address workspaceAddress; // The address of the workspace that created the job
    //to get fees and manager address
    address clientAddress; // the address of the client
    uint256  created;
    bool disabled;
    uint round; // current round,  this is the key to the last assignment
    //it means when you finish its not disabled and you can reuse for monthly salaries for example

    mapping(uint =>Assignment) assignments;
    mapping(bytes32 => Assignee) assignees; // this is like snapshots of assignee data accessed with a hashs

}

struct Assignment{
    uint256 created;
    uint256 totalAssignees;
    uint256 reward;
    string metadataUrl;
    bool done;
    bool initialized;
    bytes32[] assigneeHashes;
}    
struct Assignee {
        address payable assigneeAddress;
        bool finished;
        string proofUrl;
        uint256 share;
    }


library JobLib{
    event AssigneeAdded(address _address,uint256 _share);
    uint256 constant public totalShares = 1000000; 



    function createAssignment(
        JobState storage self,
        address[] memory assignees_,
        uint256[] memory share_,
        uint256 reward_,
        string memory metadataUrl_) external {
        require(assignees_.length == share_.length, "Assignees and shares length mismatch.");
        require(self.disabled == false, "The job is disabled");
        if(self.assignments[0].initialized){
            // If the assignment at zero index is initialized, 
            // then this is not the first assignment so I can increase the round; 
            // this should trigger every time except if this is the first job
            self.round++;
        }
        uint256 allSentShares = 0;    

        Assignment memory _assignment = Assignment({
            created: block.timestamp,
            totalAssignees :assignees_.length,
            reward: reward_,
            metadataUrl: metadataUrl_,
            done: false,
            initialized : true,
            assigneeHashes : new bytes32[](assignees_.length)
            });
        
        // You can create an assignment without any asssignees
        if(assignees_.length > 0){
          for (uint256 i = 0; i < assignees_.length;i++){
           require(share_[i] <= totalShares,"invalid share can be max 1 million");
           allSentShares += share_[i];
           Assignee memory createdAssignee = _createAssignee(assignees_[i],share_[i]);
           bytes32 hashedAssignee = keccak256(abi.encodePacked(self.round,createdAssignee.assigneeAddress));
           
           _assignment.assigneeHashes[i] = hashedAssignee;
           self.assignees[hashedAssignee] = createdAssignee;
           
           emit AssigneeAdded(assignees_[i],share_[i]);

          }
        }
   
       require(allSentShares <= totalShares,"the assignees have too many shares");
       self.assignments[self.round] = _assignment;       
    }

    function _createAssignee(address _address,uint256 share_) private pure returns (Assignee memory) {
        require(_address != address(0), "address is the zero address");
        return Assignee(payable(_address),false,"",share_);
    }

   

}