// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

library RoleLib {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WORKER_ROLE = keccak256("WORKER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CLIENT_ROLE = keccak256("CLIENT_ROLE");
}
