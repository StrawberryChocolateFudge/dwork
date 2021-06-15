// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./WorkSpace.sol";

struct FactoryState {
    address owner;
    mapping(address => address) workSpaces;
    uint256 amountOfWorkSpaces;
    uint8 contractFee;
    bool disabled;
    address workSpaceLibraryAddress;
    address jobLibraryAddress;
}

library WorkSpaceFactoryLib {
    event WorkSpaceCreated(
        address creator,
        address contractAddress,
        string metadata
    );

    function getContractAddress(FactoryState storage self, address _key)
        public
        view
        returns (address)
    {
        return self.workSpaces[_key];
    }

    function addressIsNew(FactoryState storage self, address _address)
        public
        view
        returns (bool)
    {
        // If this is true, that means the wallet is not added to the workSpaces ,yet.
        return
            self.workSpaces[_address] ==
            address(0x0000000000000000000000000000000000000000);
    }

    function getContractFee(FactoryState storage self)
        external
        view
        returns (uint8)
    {
        return self.contractFee;
    }

    function getOwner(FactoryState storage self)
        external
        view
        returns (address)
    {
        return self.owner;
    }

    function setWorkSpaceLibrary(FactoryState storage self, address _address)
        external
        returns (address)
    {
        self.workSpaceLibraryAddress = _address;
        return self.workSpaceLibraryAddress;
    }

    function setJobLibraryAddress(FactoryState storage self,address _address) external returns (address){   
        self.jobLibraryAddress = _address;
        return self.jobLibraryAddress;
    }
}
