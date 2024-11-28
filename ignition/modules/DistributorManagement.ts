// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  DistributorManagementModule = buildModule("DistributorManagementModule", (m) => {
  
  const userRoleAddress = "0x65f34d19a3B47c0177661C32497470543816C40c";
  const productManagementAddress = "0x3D8ceA276f85Dd8b373f2Db22Ac3b4A870cF15ae";

  const distributorManagement = m.contract("DistributorManagement",[userRoleAddress,productManagementAddress]);

  return { distributorManagement };
});

export default DistributorManagementModule;
