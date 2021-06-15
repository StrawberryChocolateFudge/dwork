// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./WorkSpace.sol";
import "./RoleLib.sol";
import "./WorkSpaceFactoryLib.sol";
import "./CloneFactory.sol";

// The workspace factory is used to create and track WorkSpaces
contract WorkSpaceFactory is AccessControl, CloneFactory {
    using WorkSpaceFactoryLib for FactoryState;
    FactoryState state;

    event WorkSpaceCreated(
        address creator,
        address contractAddress,
        string metadata
    );

    constructor(address _owner) {
        require(_owner != address(0), "500");
        state.owner = _owner;
        _setupRole(RoleLib.ADMIN_ROLE, state.owner);
        state.disabled = false;
        state.contractFee = 0;
    }

    function createWorkSpace(uint8 _fee, string memory _metadata)
        public
        returns (address)
    {
        // each address can create a single workspace with this contract
        require(!state.disabled, "501");

        require(state.addressIsNew(msg.sender), "502");


        WorkSpace workSpace =
            WorkSpace(createClone(state.workSpaceLibraryAddress));


        workSpace.initialize(_fee, _metadata, msg.sender,state.jobLibraryAddress);

        state.workSpaces[msg.sender] = address(workSpace);

        emit WorkSpaceCreated(
            msg.sender,
            state.workSpaces[msg.sender],
            _metadata
        );
        state.amountOfWorkSpaces++;
        return state.workSpaces[msg.sender];
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

    function setWorkSpaceLibrary(address _address) external returns (address) {
        return state.setWorkSpaceLibrary(_address);
    }

    function setJobLibraryAddress(address _address) external returns (address){
        return state.setJobLibraryAddress(_address);
    }
    function getJobLibraryAddress() external view returns (address){
        return state.jobLibraryAddress;
    }

    function amIAFactory() external pure returns (bool){
        // This is used so the workspace clone can call back to the creator address 
        // to ask if it's real during initialization!
        // To avoid a random address just calling the init
        return true;
    }
}
