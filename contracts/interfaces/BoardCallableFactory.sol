// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface BoardCallableFactory {
    //The factory interface defines the functions called by the Board
    function setContractFee(uint16 _newFee) external;

    function setDisabled(bool _disabled) external;

    function setWorkSpaceLibrary(address _address) external returns (address);

    function setJobLibraryAddress(address _address) external returns (address);

    function setDividendsLibraryAddress(address _address) external returns (address);
}

