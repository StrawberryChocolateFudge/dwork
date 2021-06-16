// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
 
// DLink is a standalone contract that just links an address with more addresses

contract DLink{
    mapping (bytes32 => address[]) workLink;
    // an address may update its own mapping, or it may delete from it
    
    mapping(address =>uint) modifiedCounter;

    function link(address[] memory workspaces) external returns (uint){
        
        if(modifiedCounter[msg.sender] == 0){
            modifiedCounter[msg.sender] = 1;
      } else {
          modifiedCounter[msg.sender] += 1;
      }        
        
        workLink[getHash(msg.sender)] = workspaces;
        return workLink[getHash(msg.sender)].length;
    }

    function getLinks() external view returns (address[] memory) {
       return workLink[getHash(msg.sender)];     
   }

   function getHash(address sender) internal view  returns (bytes32){
       return keccak256(abi.encodePacked(sender,modifiedCounter[sender]));
   }

   function getCounter() external view returns (uint){
       return modifiedCounter[msg.sender];
   }

   function getHistory(uint indx) external view returns (address[] memory){
       require(indx > 0,"The id cannot be smaller than one");
       bytes32 historyAccess = keccak256(abi.encodePacked(msg.sender,indx));
       return workLink[historyAccess];
   }
}
