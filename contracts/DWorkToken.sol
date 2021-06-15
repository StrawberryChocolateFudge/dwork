// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DWorkToken is ERC20, AccessControl {
    // WorkSpaceCredits
    constructor(uint256 initialSupply,address _adminAddress) ERC20("dWork", "DWORK") {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _mint(_adminAddress, initialSupply);
    }
}
