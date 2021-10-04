# Workspace factory

## Description

The workspace factory contract is used to safely deploy `workspace` and `job` smart contracts.

## Events

`event WorkSpaceCreated( address creator, address contractAddress, string metadata );`
`event FallbackTriggered(address sender);`
`event JobLibraryVersion(uint256);`
`event WorkSpaceLibraryVersion(uint256);`
`event DividendsLibraryVersion(uint256);`
`event ContractFeeChange(uint16);`

## Public Api

`createWorkSpace(uint16 _fee, string memory _metadata) external returns (address)`

Call this function with the fee and the metadata of the workspace you wish to create.
All the roles are able to use this.

## Public View Functions

`addressIsNew(address _address) external view returns (bool)`

Returns true if the address has a workspace already

`getContractAddress(address _address) external view returns (address)`

Gets a workspace contracts by address.

`amountOfWorkSpaces() external view returns (uint32)`

Returns how many workspaces were created

`getContractFee() external view returns (uint16)`

Returns the fee of using the platform

`getWorkSpaceLibrary() external view returns (address)`

Returns the address of the library to clone for the workspace

`getJobLibraryAddress() external view returns (address)`

Returns the address of the Job contract to clone for the workspace

`getBoardAddress() external view returns (address)`

Returns the address of the board contract

`getCurrentWorkspaceIndex(address _manager) external view returns (uint256)`

Internally, storage is indexed, you can get the workspace Index to use with getHistoricWorkspace

`getHistoricWorkspace(uint32 idx, address _manager) external view returns (address)`

Use this function with the above one to get the latest workspace rand by the manager.

`getCurrentJobLibraryVersion() external view returns (uint32)`

You can get the version of the latest job contract.

## Api called by other contract

`createJob( address _clientAddress, address _managerAddress, string calldata metadataUrl, uint16 managementFee ) external onlyRole(RoleLib.WORKSPACE) returns (address)`

This function is called by the workspace to create the escrow contract.

`setContractFee(uint16 _newFee) external `

You can set the usage fees, only the board can call this after voting.

## Called only by the owner

`setDisabled(bool _disabled) external onlyOwner`

Disable the factory.

`setBoardAddress(address to) external onlyOwner`

Disable the board address.

`setWorkSpaceLibrary(address _address) external onlyOwner`

The owner can set what contract is cloned by the factory.

`setJobLibraryAddress(address _address) external onlyOwner`

The owner can set the Job's contract address for upgrade path

`setDividendsLibraryAddress(address _address) external onlyOwner`

The dividends contract address can be set for upgrading.
