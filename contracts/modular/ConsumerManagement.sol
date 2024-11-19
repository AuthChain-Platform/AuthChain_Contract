// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./UserRoleManager.sol";
import "./ProductManagement.sol";

contract ConsumerManagement {

    uint256 public id = 0;
    address public owner;
    UserRoleManager public userRoleManager;
    ProductManagement public productManagement;

    // Consumer Struct
    struct Consumer {
        uint256 id;
        string name;
        string email;
        string location;
        string state;
        string image;
        string physicalAddress;
        bool verified;
        uint256 totalProductsBought;
    }

    mapping(address => Consumer) public consumers;
    mapping(address => uint256[]) public consumerPurchases;
    address[] public allConsumers;
    mapping(address => UserRoleManager.userRole) public consumerRoles;

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyVerifiedConsumer() {
        require(consumers[msg.sender].verified == true, "Only verified consumers can perform this action");
        _;
    }

    constructor(address _userRoleManager, address _productManagement) {
        owner = msg.sender;
        userRoleManager = UserRoleManager(_userRoleManager);
        productManagement = ProductManagement(_productManagement);
    }

    function registerConsumer(
        string memory name,
        string memory email,
        string memory location,
        string memory state,
        string memory image,
        string memory physicalAddress
    ) public {
        require(consumers[msg.sender].id == 0, "Consumer is already registered");

        uint256 newConsumerId = ++id; 

        Consumer storage newConsumer = consumers[msg.sender];
        newConsumer.id = newConsumerId;
        newConsumer.name = name;
        newConsumer.email = email;
        newConsumer.location = location;
        newConsumer.state = state;
        newConsumer.image = image;
        newConsumer.physicalAddress = physicalAddress;
        newConsumer.verified = true;
        newConsumer.totalProductsBought = 0;

        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Consumers);
        
        consumerRoles[msg.sender] = UserRoleManager.userRole.Consumers;

        allConsumers.push(msg.sender);
    }

        function checkRetailerRole(address consumersAddress) public view returns (string memory) {
        if (consumerRoles[consumersAddress] == UserRoleManager.userRole.Consumers) {
            return "Retailer";
        }
        return "No Role";
    }



    function updateConsumerInfo(
        string memory name,
        string memory email,
        string memory physicalAddress
    ) public onlyVerifiedConsumer {
        Consumer storage consumer = consumers[msg.sender];
        consumer.name = name;
        consumer.email = email;
        consumer.physicalAddress = physicalAddress;
    }


    function verifyConsumer(address consumerAddress) public onlyAdmin {
        consumers[consumerAddress].verified = true;
    }


    function deregisterConsumer(address consumerAddress) public onlyAdmin {
        delete consumers[consumerAddress];
        delete consumerPurchases[consumerAddress];

        for (uint256 i = 0; i < allConsumers.length; i++) {
            if (allConsumers[i] == consumerAddress) {
                allConsumers[i] = allConsumers[allConsumers.length - 1];
                allConsumers.pop();
                break;
            }
        }
    }


    function getConsumerDetails(address consumerAddress) public view returns (Consumer memory) {
        return consumers[consumerAddress];
    }

    function getConsumerPurchases(address consumerAddress) public view returns (uint256[] memory) {
        return consumerPurchases[consumerAddress];
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

        require(status != ProductManagement.ProductStatus.NON_EXISTENT, "Product does not exist");

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
