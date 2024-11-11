// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const  AuthChainModule = buildModule("AuthChainModule", (m) => {


  const authChain = m.contract("AuthChain");

  return { authChain };
});

export default AuthChainModule;
