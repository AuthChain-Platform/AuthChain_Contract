// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  RetailerManagementModule = buildModule("RetailerManagementModule", (m) => {
    
  const userRoleAddress = "";
  const productManagementAddress = "";

  const retailerManagement = m.contract("RetailerManagement", [userRoleAddress,productManagementAddress]);

  return { retailerManagement };
});

export default RetailerManagementModule;
