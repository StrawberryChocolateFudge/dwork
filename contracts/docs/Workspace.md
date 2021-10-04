# Workspace

## Description

The workspace  contract is used for matching client and worker roles by a manager.
This is a Recruiter based freelance work platform.

The creator of the contract is the manager.

## Events
`event RegistrationSuccess(bytes32 role, address registeredAddress);`

`event Moderated(address, bytes32, bool);`

`event JobCreated(address);`

`event FallbackTriggered(address);`

`event AddedWorker(address to, address worker);`


## Public Api


`createJob(string calldata _metadataUrl, address client) external override`

This function has to be called by the manager or the client.
It will deploy a Job contract for a specific client. 
The Job can have metadata for storing an external link.

`addWorker(address to, address workerAddress) external override`

This is called by the manager or the client and will assign a worker to the job contract created previously

`registerWorker(
	string calldata _metadataUrl,
        address workerAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external returns (Worker memory)`

A worker can be registered to the workspace by the manager or by himself if the registrations are open.
If invite is required, the token must be passed.
The  _writtenContractHash is to track what agreement the worker signed externally


`registerClient(
        string calldata _metadataUrl,
        address clientAddress,
        string calldata inviteToken,
        bytes32 _writtenContractHash
    ) external returns (Client memory)`

The client can be registered by the manager or by himslef.
The metadata is for an external URL,
the invite token is needed if invites are set to required
the  _writtenContractHash field is to track what agreement the client signed 


`moderateTarget(
        address moderatedAddress,
        bytes32 target,
        bool setTo
    ) external onlyRole(RoleLib.MANAGER_ROLE) returns (bool)`

The manager may choose to moderate an address.
Target is an enum RoleLib.WorkerRole or RoleLib.ClientRole
setTo will set it to active or inactive

`setFee(uint16 _fee) external onlyRole(RoleLib.MANAGER_ROLE)`

The manager can set the fee he charges

`setMetadata(string calldata _metadataUrl)
        external
        onlyRole(RoleLib.MANAGER_ROLE)`

The manager may set the metadata of the workspace anytime

`addWrittenContract(bytes32 contractHash, string memory contractUrl)`
The url of a written agreement can be passed in along with it's hash

`setCurrentWorkerContractHash(bytes32 newHash)
        external
        onlyRole(RoleLib.MANAGER_ROLE)`

Set what written contract is offered to the worker automaticly

`setCurrentClientContractHash(bytes32 newHash)
        external
        onlyRole(RoleLib.MANAGER_ROLE)`

Set what written contract is offered to the clients on registration

`addInviteToken(string calldata inviteToken)
        external
        onlyRole(RoleLib.MANAGER_ROLE)`

Add an invite token to use for invites, if this is used, only the people with the token can sign up

`noInvites() external onlyRole(RoleLib.MANAGER_ROLE)`

The manager may cancel invite tokens

`setRegistrationOpen(bool isOpen)
        external
        onlyRole(RoleLib.MANAGER_ROLE)`

The manager can decide if the registrations are on or off.

`getWrittenContract(bytes32 contractHash)
        external
        view
        returns (string memory)`

Get the url of the written contract by it's hash



## Public View Functions
`function whoAmI() external view returns (uint256)`

Returns an int representing the role

`metadataUrl() external view returns (string memory)`

returns the url of the metadata

`requireInvite() external view returns (bool)`

return if the registrations require invite

`currentWorkerContractHash() external view returns (bytes32)`

returns the hash of the contract currently offered to workers

`currentClientContractHash() external view returns (bytes32)`

returns the hash of the current client contract hash

`clients(address _address) external view returns (Client memory)`

returns a client by address

`workers(address _address) external view returns (Worker memory)`

returns a worker by address

`fee() external view returns (uint16)`

returns the fee set by the manager

`clientjobs(address _address) external view returns (Job[] memory)`

returns the addresses of job contracts a client possesses

`workerjobs(address _address) external view returns (Job[] memory)`

returns the address of the jobs a worker has

`getRegistrationOpen() external view returns (bool)`

call this to find out if registrations are open or not

`getManagerAddress() external view returns (address)`

get the address of the manager

`getVersion() external view returns (uint256)`

get the version of the current workspace contract

`getAddresses() external view returns (address[] memory, address[] memory)`

Gets all the addresses of workers and clients, returned in the order of (self.workerAddresses, self.clientAddresses)



## called by another contract
This below function is called by the factory on initialization;

`initialize(
        uint16 _fee,
        string memory _metadataUrl,
        address _manager,
        uint256 workSpaceVersion
    ) external override initializer()`

