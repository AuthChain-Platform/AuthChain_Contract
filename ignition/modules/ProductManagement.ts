// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  ProductManagementModule = buildModule("ProductManagementModule", (m) => {    

  const userRoleAddress = "0x9b17d06296D01ab7BD42e2e55a517980fFFE9c61";

  const productManagement = m.contract("ProductManagement", [userRoleAddress]);

  return { productManagement };
});

export default ProductManagementModule;
