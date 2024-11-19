// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  ConsumerManagementModule = buildModule("ConsumerManagementModule", (m) => {

  const userRoleAddress = "";
  const productManagementAddress = "";
  const consumerManagement = m.contract("ConsumerManagement", [userRoleAddress,productManagementAddress]);

  return { consumerManagement };
});

export default ConsumerManagementModule;
