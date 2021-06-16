// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./WorkSpace.sol";
import "hardhat/console.sol";
struct FactoryState {
    address owner;
    mapping(address => mapping(uint => address)) workSpaces;
    mapping(address => uint) currentIndex;

    uint256 amountOfWorkSpaces;
    uint8 contractFee;
    bool disabled;
    address workSpaceLibraryAddress;
    address jobLibraryAddress;
    string metadataUrl;
    uint jobLibraryVersion;
    uint workSpaceLibraryVersion;
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
        uint index = self.currentIndex[_key];
        return self.workSpaces[_key][index];
    }

    function addressIsNew(FactoryState storage self, address _address)
        public
        view
        returns (bool)
    {
        // If this is true, that means the wallet is not added to the workSpaces ,yet.
        uint index = self.currentIndex[_address];

        return
            self.workSpaces[_address][index] ==
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
        if(self.workSpaceLibraryAddress !=  _address){
            self.workSpaceLibraryVersion += 1;

            self.workSpaceLibraryAddress = _address;

        }

        return self.workSpaceLibraryAddress;
    }

    function setJobLibraryAddress(FactoryState storage self,address _address) external returns (address){   
        
        if(self.jobLibraryAddress != _address){
            self.jobLibraryAddress = _address;
            self.jobLibraryVersion += 1;
        }

        return self.jobLibraryAddress;
    }

    function checkIfWorkSpaceIsOutdated(FactoryState storage self,address _manager ) external view returns (bool){
        uint current = self.currentIndex[_manager];
        if(current == 0){
            return true;
        }
        WorkSpace workspace__ = WorkSpace(self.workSpaces[_manager][current]);
        (uint workSpaceVersion, uint JobVersion) = workspace__.getVersions();
        if(self.jobLibraryVersion > JobVersion){
            return true;
        }
        if(self.workSpaceLibraryVersion > workSpaceVersion){
            return true;
        }

        return false;
    }
}
