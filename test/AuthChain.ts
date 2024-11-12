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
    const [ owner, account1, account2, account3 ] = await hre.ethers.getSigners();

    const authChainContract = await hre.ethers.getContractFactory("AuthChain");
    const authChainDeploy = await authChainContract.deploy();

    return { authChainDeploy, owner, account1, account2, account3 }
  }

  describe("Test Deployment successful with admin owner", function () {
    it("Should ensure that contract is deployed with admin user set in the constructor", async function () {
      const { authChainDeploy, owner, account1, account2 } = await loadFixture(deployAuthChain);

      expect(await authChainDeploy.adminUser()).to.eq(owner);
    });

  })

  describe("Test register manufacturer functionality", function () {
    it("Should ensure manufacturer is registered with a verified status of false and user role of default", async function () {
      const { authChainDeploy, owner, account1, account2 } = await loadFixture(deployAuthChain);

      const brandName = "Pure Products";
      const nafdacNumber = "JK123TY44";
      const registrationNumber = "2658867";
      const yearOfRegistration = 2025;

      const registerManufacturer = await authChainDeploy.connect(account1).registerManufacturer(
        brandName,
        nafdacNumber,
        registrationNumber,
        yearOfRegistration
      );

      const getManufacturer = await authChainDeploy.getManufacturer(account1);

      expect(await getManufacturer.brandName).to.eq(brandName);
      expect(await getManufacturer.nafdac_no).to.eq(nafdacNumber);
      expect(await getManufacturer.registration_no).to.eq(registrationNumber);
      expect(await getManufacturer.yearOfRegistration).to.eq(yearOfRegistration);
      expect(await getManufacturer.verify).to.eq(false);
      expect(await getManufacturer.verify).to.not.eq(true);
      expect(await getManufacturer.role).to.eq(0);
      expect(await getManufacturer.role).to.not.eq(1);

    });

  })

  describe("Test register admin functionality with contract admin uer should pass", function () {
    it("Should ensure admin can only be registered by contract admin user", async function () {
      const { authChainDeploy, owner, account1, account2 } = await loadFixture(deployAuthChain);

      const registerAdmin = await authChainDeploy.connect(owner).registerAdmin(account1);

      const getAdmin = await authChainDeploy.getAdmin(account1);

      expect(await getAdmin.role).to.eq(5);
      expect(await getAdmin.role).to.not.eq(1);

    });

  })


  describe("Test register admin functionality with non contract admin user should fail", function () {
    it("Should ensure admin cannot be registered by other user apart from contract admin user ", async function () {
      const { authChainDeploy, owner, account1, account2 } = await loadFixture(deployAuthChain);

      await expect(authChainDeploy.connect(account1).registerAdmin(account2)).to.be.revertedWithCustomError(
        authChainDeploy,
        "NotAnAdminUser()"
      ).withArgs();

    });

  })


  describe("Test verify manufacturer functionality", function () {
    it("Should ensure that only admin can verify manufacturer", async function () {
      const { authChainDeploy, owner, account1, account2 } = await loadFixture(deployAuthChain);

      const brandName = "Pure Products";
      const nafdacNumber = "JK123TY44";
      const registrationNumber = "2658867";
      const yearOfRegistration = 2025;

      // registering manufacturer
     

      const registerManufacturer = await authChainDeploy.connect(account1).registerManufacturer(
        brandName,
        nafdacNumber,
        registrationNumber,
        yearOfRegistration
      );

      const getManufacturer = await authChainDeploy.getManufacturer(account1);

      // registering admin
      const registerAdmin = await authChainDeploy.connect(owner).registerAdmin(account2);

      const getAdmin = await authChainDeploy.getAdmin(account2);

      
      const verifyManufacturer = await authChainDeploy.connect(account2).verifyManufacturer(account1);

      const updatedManufacturer =  await authChainDeploy.getManufacturer(account1);
      

      await expect(updatedManufacturer.verify).to.eq(true);
    });

  })

  describe("Test verify manufacturer functionality", function () {
    it("Should ensure that non admin can not verify manufacturer", async function () {
      const { authChainDeploy, owner, account1, account2 } = await loadFixture(deployAuthChain);

      const brandName = "Pure Products";
      const nafdacNumber = "JK123TY44";
      const registrationNumber = "2658867";
      const yearOfRegistration = 2025;

      // registering manufacturer
     
      const registerManufacturer = await authChainDeploy.connect(account1).registerManufacturer(
        brandName,
        nafdacNumber,
        registrationNumber,
        yearOfRegistration
      );

      const getManufacturer = await authChainDeploy.getManufacturer(account1);

      // registering admin
      const registerAdmin = await authChainDeploy.connect(owner).registerAdmin(account2);

      const getAdmin = await authChainDeploy.getAdmin(account2);

      
      const verifyManufacturer = await authChainDeploy.connect(account2).verifyManufacturer(account1);

      const updatedManufacturer =  await authChainDeploy.getManufacturer(account1);
      

      await expect(authChainDeploy.connect(owner).verifyManufacturer(account1)).to.be.revertedWithCustomError(
        authChainDeploy,
        "NotAnAdmin()",
      ).withArgs();

    });

  })



  describe("Test register distributor functionality", function () {
    it("Should ensure that only verified manufacturer can register distributor", async function () {
      const { authChainDeploy, owner, account1, account2, account3 } = await loadFixture(deployAuthChain);

      const brandName = "Pure Products";
      const nafdacNumber = "JK123TY44";
      const registrationNumber = "2658867";
      const yearOfRegistration = 2025;

      // registering manufacturer
     
      const registerManufacturer = await authChainDeploy.connect(account1).registerManufacturer(
        brandName,
        nafdacNumber,
        registrationNumber,
        yearOfRegistration
      );

      const getManufacturer = await authChainDeploy.getManufacturer(account1);

      // registering admin
      const registerAdmin = await authChainDeploy.connect(owner).registerAdmin(account2);

      const getAdmin = await authChainDeploy.getAdmin(account2);

      
      const verifyManufacturer = await authChainDeploy.connect(account2).verifyManufacturer(account1);

      const updatedManufacturer =  await authChainDeploy.getManufacturer(account1);

      

      //assigning role to manufacturer
      const assignManufacturerRole = await authChainDeploy.connect(account2).assignUserRoles(account1, 2);

      // registering distributor
      const logisticsPersonnelUID = "7283787";
      const registerLogisticsPersonnel = await authChainDeploy.connect(account1).registerLogisticsPersonnel(
        account3,
        logisticsPersonnelUID,
        brandName
      );

      const getLogisticsPersonnel = await authChainDeploy.getLogisticsPersonnel(account3)
      

      await expect(getLogisticsPersonnel.uid).to.eq(logisticsPersonnelUID);
      await expect(getLogisticsPersonnel.logisticsAddress).to.eq(account3);
      await expect(getLogisticsPersonnel.active).to.eq(true);
      await expect(getLogisticsPersonnel.brandName).to.eq(brandName);
      await expect(getLogisticsPersonnel.role).to.eq(0);

    });

  })
});
