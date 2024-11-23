// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  DistributorManagementModule = buildModule("DistributorManagementModule", (m) => {
  
  const userRoleAddress = "0x65f34d19a3B47c0177661C32497470543816C40c";
  const productManagementAddress = "0x4456ce0eBadB36Ad298Ff19ce4aC18075c4407Cb";

  const distributorManagement = m.contract("DistributorManagement",[userRoleAddress,productManagementAddress]);

  return { distributorManagement };
});

export default DistributorManagementModule;
