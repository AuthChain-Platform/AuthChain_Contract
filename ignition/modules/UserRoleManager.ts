// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  UserRoleManagerModule = buildModule("UserRoleManagerModule", (m) => {

  const userRoleManager = m.contract("UserRoleManager");

  return { userRoleManager };
});

export default UserRoleManagerModule;
