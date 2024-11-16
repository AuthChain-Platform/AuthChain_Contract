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
        string physicalAddress;
        bool verified;
        uint256 totalProductsBought;
        mapping(uint256 => uint256) purchasedProducts;
    }

    mapping(address => Consumer) public consumers;

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyVerifiedConsumer() {
        require(consumers[msg.sender].verified, "Only verified consumers can perform this action");
        _;
    }

    constructor(address _userRoleManager, address _productManagement) {
        owner = msg.sender;
        userRoleManager = UserRoleManager(_userRoleManager);
        productManagement = ProductManagement(_productManagement);
    }

    // Register a new consumer
    function registerConsumer(
        string memory name,
        string memory email,
        string memory physicalAddress
    ) public onlyAdmin {

        uint256 newConsumerId = id + 1;
        Consumer storage newConsumer = consumers[msg.sender];

        newConsumer.id = newConsumerId;
        newConsumer.name = name;
        newConsumer.email = email;
        newConsumer.physicalAddress = physicalAddress;
        newConsumer.verified = true;
        newConsumer.totalProductsBought = 0;

        // Assign the Consumers role to the new consumer
        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Consumers);
    }

    function buyProduct(uint256 productCode, uint256 quantity) public payable onlyVerifiedConsumer {
        
        require(productManagement.isProductAvailable(productCode), "Product not available for sale");
       
        uint256 productPrice = productManagement.getProductPrice(productCode);
        uint256 totalPrice = productPrice * quantity;
        
        require(msg.value >= totalPrice, "Insufficient payment");

        productManagement.buyProduct{value: totalPrice}(productCode, quantity);

        Consumer storage consumer = consumers[msg.sender];
        
        for (uint256 i = 0; i < quantity; i++) {
            consumer.purchasedProducts[consumer.totalProductsBought] = productCode;
            consumer.totalProductsBought++;
        }
    }

    // Consumer sells a product to another consumer
    function sellProduct(address buyerAddress, uint256 productCode) public onlyVerifiedConsumer {
 
        Consumer storage seller = consumers[msg.sender];        // Confirms the product is owned by the seller
       
        bool ownsProduct = false;

        for (uint256 i = 0; i < seller.totalProductsBought; i++) {
            if (seller.purchasedProducts[i] == productCode) {
                ownsProduct = true;
                break;
            }
        }

        require(ownsProduct, "You do not own this product");

        // Transfer the product ownership 
        seller.totalProductsBought--;
       
        for (uint256 i = 0; i < seller.totalProductsBought; i++) {
            if (seller.purchasedProducts[i] == productCode) {
                seller.purchasedProducts[i] = seller.purchasedProducts[seller.totalProductsBought];
            }
        }

        // Add product to the buyer's profile
        Consumer storage buyer = consumers[buyerAddress];
        buyer.purchasedProducts[buyer.totalProductsBought] = productCode;
        buyer.totalProductsBought++;

        // Updates product status to show the new owner of the product
        productManagement.transferProductOwnership(productCode, buyerAddress);
    }

    // Update consumer information
    function updateConsumerInfo(

        string memory physicalAddress
    ) public {
        Consumer storage consumer = consumers[msg.sender];
        consumer.physicalAddress = physicalAddress;
    }

    // Deregister a consumer
    function deregisterConsumer(address consumerAddress) public onlyAdmin {
        delete consumers[consumerAddress];
    }

    // Verify a consumer
    function verifyConsumer(address consumerAddress, bool isVerified) public onlyAdmin {
        consumers[consumerAddress].verified = isVerified;
    }

    // Get consumer details
    function getConsumerDetails(address consumerAddress) public view returns (string memory name, string memory email, string memory physicalAddress, bool verified) {
        Consumer storage consumer = consumers[consumerAddress];
        return (consumer.name, consumer.email, consumer.physicalAddress, consumer.verified);
    }

    // View all purchased products by a consumer
    function viewPurchasedProducts(address consumerAddress) public view returns (uint256[] memory) {
        Consumer storage consumer = consumers[consumerAddress];
        
        uint256[] memory products = new uint256[](consumer.totalProductsBought);
        
        for (uint256 i = 0; i < consumer.totalProductsBought; i++) {
            products[i] = consumer.purchasedProducts[i];
        }
        return products;
    }
}
