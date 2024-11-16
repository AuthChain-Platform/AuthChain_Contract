// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./UserRoleManager.sol";
import "./ProductManagement.sol";

contract RetailerManagement {
    address public owner;
    UserRoleManager public userRoleManager;
    ProductManagement public productManagement;

    // Retailer struct
    struct Retailer {
        string storeName;
        string location;
        bool verified;
        uint256 totalSales;
        mapping(uint256 => uint256) soldProductIds;
        uint256 totalProducts;
    }

    mapping(address => Retailer) public retailers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyVerifiedRetailer() {
        require(retailers[msg.sender].verified, "Only verified retailers can perform this action");
        _;
    }

    constructor(address _userRoleManagerAddress, address _productManagementAddress) {
        
        require(_userRoleManagerAddress != address(0), "Invalid UserRoleManager address");
        require(_productManagementAddress != address(0), "Invalid ProductManagement address");
        
        owner = msg.sender;
        userRoleManager = UserRoleManager(_userRoleManagerAddress);
        productManagement = ProductManagement(_productManagementAddress);
    }

    // Register a new retailer
    function registerRetailer(
        address retailerAddress,
        string memory storeName,
        string memory location
    ) public onlyOwner {
        require(retailerAddress != address(0), "Invalid retailer address");
        require(bytes(storeName).length > 0, "Store name is required");
        require(bytes(location).length > 0, "Location is required");
        
        Retailer storage retailer = retailers[retailerAddress];
        require(!retailer.verified, "Retailer already registered");
        
        retailer.storeName = storeName;
        retailer.location = location;
        retailer.verified = true;
        retailer.totalSales = 0;
        retailer.totalProducts = 0;

        // Assign the Retailer role to the user
        userRoleManager.assignRole(retailerAddress, UserRoleManager.userRole.Retailers);
    }

    // Function for a retailer to buy a product
    function buyProduct(uint256 productId) public payable onlyVerifiedRetailer {
        
        require(productManagement.isProductAvailable(productId), "Product is not available");
        
        uint256 productPrice = productManagement.getProductPrice(productId);
        require(msg.value >= productPrice, "Insufficient payment for the product");

        address productOwner = productManagement.getProductOwner(productId);
        require(productOwner != address(0), "Invalid product owner address");

        // Transfer payment to the product owner
        payable(productOwner).transfer(productPrice);

        // Mark the product as sold
        productManagement.markProductAsSold(productId);

        // Record the sale in the retailer's profile
        Retailer storage retailer = retailers[msg.sender];
        retailer.soldProductIds[retailer.totalSales] = productId;
        retailer.totalSales++;
        retailer.totalProducts++;
    }

    // Function for a retailer to sell a product to a consumer
    function sellProduct(uint256 productId, address consumerAddress) public onlyVerifiedRetailer {
        
        require(productManagement.isProductAvailable(productId), "Product is not available for sale");
        require(productManagement.getProductOwner(productId) == msg.sender, "Only the product owner can sell it");
        
        // Transfer ownership of the product to the consumer
        productManagement.transferProductOwnership(productId, consumerAddress);
        
        // Record the sale in the retailer's profile
        Retailer storage retailer = retailers[msg.sender];
        retailer.soldProductIds[retailer.totalSales] = productId;
        retailer.totalSales++;
    }

    // Get retailer details
    function getRetailerDetails(address retailerAddress) public view returns (
        string memory storeName, 
        string memory location, 
        bool verified
    ) {
        require(retailerAddress != address(0), "Invalid retailer address");
       
        Retailer storage retailer = retailers[retailerAddress];
        return (retailer.storeName, retailer.location, retailer.verified);
    }

    // View all sold products by a retailer
    function viewSoldProducts(address retailerAddress) public view returns (uint256[] memory) {
       
        require(retailerAddress != address(0), "Invalid retailer address");
        
        Retailer storage retailer = retailers[retailerAddress];
        uint256[] memory products = new uint256[](retailer.totalSales);
        
        for (uint256 i = 0; i < retailer.totalSales; i++) {
            products[i] = retailer.soldProductIds[i];
        }
        
        return products;
    }
}
