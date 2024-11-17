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
        mapping(uint256 => uint256) purchasedProductIds; // Track product IDs bought
        mapping(uint256 => uint256) productQuantities; // Track quantities of products bought
        mapping(uint256 => uint256) soldProductIds; // Track product IDs sold
        uint256 totalProducts;
    }

    mapping(address => Retailer) public retailers;
    mapping(uint256 => ProductSale) public soldProductDetails; 

    address[] public allRetailers;


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

        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Retailers);
    }


    function buy(uint256 productId, uint256 quantity) public payable onlyVerifiedRetailer {
            require(quantity > 0, "Quantity must be greater than zero");

            ( , uint256 price, , , , uint256 availableQuantity, , , ,) = productManagement.getProductDetails(productId);
            require(availableQuantity >= quantity, "Insufficient stock");

            uint256 totalPrice = price * quantity;
            require(msg.value >= totalPrice, "Insufficient funds");

            uint256 trackingId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, productId, quantity)));

            productManagement.purchaseProduct{value: totalPrice}(productId, quantity);

            for (uint i = 0; i < allRetailers.length; i++) {
                if (allRetailers[i] == msg.sender) { 
                    retailers[allRetailers[i]].totalProducts -= quantity;  
                    retailers[allRetailers[i]].totalSales += totalPrice; 
                    break;
                }
            }

            // Record the sale of the product globally
            soldProductDetails[productId].productId = productId;
            soldProductDetails[productId].quantitySold += quantity;
            soldProductDetails[productId].totalRevenue += totalPrice;

            payable(msg.sender).transfer(totalPrice);

            emit ProductPurchased(productId, msg.sender, quantity, totalPrice, trackingId);

            if (msg.value > totalPrice) {
                payable(msg.sender).transfer(msg.value - totalPrice);
            }
    }


    function retailerRevenue(address retailerAddress) public view  returns (uint256) {

        Retailer storage retailer = retailers[retailerAddress];
        uint256 totalRevenue = retailer.totalSales;

        return totalRevenue;
    }

    function retailerRevenue() public view onlyVerifiedRetailer returns (uint256) {

        Retailer storage retailer = retailers[msg.sender];
        uint256 totalRevenue = retailer.totalSales;

        return totalRevenue;
    }


    function getProductsOfRetailer() public view returns (uint256[] memory, uint256[] memory) {
        require(retailers[msg.sender].verified, "Retailer is not verified");

        Retailer storage retailer = retailers[msg.sender];
        uint256 totalProducts = retailer.totalProducts;

        uint256 uniqueProductsCount = 0;
        for (uint256 i = 0; i < totalProducts; i++) {
            if (retailer.purchasedProductIds[i] > 0) {
                uniqueProductsCount++;
            }
        }

        uint256[] memory productIds = new uint256[](uniqueProductsCount);
        uint256[] memory quantities = new uint256[](uniqueProductsCount);

        uint256 index = 0;
        for (uint256 productId = 0; productId < totalProducts; productId++) {
            if (retailer.purchasedProductIds[productId] > 0) {
                productIds[index] = productId;
                quantities[index] = retailer.productQuantities[productId];
                index++;
            }
        }

        return (productIds, quantities);
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
        require(retailers[retailerAddress].verified, "Retailer is not verified");
        Retailer storage retailer = retailers[retailerAddress];
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

        Retailer storage retailer = retailers[retailerAddress];
        uint256[] memory products = new uint256[](retailer.totalSales);

        for (uint256 i = 0; i < retailer.totalSales; i++) {
            products[i] = retailer.soldProductIds[i];
        }

        return products;
    }


    function viewAllRegisteredRetailers() public view returns (address[] memory) {
        return allRetailers;
    }

  
    function updateProductQuantity(uint256 productId, uint256 quantity) public onlyVerifiedRetailer {
        require(productManagement.getProductOwner(productId) == msg.sender, "Only the product owner can update the quantity");
        Retailer storage retailer = retailers[msg.sender];
        retailer.productQuantities[productId] = quantity;
    }


    function showAllProducts() public view returns (ProductManagement.Product[] memory) {
        return productManagement.getAllProducts();
    }


    function deregisterRetailer(address retailerAddress) public onlyAdmin {
        delete retailers[retailerAddress]; 
        
        Retailer storage retailer = retailers[retailerAddress];
        for (uint256 i = 0; i < retailer.totalProducts; i++) {
            delete retailer.purchasedProductIds[i]; 
            delete retailer.productQuantities[i]; 
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