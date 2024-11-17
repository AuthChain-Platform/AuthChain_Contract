import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("AuthChain", function () {
    async function deployAuthChain() {
        const [owner, manufacturer, logistics, retailer, consumer, admin] = await hre.ethers.getSigners();
        const authChainContract = await hre.ethers.getContractFactory("AuthChain");
        const authChainDeploy = await authChainContract.deploy();
        return { authChainDeploy, owner, manufacturer, logistics, retailer, consumer, admin };
    }

    describe("Retailer Registration and Management", function () {
        it("Should register a retailer with retailer role", async function () {
            const { authChainDeploy, retailer } = await loadFixture(deployAuthChain);
            const brandName = "Test Retail Store";

            await authChainDeploy.connect(retailer).registerRetailer(brandName);
            const retailerInfo = await authChainDeploy.connect(retailer).getRetailer();

            expect(retailerInfo.brandName).to.equal(brandName);
            expect(retailerInfo.role).to.equal(4); // Default role
        });

        it("Should emit RetailerRegistered event", async function () {
            const { authChainDeploy, retailer } = await loadFixture(deployAuthChain);
            const brandName = "Test Retail Store";

            await expect(authChainDeploy.connect(retailer).registerRetailer(brandName))
                .to.emit(authChainDeploy, "RetailerRegistered")
                .withArgs(retailer.address, brandName);
        });
    });

    describe("Product Management", function () {
        it("Should allow manufacturer to add product to inventory", async function () {
            const { authChainDeploy, owner, manufacturer, admin } = await loadFixture(deployAuthChain);
            
            // Register and verify manufacturer
            await authChainDeploy.connect(manufacturer).registerManufacturer(
                "Test Manufacturer",
                "NAF123",
                "REG456",
                2024,
                "Test Location"
            );

            await authChainDeploy.connect(owner).registerAdmin(admin);
            await authChainDeploy.connect(admin).verifyManufacturer(manufacturer.address);
            await authChainDeploy.connect(admin).assignUserRoles(manufacturer.address, 2); // Manufacturer role

            // Add product
            const productCode = 12345;
            await expect(authChainDeploy.connect(manufacturer).addToInventory(
                productCode,           // _productCode
                "Test Product",        // _productName
                "Test Description",    // _description
                1000,                  // _price
                "2025-12-31",         // _expiryDate as string
                1,                    // _batchID
                100,                  // _quantity
                "2024-03-13",         // _productionDate
                "BATCH001",           // _batch
                "product-image.jpg"   // _productImage
            )).to.emit(authChainDeploy, "ProductAdded")
              .withArgs(productCode, "Test Product", 100, manufacturer.address);
        });

        it("Should fail when non-manufacturer tries to add product", async function () {
            const { authChainDeploy, manufacturer } = await loadFixture(deployAuthChain);
            
            await expect(authChainDeploy.connect(manufacturer).addToInventory(
                12345,               // _productCode
                "Test Product",      // _productName
                "Test Description",  // _description
                1000,               // _price
                "2025-12-31",       // _expiryDate as string
                1,                  // _batchID
                100,                // _quantity
                "2024-03-13",       // _productionDate
                "BATCH001",         // _batch
                "product-image.jpg" // _productImage
            )).to.be.revertedWithCustomError(authChainDeploy, "NotAManufacturer");
        });
    });

    describe("Consumer Registration and Purchasing", function () {
      it("Should allow retailer to sell to consumer", async function () {
          const { authChainDeploy, owner, manufacturer, retailer, admin, logistics, consumer} = await loadFixture(deployAuthChain);
          
          // 1. Setup admin first
          await authChainDeploy.connect(owner).registerAdmin(admin.address);
  
          // 2. Setup retailer
          await authChainDeploy.connect(retailer).registerRetailer("Test Retail");
          // Assign retailer role
          await authChainDeploy.connect(admin).assignUserRoles(retailer.address, 4); // Retailer role
  
          // 3. Setup manufacturer
          await authChainDeploy.connect(manufacturer).registerManufacturer(
              "Test Manufacturer",
              "NAF123",
              "REG456",
              2024,
              "Test Location"
          );
          // Verify manufacturer
          await authChainDeploy.connect(admin).verifyManufacturer(manufacturer.address);
          // Assign manufacturer role
          await authChainDeploy.connect(admin).assignUserRoles(manufacturer.address, 2); // Manufacturer role
  
          // 4. Add product to manufacturer inventory
          const productCode = 12345;
          await authChainDeploy.connect(manufacturer).addToInventory(
              productCode,
              "Test Product",
              "Test Description",
              1000,
              "2025-12-31",
              1,
              100,
              "2024-03-13",
              "BATCH001",
              "product-image.jpg"
          );
  
          // 5. Register consumer
        //   await authChainDeploy.connect(consumer).registerConsumer();
          
          // 6. Transfer product to retailer
          await authChainDeploy.connect(manufacturer).transferToRetailer(
              productCode,
              retailer.address,
              10,
              logistics.address
          );

          await expect(authChainDeploy.connect(manufacturer).)
  
          // 7. Sell to consumer
    //       await expect(
    //           authChainDeploy.connect(retailer).sellToConsumer(
    //               productCode,
    //               consumer.address,
    //               1
    //           )
    //       ).to.emit(authChainDeploy, "ProductSoldToConsumer")
    //        .withArgs(productCode, account3.address, 1);
    //   });
  
      // Optional: Add test to verify product status after sale
     
  });

  describe("Consumer Registration and Purchasing", function () {
    it("Should allow retailer to sell to consumer with batch tracking", async function () {
        const { authChainDeploy, owner, account1, account2, account3 } = await loadFixture(deployAuthChain);
        
        // 1. Setup admin first
        await authChainDeploy.connect(owner).registerAdmin(owner.address);

        // 2. Setup retailer
        await authChainDeploy.connect(account1).registerRetailer("Test Retail");
        await authChainDeploy.connect(owner).assignUserRoles(account1.address, 4); // Retailer role

        // 3. Setup manufacturer
        await authChainDeploy.connect(account2).registerManufacturer(
            "Test Manufacturer",
            "NAF123",
            "REG456",
            2024,
            "Test Location"
        );
        await authChainDeploy.connect(owner).verifyManufacturer(account2.address);
        await authChainDeploy.connect(owner).assignUserRoles(account2.address, 2);

        // 4. Add product with specific batchID
        const productCode = 12345;
        const batchID = 567;
        await authChainDeploy.connect(account2).addToInventory(
            productCode,
            "Test Product",
            "Test Description",
            1000,
            "2025-12-31",
            batchID,  // Using specific batchID
            100,
            "2024-03-13",
            "BATCH001",
            "product-image.jpg"
        );

        // 5. Register consumer
        await authChainDeploy.connect(account3).registerConsumer();
        
        // 6. Transfer product to retailer
        await authChainDeploy.connect(account2).transferToRetailer(
            productCode,
            account1.address,
            10,
            account3.address
        );

        // 8. Sell to consumer
        await authChainDeploy.connect(account1).sellToConsumer(
            productCode,
            account3.address,
            1
        );

    });

    it("Should maintain correct batch information through the supply chain", async function () {
        const { authChainDeploy, owner, account1, account2, account3 } = await loadFixture(deployAuthChain);
        
        // Setup
        await authChainDeploy.connect(owner).registerAdmin(owner.address);
        await authChainDeploy.connect(account1).registerRetailer("Test Retail");
        await authChainDeploy.connect(owner).assignUserRoles(account1.address, 4);
        
        await authChainDeploy.connect(account2).registerManufacturer(
            "Test Manufacturer",
            "NAF123",
            "REG456",
            2024,
            "Test Location"
        );
        await authChainDeploy.connect(owner).verifyManufacturer(account2.address);
        await authChainDeploy.connect(owner).assignUserRoles(account2.address, 2);
        
        // Product with multiple batches
        const productCode1 = 12345;
        const productCode2 = 12346;
        const batchID1 = 567;
        const batchID2 = 568;

        // Add products with different batches
        await authChainDeploy.connect(account2).addToInventory(
            productCode1,
            "Test Product 1",
            "Test Description",
            1000,
            "2025-12-31",
            batchID1,
            100,
            "2024-03-13",
            "BATCH001",
            "product-image.jpg"
        );

        await authChainDeploy.connect(account2).addToInventory(
            productCode2,
            "Test Product 2",
            "Test Description",
            1000,
            "2025-12-31",
            batchID2,
            100,
            "2024-03-13",
            "BATCH002",
            "product-image.jpg"
        );

        await authChainDeploy.connect(account3).registerConsumer();

        // Transfer both products to retailer
        await authChainDeploy.connect(account2).transferToRetailer(
            productCode1,
            account1.address,
            10,
            account3.address
        );

        await authChainDeploy.connect(account2).transferToRetailer(
            productCode2,
            account1.address,
            10,
            account3.address
        );


        // Sell both products to consumer
        await authChainDeploy.connect(account1).sellToConsumer(
            productCode1,
            account3.address,
            5
        );

        await authChainDeploy.connect(account1).sellToConsumer(
            productCode2,
            account3.address,
            5
        );

       
    });

    it("Should update product quantities after sale", async function () {
      const { authChainDeploy, owner, account1, account2, account3 } = await loadFixture(deployAuthChain);
      
      // Same setup as above
      await authChainDeploy.connect(owner).registerAdmin(owner.address);
      
      await authChainDeploy.connect(account1).registerRetailer("Test Retail");
      await authChainDeploy.connect(owner).assignUserRoles(account1.address, 4);
      
      await authChainDeploy.connect(account2).registerManufacturer(
          "Test Manufacturer",
          "NAF123",
          "REG456",
          2024,
          "Test Location"
      );
      await authChainDeploy.connect(owner).verifyManufacturer(account2.address);
      await authChainDeploy.connect(owner).assignUserRoles(account2.address, 2);
      
      const productCode = 12345;
      const initialQuantity = 100;
      const transferQuantity = 10;
      const purchaseQuantity = 2;

      await authChainDeploy.connect(account2).addToInventory(
          productCode,
          "Test Product",
          "Test Description",
          1000,
          "2025-12-31",
          1,
          initialQuantity,
          "2024-03-13",
          "BATCH001",
          "product-image.jpg"
      );

      await authChainDeploy.connect(account3).registerConsumer();
      
      await authChainDeploy.connect(account2).transferToRetailer(
          productCode,
          account1.address,
          transferQuantity,
          account3.address
      );

      await authChainDeploy.connect(account1).sellToConsumer(
          productCode,
          account3.address,
          purchaseQuantity
      );

      // Get consumer's purchase info
      const consumerInfo = await authChainDeploy.connect(account3).getConsumer();
      expect(consumerInfo.role).to.equal(1); // Consumer role
  });
});

    // ... rest of the test cases remain the same
});