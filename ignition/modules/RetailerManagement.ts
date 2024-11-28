// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  RetailerManagementModule = buildModule("RetailerManagementModule", (m) => {
    
  const userRoleAddress = "0x65f34d19a3B47c0177661C32497470543816C40c";
  const productManagementAddress = "0x3D8ceA276f85Dd8b373f2Db22Ac3b4A870cF15ae";
  const distributorManagementAddress = "0x00fCCefe9eD0B3Fb38a8D1B668302ce194e0b58C";

  const retailerManagement = m.contract("RetailerManagement", [userRoleAddress, productManagementAddress, distributorManagementAddress]);

  return { retailerManagement };
});

export default RetailerManagementModule;
