// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  ProductManagementModule = buildModule("ProductManagementModule", (m) => {    

  const userRoleAddress = "0x65f34d19a3B47c0177661C32497470543816C40c";

  const productManagement = m.contract("ProductManagement", [userRoleAddress]);

  return { productManagement };
});

export default ProductManagementModule;
