// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/*
  dev comment: This interface defines the functions that 
  need to be included in a job contract. 
  All future Job libs must implement this interface, to be able to be used by the factory
  */
interface IJob {
    /*
    This is called by the factory to initialize the job
    */

    function initialize(
        address _workSpaceAddress,
        address _clientAddress,
        address _managerAddress,
        string calldata metadataUrl,
        uint32 version,
        uint16 contractFee,
        uint16 managementFee,
        address dividendsContract
    ) external;

    /*
    Add worker is called by the workspace, to add a worker
    */
    function addWorker(address workerAddress) external returns (bool);
}
