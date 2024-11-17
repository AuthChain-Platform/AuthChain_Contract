// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./ProductManagement.sol";
import "./UserRoleManager.sol";

contract DistributorManagement {

    uint256 public id;
    address public owner;
    UserRoleManager public userRoleManager; 
    ProductManagement public productManagement;

    struct Distributor {
        uint256 id;
        address distributorAddress; 
        string distributorName;
        string registration_no;
        uint256 yearOfRegistration;
        string location;
        string state;
        string image;
        bool verified;
        uint256 totalDistributions;
        uint256 totalSales;  
        uint256 totalProducts;
    }

    Distributor[] public allDistributors;

    event ProductPurchased(uint256 productId, address buyer, uint256 quantity, uint256 totalPrice, uint256 trackingId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _; 
    }

    modifier onlyVerifiedDistributor() {
        bool isVerified = false;
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].verified == true) {
                isVerified = true;
                break;
            }
        }
        require(isVerified, "Only verified distributor can perform this action");
        _; 
    }

    constructor(address _userRoleManager, address _productManagementAddress) {
        owner = msg.sender;
        userRoleManager = UserRoleManager(_userRoleManager);
        productManagement = ProductManagement(_productManagementAddress);
    }


    function registerDistributor(
        string memory distributorName,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image
    ) public {

        for (uint i = 0; i < allDistributors.length; i++) {
            require(allDistributors[i].distributorAddress != msg.sender, "Distributor already registered");
        }

        uint256 newDistributorId = id + 1;

        allDistributors.push(Distributor({

            id: newDistributorId,
            distributorAddress: msg.sender,
            distributorName: distributorName,
            registration_no: registration_no,
            yearOfRegistration: yearOfRegistration,
            location: location,
            state: state,
            image: image,
            verified: true,
            totalDistributions: 0,
            totalSales: 0,
            totalProducts: 0

        }));

        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Distributor);
    }

    function deregisterDistributor(uint256 distributorId) public onlyOwner {
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                delete allDistributors[i];
                break;
            }
        }
    }

    function updateDistributorInfo(
        uint256 distributorId,
        string memory distributorName,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image
    ) public onlyOwner {
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                allDistributors[i].distributorName = distributorName;
                allDistributors[i].registration_no = registration_no;
                allDistributors[i].yearOfRegistration = yearOfRegistration;
                allDistributors[i].location = location;
                allDistributors[i].state = state;
                allDistributors[i].image = image;
                break;
            }
        }
    }

    function viewAllRegisteredDistributors() public view returns (Distributor[] memory) {
        return allDistributors;
    }

    function viewPurchasedProductQuantities(uint256 distributorId) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory productIds = new uint256[](allDistributors.length);
        uint256[] memory quantities = new uint256[](allDistributors.length);
        uint256 index = 0;

        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                productIds[index] = allDistributors[i].totalProducts;
                quantities[index] = allDistributors[i].totalDistributions;
                index++;
            }
        }
        return (productIds, quantities);
    }


    function buy(uint256 productId, uint256 quantity) public payable onlyVerifiedDistributor {
        require(quantity > 0, "Quantity must be greater than zero");

        ( , uint256 price, , , , uint256 availableQuantity, , , ,) = productManagement.getProductDetails(productId);


        require(availableQuantity >= quantity, "Insufficient stock");

        uint256 totalPrice = price * quantity;
        
        require(msg.value >= totalPrice, "Insufficient funds");

        uint256 trackingId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, productId, quantity)));

        productManagement.purchaseProduct{value: totalPrice}(productId, quantity);

        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].distributorAddress == msg.sender) {
                allDistributors[i].totalProducts -= quantity;  
                allDistributors[i].totalSales += totalPrice; 
                break;
            }
        }


        payable(msg.sender).transfer(totalPrice);


        emit ProductPurchased(productId, msg.sender, quantity, totalPrice, trackingId);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }


    function viewDistributorRevenue(uint256 distributorId) public view returns (uint256) {
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                return allDistributors[i].totalSales; 
            }
        }
        revert("Distributor not found");
    }


    function viewDistributorProducts(uint256 distributorId) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory productIds = new uint256[](allDistributors.length);
        uint256[] memory productQuantities = new uint256[](allDistributors.length);
        uint256 index = 0;

        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                productIds[index] = distributorId; 
                productQuantities[index] = allDistributors[i].totalProducts;
                index++;
            }
        }

        return (productIds, productQuantities);
    }

    function showAllDistributors() public view returns (Distributor[] memory) {
        return allDistributors;
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
