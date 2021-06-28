// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
struct DividendsState {
    uint256 totalBalance; // The total balance deposited in the contract
    uint256 currentBalance;
    uint256 managedTokens; //The amount of tokens the contract manages.
    //managedTokens can be used to calculate if somebody sent tokens here by accident
    mapping(address => mapping(uint256 => Balance)) tokenBalances;
    // The token balances per cycle
    mapping(address => uint256) indexes;
}

enum BalanceState {
    Deposited,
    Reclaimed,
    Withdrawn
}
enum Change {
    Add,
    Withdraw
}

struct Balance {
    bool initialized;
    BalanceState state;
    uint256 atBlock; //at block is when the tokes are deposited
    uint256 balance; //how much tokens were deposited
}

uint256 constant precision = 1000000000; //The precision of dividends calculations, 9 decimals

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
        self.tokenBalances[sender][self.indexes[sender]] = Balance({
            initialized: true,
            atBlock: block.number,
            balance: balance,
            state: BalanceState.Deposited
        });
    }

   
    function setCurrentBalance(
        DividendsState storage self,
        uint256 balance,
        Change change
    ) external returns (uint256 newBalance) {
        if (change == Change.Add) {
            newBalance = self.currentBalance + balance;
            self.currentBalance = newBalance;
        } else if (change == Change.Withdraw) {
            newBalance = self.currentBalance - balance;
            self.currentBalance = newBalance;
        }
    }

    function isUnlocked(
        DividendsState storage self,
        uint256 index,
        address sender,
        uint256 cycle
    ) internal view returns (bool) {
        require(index > 0, "565");
        require(index <= self.indexes[sender], "566");
        // If the balance was deposited 1 million blocks ago, it can be unlocked
        return self.tokenBalances[sender][index].atBlock + cycle < block.number;
    }

    function setManagedTokens(
        DividendsState storage self,
        uint256 amount,
        Change change
    ) external {
        if (change == Change.Add) {
            self.managedTokens += amount;
        } else if (change == Change.Withdraw) {
            self.managedTokens -= amount;
        }
    }

    function verify(
        DividendsState storage self,
        uint256 index,
        address sender,
        uint256 _cycle
    ) external view returns (bool, string memory) {
        if (!self.tokenBalances[sender][index].initialized) {
            return (false, "567");
        }

        if (self.tokenBalances[sender][index].state != BalanceState.Deposited) {
            return (
                false,
                "568"
            );
        }
        if (!isUnlocked(self, index, sender, _cycle)) {
            return (false, "569");
        }

        return (true, "");
    }
}
