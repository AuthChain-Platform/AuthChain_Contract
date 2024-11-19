// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  ProductManagementModule = buildModule("ProductManagementModule", (m) => {    

  const userRoleAddress = "";

  const productManagement = m.contract("ProductManagement", [userRoleAddress]);

  return { productManagement };
});

export default ProductManagementModule;
