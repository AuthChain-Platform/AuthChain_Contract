import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("AuthChain", function () {
//  Test for AuthChain

  async function deployAuthChain() {
    const [ owner, account1, account2 ] = await hre.ethers.getSigners();

    const authChainContract = await hre.ethers.getContractFactory("AuthChain");
    const authChainDeploy = await authChainContract.deploy();

    return { authChainDeploy, owner, account1, account2 }
  }
});
