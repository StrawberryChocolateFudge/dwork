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