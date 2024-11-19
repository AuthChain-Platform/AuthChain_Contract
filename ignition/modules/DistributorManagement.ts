// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  DistributorManagementModule = buildModule("DistributorManagementModule", (m) => {
  
  const userRoleAddress = "0x9b17d06296D01ab7BD42e2e55a517980fFFE9c61";
  const productManagementAddress = "0xe71aa05fE1743f8C5db3160Cf3a7d6004E3866aF";

  const distributorManagement = m.contract("DistributorManagement",[userRoleAddress,productManagementAddress]);

  return { distributorManagement };
});

export default DistributorManagementModule;