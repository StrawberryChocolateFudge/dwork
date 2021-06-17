// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./WorkSpace.sol";
import "./RoleLib.sol";
import "./WorkSpaceFactoryLib.sol";
import "./CloneFactory.sol";

// The workspace factory is used to create and track WorkSpaces
contract WorkSpaceFactory is AccessControl, CloneFactory,Multicall {
    using WorkSpaceFactoryLib for FactoryState;
    FactoryState private state;
    mapping(address => bool) private createLocks;

    event WorkSpaceCreated(
        address creator,
        address contractAddress,
        string metadata
    );

    event CreateWorkSpaceFailed(
        address sender
    );

    event FallbackTriggered(
        address sender
    );


    constructor(address _owner) {
        require(_owner != address(0), "500");
        state.owner = _owner;
        _setupRole(RoleLib.ADMIN_ROLE, state.owner);
        state.disabled = false;
        state.contractFee = 0;
        state.jobLibraryVersion = 0;
        state.workSpaceLibraryVersion = 0;
    }

    function createWorkSpace(uint8 _fee, string memory _metadata)
        external
        returns (address)
    {
        //if upgrade is available, allow the creation of multiple workspaces
        //The creator wil laslo pass if this is the first workspace he created
        require(state.checkIfWorkSpaceIsOutdated(msg.sender),"502");


        require(!state.disabled, "501");
        // Locking the create so a user can only create one at a time, no reentrancy
        require(createLocks[msg.sender] == false, "503");
        createLocks[msg.sender] = true;
        uint256 index;

        WorkSpace workSpace = WorkSpace(createClone(state.workSpaceLibraryAddress));

        try workSpace.initialize(
                _fee,
                _metadata,
                msg.sender,
                state.jobLibraryAddress,
                state.workSpaceLibraryVersion,
                state.jobLibraryVersion
            ){
            state.currentIndex[msg.sender] += 1;
            index = state.currentIndex[msg.sender];
            state.workSpaces[msg.sender][index] = address(workSpace);

            state.amountOfWorkSpaces++;
            _setupRole(RoleLib.WORKSPACE,address(workSpace));
            emit WorkSpaceCreated(
                msg.sender,
                state.workSpaces[msg.sender][index],
                _metadata
            );
        } catch {
            // I will release the lock if that call fails and returns a revert, in case it doesn't continue
            emit CreateWorkSpaceFailed(msg.sender);
            createLocks[msg.sender] = false;
        }

        createLocks[msg.sender] = false;

        return state.workSpaces[msg.sender][index];
    }

    function createJob(address _clientAddress) external onlyRole(RoleLib.WORKSPACE) returns (address){
        Job job = Job(payable(createClone(state.jobLibraryAddress)));
        job.initialize(msg.sender,_clientAddress);
        return address(job);
    }

    function setContractFee(int8 _newFee)
        external
        onlyRole(RoleLib.ADMIN_ROLE)
    {
        state.contractFee = uint8(_newFee);
    }

    function setDisabled(bool _disabled) external onlyRole(RoleLib.ADMIN_ROLE) {
        state.disabled = _disabled;
    }

    function setWorkSpaceLibrary(address _address)
        external
        onlyRole(RoleLib.ADMIN_ROLE)
        returns (address)
    {
        return state.setWorkSpaceLibrary(_address);
    }

    function setJobLibraryAddress(address _address)
        external
        onlyRole(RoleLib.ADMIN_ROLE)
        returns (address)
    {
        return state.setJobLibraryAddress(_address);
    }

    function addressIsNew(address _address) external view returns (bool) {
        return state.addressIsNew(_address);
    }

    function getContractAddress(address _address)
        external
        view
        returns (address)
    {
        return state.getContractAddress(_address);
    }

    function amountOfWorkSpaces() external view returns (uint256) {
        return state.amountOfWorkSpaces;
    }

    function getContractFee() external view returns (uint256) {
        return state.getContractFee();
    }

    function getOwner() external view returns (address) {
        return state.getOwner();
    }

    function getWorkSpaceLibrary() external view returns (address) {
        return state.workSpaceLibraryAddress;
    }

    function getJobLibraryAddress() external view returns (address) {
        return state.jobLibraryAddress;
    }

    function amIAFactory() external pure returns (bool) {
        // This is used so the workspace clone can call back to the creator address
        // to ask if it's real during initialization!
        // To avoid a random address just calling the init
        return true;
    }

    function getCurrentWorkspaceIndex(address _manager)
        external
        view
        returns (uint256)
    {
        return state.currentIndex[_manager];
    }

    function getHistoricWorkspace(uint256 idx, address _manager)
        external
        view
        returns (address)
    {
        return state.workSpaces[_manager][idx];
    }

    fallback() external {
        emit FallbackTriggered(msg.sender);
    }
}
