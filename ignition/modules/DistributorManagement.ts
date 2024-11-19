// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  DistributorManagementModule = buildModule("DistributorManagementModule", (m) => {
  
  const userRoleAddress = "";
  const productManagementAddress = "";

  const distributorManagement = m.contract("DistributorManagement",[userRoleAddress,productManagementAddress]);

  return { distributorManagement };
});

export default DistributorManagementModule;
