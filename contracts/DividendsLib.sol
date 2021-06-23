// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct DividendsState {
    uint256 totalBalance; // The total balance deposited in the contract
    mapping(address => mapping(uint256 => Balance)) balances;
    // The token balances per cycle
    mapping(address => uint256) indexes;
}

enum BalanceState {Deposited,Reinvested,Withdrawn}

struct Balance {
    bool initialized;
    bool withdrawn;
    BalanceState state; 
    uint256 atBlock; //at block is when the tokes are deposited
    uint256 balance; //how much tokens were deposited
}

//one cycle has 1 million blocks, after 1 million blocks the tokens can be redeemed or reinvested
uint256 constant cycleBlocks = 1000000;

library DividendsLib {
    function setTotalBalance(DividendsState storage self, uint256 _balance)
        external
    {
        self.totalBalance += _balance;
    }

    function setNewBalance(
        DividendsState storage self,
        address sender,
        uint256 balance
    ) external {
        self.indexes[sender] += 1;
        self.balances[sender][self.indexes[sender]] = Balance({
            initialized : true,
            withdrawn : false,
            atBlock: block.number,
            balance: balance,
            state : BalanceState.Deposited
        });
    }

    function isUnlocked(
        DividendsState storage self,
        uint256 index,
        address sender
    ) external view returns (bool) {
        require(index > 0, "Index cant be zero");
        require(index <= self.indexes[sender], "Index cannot be too high");
        // If the balance was deposited 1 million blocks ago, it can be unlocked
        return
            self.balances[sender][index].atBlock + cycleBlocks < block.number;
    }
}
