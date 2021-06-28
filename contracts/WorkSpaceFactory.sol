// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./WorkSpace.sol";
import "./libraries/CloneFactory.sol";
import "./libraries/RoleLib.sol";
import "./libraries/WorkSpaceFactoryLib.sol";
import "./interfaces/IWorkSpace.sol";
import "./interfaces/IJob.sol";

// The workspace factory is used to create and track WorkSpaces
contract WorkSpaceFactory is AccessControl, CloneFactory, Multicall, Ownable {
    using WorkSpaceFactoryLib for FactoryState;
    FactoryState private state;
    mapping(address => bool) private createLocks;

    event WorkSpaceCreated(
        address creator,
        address contractAddress,
        string metadata
    );

    event CreateWorkSpaceFailed(address sender);

    event FallbackTriggered(address sender);

    event JobLibraryVersion(uint256);
    event WorkSpaceLibraryVersion(uint256);
    event DividendsLibraryVersion(uint256);
    event ContractFeeChange(uint16);

    constructor(uint16 fee) {
        state.disabled = false;
        state.contractFee = fee;
        state.jobLibraryVersion = 0;
        state.workSpaceLibraryVersion = 0;
    }

    function createWorkSpace(uint16 _fee, string memory _metadata)
        external
        returns (address)
    {
        //if upgrade is available, allow the creation of multiple workspaces
        //The creator will also pass if this is the first workspace he created
        require(state.checkIfWorkSpaceIsOutdated(msg.sender), "502");
        require(_fee <= 4000 && _fee > 0, "552");
        require(!state.disabled, "501");
        // Locking the create so a user can only create one at a time, no reentrancy
        require(createLocks[msg.sender] == false, "503");
        createLocks[msg.sender] = true;
        uint256 index;
        IWorkSpace workSpace = IWorkSpace(
            createClone(state.workSpaceLibraryAddress)
        );

        try
            workSpace.initialize(
                _fee,
                _metadata,
                msg.sender,
                state.workSpaceLibraryVersion
            )
        {
            state.currentIndex[msg.sender] += 1;
            index = state.currentIndex[msg.sender];
            state.workSpaces[msg.sender][index] = address(workSpace);
            state.amountOfWorkSpaces++;
            _setupRole(RoleLib.WORKSPACE, address(workSpace));
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

    function createJob(
        address _clientAddress,
        address _managerAddress,
        string calldata metadataUrl,
        uint16 managementFee
    ) external onlyRole(RoleLib.WORKSPACE) returns (address) {
        IJob job = IJob(payable(createClone(state.jobLibraryAddress)));
        job.initialize(
            msg.sender,
            _clientAddress,
            _managerAddress,
            metadataUrl,
            state.jobLibraryVersion,
            state.contractFee,
            managementFee,
            state.dividendsLibrary
        );
        return address(job);
    }

    function setContractFee(uint16 _newFee) external {
        require(_newFee <= 1000, "521");
        require(msg.sender == state.boardAddress, "only callable by the board");
        state.contractFee = _newFee;
        emit ContractFeeChange(state.contractFee);
    }

    function setDisabled(bool _disabled) external onlyOwner {
        state.disabled = _disabled;
    }

    function setBoardAddress(address to) external onlyOwner {
        state.boardAddress = to;
    }

    function setWorkSpaceLibrary(address _address)
        external
        onlyOwner
        returns (address)
    {
        return state.setWorkSpaceLibrary(_address);
    }

    function setJobLibraryAddress(address _address)
        external
        onlyOwner
        returns (address)
    {
        return state.setJobLibraryAddress(_address);
    }

    function setDividendsLibraryAddress(address _address)
        external
        onlyOwner
        returns (address)
    {
        return state.setDividendsLibraryAddress(_address);
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

    function amountOfWorkSpaces() external view returns (uint32) {
        return state.amountOfWorkSpaces;
    }

    function getContractFee() external view returns (uint16) {
        return state.getContractFee();
    }

    function getWorkSpaceLibrary() external view returns (address) {
        return state.workSpaceLibraryAddress;
    }

    function getJobLibraryAddress() external view returns (address) {
        return state.jobLibraryAddress;
    }

    function getBoardAddress() external view returns (address) {
        return state.boardAddress;
    }

    function getCurrentWorkspaceIndex(address _manager)
        external
        view
        returns (uint256)
    {
        return state.currentIndex[_manager];
    }

    function getHistoricWorkspace(uint32 idx, address _manager)
        external
        view
        returns (address)
    {
        return state.workSpaces[_manager][idx];
    }

    function getCurrentJobLibraryVersion() external view returns (uint32) {
        return state.jobLibraryVersion;
    }

    fallback() external {
        emit FallbackTriggered(msg.sender);
    }
}
