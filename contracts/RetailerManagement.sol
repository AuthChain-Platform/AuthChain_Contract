// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./UserRoleManager.sol";
import "./ProductManagement.sol";

contract RetailerManagement {

    address public owner;
    UserRoleManager public userRoleManager;
    ProductManagement public productManagement;

    struct ProductSale {
            uint256 productId;
            uint256 totalRevenue; // Revenue generated from sale
            uint256 quantitySold; // Quantity of the product sold
        }

    struct ProductPurchase {
        uint256 productId;
        uint256 quantity;
    }
    
    struct Retailer {
        uint256 id;
        string retailerName;
        string registration_no;
        uint256 yearOfRegistration;
        string location;
        string state;
        string image;
        bool verified;
        uint256 totalSales;
        uint256 totalProducts;
        uint256[] soldProductIds;
        ProductPurchase[] purchasedProducts;
    }

    uint256 totalSales; // Represents total monetary sales
    uint256[] soldProductIds; // Array to store sold product IDs

    mapping(uint256 => uint256) purchasedProductIds; 
    mapping(uint256 => uint256) productQuantities;

    mapping(address => Retailer) public retailers;
    address[] public allRetailers;

    mapping(address => UserRoleManager.userRole) public retailerRoles;

    
    mapping(uint256 => ProductSale) public soldProductDetails; 

    
    event ProductPurchased(uint256 productId, address buyer, uint256 quantity, uint256 totalPrice, uint256 trackingId);


    modifier onlyAdmin() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _; 
    }

    modifier onlyVerifiedRetailer() {
        require(retailers[msg.sender].verified == true, "Only verified retailers can perform this action");
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
        string memory retailerName,
        string memory nafdac_no,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image
    ) public {

        require(msg.sender != address(0), "Invalid retailer address");
        require(bytes(retailerName).length > 0, "Retailer name is required");
        require(bytes(location).length > 0, "Location is required");
        require(bytes(nafdac_no).length > 0, "NAFDAC number is required");
        require(bytes(registration_no).length > 0, "Registration number is required");
        require(yearOfRegistration > 0, "Year of registration is required");
        require(bytes(state).length > 0, "State is required");

        Retailer storage retailer = retailers[msg.sender];
        require(!retailer.verified, "Retailer already registered");

        retailer.id = allRetailers.length + 1;
        retailer.retailerName = retailerName;
        retailer.registration_no = registration_no;
        retailer.yearOfRegistration = yearOfRegistration;
        retailer.location = location;
        retailer.state = state;
        retailer.image = image;
        retailer.verified = true;
        retailer.totalSales = 0;
        retailer.totalProducts = 0;

        allRetailers.push(msg.sender);

        retailerRoles[msg.sender] = UserRoleManager.userRole.Retailers;

        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Retailers);
    }

    function checkRetailerRole(address retailersAddress) public view returns (string memory) {
        if (retailerRoles[retailersAddress] == UserRoleManager.userRole.Retailers) {
            return "Retailer";
        }
        return "No Role";
    }


    function buy(uint256 productId, uint256 quantity) public payable onlyVerifiedRetailer {
        require(quantity > 0, "Quantity must be greater than zero");

        (, uint256 price, , , , uint256 availableQuantity, , , ,) = productManagement.getProductDetails(productId);
        require(availableQuantity >= quantity, "Insufficient stock");

        uint256 totalPrice = price * quantity;
        require(msg.value >= totalPrice, "Insufficient funds");

        productManagement.purchaseProduct{value: totalPrice}(productId, quantity);

        Retailer storage retailer = retailers[msg.sender];
        retailer.totalSales += totalPrice;
        retailer.totalProducts -= quantity;

        soldProductDetails[productId].quantitySold += quantity;
        soldProductDetails[productId].totalRevenue += totalPrice;

        if (msg.value > totalPrice) {
            payable(msg.sender).call{value: msg.value - totalPrice}("");
        }

        emit ProductPurchased(productId, msg.sender, quantity, totalPrice, block.timestamp);
    }


    function retailerRevenueByAddress(address retailerAddress) public view returns (uint256) {
        Retailer memory retailer = retailers[retailerAddress];
        return retailer.totalSales;
    }

    function retailerRevenue() public view onlyVerifiedRetailer returns (uint256) {

        Retailer memory retailer = retailers[msg.sender];
        uint256 totalRevenue = retailer.totalSales;

        return totalRevenue;
    }


    function getProductsOfRetailer() public view returns (uint256[] memory productIds, uint256[] memory quantities) {
        Retailer memory retailer = retailers[msg.sender];
        uint256 totalProducts = retailer.purchasedProducts.length;

        productIds = new uint256[](totalProducts);
        quantities = new uint256[](totalProducts);

        for (uint256 i = 0; i < totalProducts; i++) {
            productIds[i] = retailer.purchasedProducts[i].productId;
            quantities[i] = retailer.purchasedProducts[i].quantity;
        }
    }


    function getRetailerDetails(address retailerAddress) public view returns (
        string memory retailerName,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image,
        bool verified,
        uint256 totalSales,
        uint256 totalProducts
    ) {
        Retailer memory retailer = retailers[retailerAddress];
        return (
            retailer.retailerName,
            retailer.registration_no,
            retailer.yearOfRegistration,
            retailer.location,
            retailer.state,
            retailer.image,
            retailer.verified,
            retailer.totalSales,
            retailer.totalProducts
        );
    }


    function getProductInfo(uint256 productCode) public view returns (string memory) {
        (
            string memory name,
            uint256 price,
            uint256 batchID,
            uint256 expiryDate,
            string memory productDescription,
            uint256 availableQuantity,
            string memory productImage,
            ProductManagement.ProductStatus status,
            address _owner,
            uint256 trackingID
        ) = productManagement.getProductDetails(productCode);

        if (status == ProductManagement.ProductStatus.MANUFACTURED) {
            return string(abi.encodePacked(
                "Name: ", name, ", ",
                "Price: ", uint2str(price), ", ",
                "Batch ID: ", uint2str(batchID), ", ",
                "Expiry Date: ", uint2str(expiryDate), ", ",
                "Description: ", productDescription, ", ",
                "Available Quantity: ", uint2str(availableQuantity), ", ",
                "Product Image: ", productImage, ", ",
                "Tracking ID: ", uint2str(trackingID), ", ",
                "Owner: ", addressToString(_owner)
            ));
        } else {
            return "Product Not Available";
        }
    }


    // Helper function to convert uint256 to string
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }



    function viewSoldProducts(address retailerAddress) public view returns (uint256[] memory) {
        require(retailerAddress != address(0), "Invalid retailer address");

        Retailer memory retailer = retailers[retailerAddress];
        require(retailer.verified, "Retailer not verified");

        // Use purchasedProducts.length instead of totalSales
        uint256[] memory soldProducts = new uint256[](retailer.purchasedProducts.length);

        for (uint256 i = 0; i < retailer.purchasedProducts.length; i++) {
            soldProducts[i] = retailer.purchasedProducts[i].productId;
        }

        return soldProducts;
    }



    function viewAllRegisteredRetailers() public view returns (address[] memory) {
        return allRetailers;
    }

  
    function updateProductQuantity(uint256 productId, uint256 quantity) public onlyVerifiedRetailer {

        address productOwner = productManagement.getProductOwner(productId);
        require(productOwner == msg.sender, "Caller is not the product owner");

        productQuantities[productId] = quantity;
    }


    function showAllProducts() public view returns (ProductManagement.Product[] memory) {
        return productManagement.getAllProducts();
    }


    function deregisterRetailer(address retailerAddress) public onlyAdmin {
        delete retailers[retailerAddress];
        for (uint256 i = 0; i < allRetailers.length; i++) {
            if (allRetailers[i] == retailerAddress) {
                allRetailers[i] = allRetailers[allRetailers.length - 1];
                allRetailers.pop();
                break;
            }
        }
    }


    // Helper function to convert address to string
    function addressToString(address _addr) internal pure returns (string memory) {
        return string(abi.encodePacked("0x", toHexString(uint256(uint160(_addr)), 20)));
    }

    // Helper function for address to hex string conversion
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes16 _HEX_SYMBOLS = "0123456789abcdef";
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = 2 * length; i > 0; i--) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }


}