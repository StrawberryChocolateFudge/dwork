// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
import "./WorkSpaceFactory.sol";
import "hardhat/console.sol";

struct FactoryContractVerifierState{
  uint version;
}
library FactoryContractVerifier{
  function checkFactoryBytecode(FactoryContractVerifierState storage self,address factoryAddress) external view returns (bool) {
        bytes32 runtimeCodeHash = keccak256(type(WorkSpaceFactory).runtimeCode);
        bytes32 callerCodeHash;
        assembly{
            callerCodeHash := extcodehash(factoryAddress)
        }
        return runtimeCodeHash == callerCodeHash;
   }
}