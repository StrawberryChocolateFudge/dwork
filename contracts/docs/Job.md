# Job

## Description

The job contract is a managed escrow deployed for a specific address with a client role from the workspace.
A job contract can host one escrow at once with a single worker.

## Events
`event Received(address, uint256);`
 This event is emitted when ether was transferred to this contract

 The below events are easy to guess when they are emitted from their names.
`event AssignmentAdded(bool ready);`

`event AssignmentReady(bool ready);`

`event AssignmentAccepted(uint256 date);`

`event WorkStarted(uint256 date);`

`event WorkDone(uint256 date, uint256 value);`

`event DisputeRequested(uint256 date);`

`event MetadataUrlChange(string url);`

`event Withdraw(
        uint32 assignmentIndex,
        uint256 workerFee,
        uint256 managementFee,
        uint256 usageFee
    );`
`event Refund(uint32 assignmentIndex, uint256 amount);`
`event DisputeResolved(uint32 assignmentIndex, bool refund);`

## Public Api

`addAssignment(bool ready) external onlyRole(RoleLib.CLIENT_ROLE)`
 
 Initializes a new assignment. if the ready argument is true, the assignemnt is ready for workers to start work on.

 `markReady() external onlyRole(RoleLib.CLIENT_ROLE)`

 The client may mark the assignment ready if it was not before

 `startWork() external onlyRole(RoleLib.WORKER_ROLE)`
 The worker can call this to start work.
 It's only possible to start work on a job if it contains at least 1 eth.

 `markDone() external onlyRole(RoleLib.WORKER_ROLE)`
 The worker can mark the job done

 `disputeRequest() external onlyRole(RoleLib.CLIENT_ROLE)`

 The client may request a dispute if he's not satisfied with the job.

 `resolveDispute(bool refundAllowed)
        external
        onlyRole(RoleLib.MANAGER_ROLE)`
  
  The manager may resolve the dispute and can allow refund

  `markAccepted() external onlyRole(RoleLib.CLIENT_ROLE)`
  If the job was done, the client may accept it.
  Accepted contracts will get payed out,

  `refund() external onlyRole(RoleLib.CLIENT_ROLE)`
  if refund is allowed the client can get his money back

  `withdraw() external`
   Withdraw can be called by the manager and the worker and will transfer the workers, the managers and the dividends fees.



 ## View functions
 `getMetadataUrl() external view returns (string memory)`
  Returns the metadata url of the job

 `getClient() external view returns (address)`
  Returns the address of the client

 `getWorker() external view returns (address)`
  Returns the address of the worker
 
 `getVersion() external view returns (uint32)`
  Returns the version of the job contract software

 `getbalance() external view returns (uint256)`
  Returns the balance of the job contract ready for the withdraw or refund

  `getTotalBalance() external view returns (uint256)`
  Returns the total balance processed by the Job contract

  `whoAmI() external view returns (string memory)` 
  Returns your role in a string code

  `kill() external onlyRole(RoleLib.CLIENT_ROLE)`
  The contract is payable so the client can kill it to recover his money

  `receive() external payable`
  The function to recieve ETH and track total balance


## Called by another contract
The below function is called on initialization when it's created automaticly.

`initialize(
        address _workSpaceAddress,
        address _clientAddress,
        address _managerAddress,
        string calldata metadataUrl,
        uint32 version,
        uint16 contractFee,
        uint16 managementFee,
        address dividendsContract
    ) external override initializer()`

`addWorker(address workerAddress)
        external
        override
        onlyRole(RoleLib.WORKSPACE)`

AddWorker is called by the workspace.

