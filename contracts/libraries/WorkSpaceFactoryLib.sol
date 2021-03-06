// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../WorkSpace.sol";
struct FactoryState {
    mapping(address => mapping(uint => address)) workSpaces;
    mapping(address => uint32) currentIndex;

    uint32 amountOfWorkSpaces;
    uint16 contractFee; 
    bool disabled;
    address workSpaceLibraryAddress;
    address jobLibraryAddress;
    address dividendsLibrary;
    string metadataUrl;
    uint32 jobLibraryVersion;
    uint32 workSpaceLibraryVersion;
    uint32 dividendsLibraryVersion;
    
    address boardAddress;
}

library WorkSpaceFactoryLib {
    event WorkSpaceCreated(
        address creator,
        address contractAddress,
        string metadata
    );

    event JobLibraryVersion(uint);
    event WorkSpaceLibraryVersion(uint);
    event DividendsLibraryVersion(uint);
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
        returns (uint16)
    {
        return self.contractFee;
    }

    function setWorkSpaceLibrary(FactoryState storage self, address _address)
        external
        returns (address)
    {
        if(self.workSpaceLibraryAddress !=  _address){
            self.workSpaceLibraryVersion += 1;

            self.workSpaceLibraryAddress = _address;

        }
        emit WorkSpaceLibraryVersion(self.workSpaceLibraryVersion);
        return self.workSpaceLibraryAddress;
    }

    function setJobLibraryAddress(FactoryState storage self,address _address) external returns (address){   
        
        if(self.jobLibraryAddress != _address){
            self.jobLibraryAddress = _address;
            self.jobLibraryVersion += 1;
        }
        emit JobLibraryVersion(self.jobLibraryVersion);
        return self.jobLibraryAddress;
    }

    function setDividendsLibraryAddress(FactoryState storage self,address _address) external returns (address){
        if(self.dividendsLibrary != _address){
            self.dividendsLibrary = _address;
            self.dividendsLibraryVersion += 1;
        }
        
         emit DividendsLibraryVersion(self.dividendsLibraryVersion);
        return self.dividendsLibrary;
    }

    function checkIfWorkSpaceIsOutdated(FactoryState storage self,address _manager ) external view returns (bool){
        uint current = self.currentIndex[_manager];
        if(current == 0){
            //True means the workspace is Not outdated
            return true;
        }
        WorkSpace workspace__ = WorkSpace(self.workSpaces[_manager][current]);
        (uint workSpaceVersion) = workspace__.getVersion();
        if(self.workSpaceLibraryVersion > workSpaceVersion){
            return true;
        }

        return false;
    }
}
