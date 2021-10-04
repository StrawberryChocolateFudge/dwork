       ▄█     █▄   ▄██████▄     ▄████████    ▄█   ▄█   ▄█        ▄█  ███▄▄▄▄      ▄█   ▄█▄    ▄████████ 
      ███     ███ ███    ███   ███    ███   ███ ▄███▀ ███       ███  ███▀▀▀██▄   ███ ▄███▀   ███    ███  
      ███     ███ ███    ███   ███    ███   ███▐██▀   ███       ███▌ ███   ███   ███▐██▀     ███    █▀   
      ███     ███ ███    ███  ▄███▄▄▄▄██▀  ▄█████▀    ███       ███▌ ███   ███  ▄█████▀      ███       
      ███     ███ ███    ███ ▀▀███▀▀▀▀▀   ▀▀█████▄    ███       ███▌ ███   ███ ▀▀█████▄      ▀███████████
      ███     ███ ███    ███ ▀███████████   ███▐██▄   ███       ███  ███   ███   ███▐██▄              ███
      ███ ▄█▄ ███ ███    ███   ███    ███   ███ ▀███▄ ███▌    ▄ ███  ███   ███   ███ ▀███▄      ▄█    ███
       ▀███▀███▀   ▀██████▀    ███    ███   ███   ▀█▀ █████▄▄██ █▀    ▀█   █▀    ███   ▀█▀    ▄████████▀
                                            ███    ███   ▀         ▀                          ▀



Decentralized Worklinks is a project comprised of 2 repositories. DWORK and worklinks.eth.
DWORK is written in solidity and it's a "managed escrow as a service" platform.
worklinks.eth is the name of the domain purchased for this project and the front end for DWORK is being developed under this name.


With this platform a wallet may create a workspace and register client and worker wallet addresses.
The manager of the workspace can match workers to a client, help the client find the right person for the job 
and deploy job contracts which functions as an escrow. The worker can finish a job and claim rewards deposited by the client
or the client may request dispute resolution and the manager can decide to refund him.

The project uses the DWORK token, a token sold via a crowdsale contract.
DWORK is used to collect dividends, fees collected from Jobs and becomes part of the board 
and may vote on how much fees they should collect in future deployed job escrow contracts.


Run all tests 
`yarn test`

run script to deploy to local network:

`npx hardhat node`

`npx hardhat run --network localhost scripts/deploy.ts`


## DEPLOYED ON TESTNET

 ·---------------------------|-------------·
 |  Contract Name            ·  Size (Kb)  │
 ····························|··············
 |  Address                  ·       0.08  │
 ····························|··············
 |  Board                    ·       4.39  │
 ····························|··············
 |  BoardLib                 ·       2.26  │
 ····························|··············
 |  CloneFactory             ·       0.06  │
 ····························|··············
 |  Dividends                ·       6.28  │
 ····························|··············
 |  DividendsLib             ·       1.79  │
 ····························|··············
 |  DLink                    ·       1.50  │
 ····························|··············
 |  DWorkCrowdSale           ·       4.14  │
 ····························|··············
 |  DWorkToken               ·       2.94  │
 ····························|··············
 |  ERC20                    ·       2.43  │
 ····························|··············
 |  FactoryContractVerifier  ·       8.95  │
 ····························|··············
 |  Job                      ·      10.28  │
 ····························|··············
 |  JobLib                   ·       5.24  │
 ····························|··············
 |  RoleLib                  ·       0.38  │
 ····························|··············
 |  SafeERC20                ·       0.08  │
 ····························|··············
 |  SafeMath                 ·       0.08  │
 ····························|··············
 |  Strings                  ·       0.08  │
 ····························|··············
 |  WorkSpace                ·      12.34  │
 ····························|··············
 |  WorkSpaceFactory         ·       8.50  │
 ····························|··············
 |  WorkSpaceFactoryLib      ·       1.66  │
 ····························|··············
 |  WorkSpaceLib             ·       7.49  │
 ·---------------------------|-------------·

CONTRACTS:
DWORK : 0x52D1433a4239713348d2bD918124Bc67f77dfe7c
CrowdSale : 0x90C0347833D4A086a86CE530c391F02857E98fae
Dividends : 0x20c858207184D4d64A83557202bb178ED8186dC9
Factory : 0x5869B73B094db5a8cA4F33569C159b645AC9201e
WorkSpace : 0xaC181D2dC5b64FDdA34E3377f6eBdc3C81D28207
Job : 0xF3C86Bac552D8DF8958E605B57bB2963488f3C31
Link : 0x964d132dAAa44DBe1E86A9D9A1605bBEA59D8253
Board : 0x278dD2cc09cE7f4Edf0bcda5927fE7BD3D99cD82

LIBRARIES:
DividendsLib : 0x3BEd772F87a0116f8C06DD5A776F13FC50fD6478
Factorylib : 0xfc4f1CF8D012b3f12c17144621FB22116b0d6118
WorkSpacelib : 0x2A84d2C0b58F251785D2F0aa7637C1C68e935ee0
Joblib : 0x301F9b1D438b42648f5eF905BF9A01Aa38B8e5aF
Boardlib : 0xdC627A00D6d717c3A920ed07C28027E6f4474dF6
FactoryContractVerifier : 0x495396CEa0d6c20A0e81fBB7B84064Ca74afc807