// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
  @dev  This interface defines the functions that 
  need to be included in a workspace contract. 
  All future Workspace libs must implement this interface, to be able to be used by the factory
  */

interface IWorkSpace {
    /*
	The workspace initializer as called by the factory
	*/
    function initialize(
        uint16 _fee,
        string memory _metadataUrl,
        address _manager,
        uint256 workSpaceVersion
    ) external;

    /*
     The job creation function that calls the workspace inside it
     It must call factory.createJob
    */
    function createJob(string calldata _metadataUrl) external;

    /*
     addWorker must call the job to add a worker to it.
    */

    function addWorker(address to, address workerAddress) external;
}
