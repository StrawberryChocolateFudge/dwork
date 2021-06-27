// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "../WorkSpaceFactory.sol";

struct FactoryContractVerifierState {
    uint256 count;
}

library FactoryContractVerifier {
    event Verification(uint256 count);

    bytes32 constant codeHash = keccak256(type(WorkSpaceFactory).runtimeCode);

    function checkFactoryBytecode(
        FactoryContractVerifierState storage self,
        address factoryAddress
    ) external returns (bool) {
        self.count++;
        emit Verification(self.count);
        bytes32 callerCodeHash;
        assembly {
            callerCodeHash := extcodehash(factoryAddress)
        }
        return codeHash == callerCodeHash;
    }
}
