// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DWorkToken is ERC20 {
    event Burn(uint256 value, address burner);

    constructor(address to, uint256 initialSupply) ERC20("DWORK", "DWORK") {
        require(to != address(0), "Address is zero address");
        _mint(to, initialSupply);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Burn(amount, msg.sender);
    }
}
