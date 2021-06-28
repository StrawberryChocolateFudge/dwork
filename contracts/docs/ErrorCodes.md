
Events
100 : The address was saved

Roles
201 : Manager
202 : client
203 : worker
204 : not registered



Errors 
500 : Invalid address
501 : The contract is disabled
502 : The wallet already has a workspace, and no need to update
503 : Somebody is usning the function, try again 
504 : _manager is the zero address
505 : _jobLibraryAddress is the zero address
506 : Caller is not the factory!
507 : The client must be initialized
508 : Disabled clients cannot create jobs
509 : Sender must be manager or client
510 : The address and share array must match!
511 : workerAddress is the zero address
512 : The manager cannot become a worker.
513 : Registration is not open
514 : The worker already signed up
515 : clientAddress is the zero address
516 : The client cannot become a manager.
517 : Registration is not open
518 : The client already signed up
519 : Function is in use, try again
520 : Fee cannot be more than 100
521 : Fee cannot be higher than 1000
522 : Disabled client cannot add worker 
523 : The caller is not the workspace
524 : The job is disabled
525 : Minimum balance is 1 ether
526 : No need for dispute if there is no balance
527 : insufficient balance in contract
528 : The final price must not be zero to withdraw funds
529 : Already got payed
530 : As long as the assignment is not accepted, you are not permitted to withdraw funds
531 : Not allowed
532 : Oh noes the calculation went wrong!
533 : Unable to send value to worker, recipient may have reverted
534 : Unable to send value manager, recipient may have reverted
535 : Unable to send value dividends, recipient may have reverted
536 : Refund is not allowed
537 : Unable to refund the value, recipient may have reverted
538 : The last assignment must not be active
539 : Cannot assign new worker if work has started 
540 : The last assignment's payments must be done or a refund must be issued
541 : The assignment doesn't exist
542 : The assignment is already ready
543 : The assignment doesn't exist
544 : The assignment is not ready yet
545 : The work has started already
546 : The work didn't start yet.
547 : No dispute to resolve.
548 : The work is not done, yet.
549 : Only the manager or worker can sign up workers
550 : Only the client and the manager can sign up workers
551 : The job doesn't exist anymore
552 : Fee must be under or equal 4000 and bigger than zero
553 : Worker is already registered for something
554 : Client is already registered for something
555 : Worker is not initialized
556 : Client is not initialized
557 : Only callable by the board
558 : The client arg must be msg.sender if you are client
//Crowdsale
559 : Rate is zero
560 : Wallet is zero address
561 : Token is the zero address
562 : Beneficiary is the zero address
563 : WeiAmount is 0
564 : Not enough balance
565 : Index cant be zero
566 : Index cant be too high
567 : balance is not initialized
568 : balance state is not deposited, the funds might be already withdrawn
569 : The balance is still locked
570 : Must have enough shares
571 : Proposal must be accepted
572 : You have to wait to make more propositions
573 : The proposal is not initialized
574 : The creator of the proposal cannot vote
575 : Cannot vote on zero index
576 : Cannot vote on future proposals
577 : The proposal expired
578 : Cant vote on closed proposals
579 : The sender voted already
580 : Cannot vote on zero index
581 : Cannot vote on future proposals
582 : The proposal is not initialized
583 : The proposal already closed
584 : The proposal didnt expire,yet