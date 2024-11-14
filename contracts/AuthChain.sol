// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./lib/error.sol";
import "./lib/event.sol";

contract AuthChain {
    address public adminUser;
    constructor() {
        adminUser = msg.sender;
    }

    // user roles to manage access controls
    enum userRole { 
        Default, 
        Consumers, 
        Manufacturer, 
        LogisticsPersonnel, 
        Retailers, 
        Admin 
    }
    // enum ProductStatus { 
    //     MANUFACTURED, 
    //     WITH_RETAILER, 
    //     SOLD_TO_CONSUMER 
    // }

    // Event role to manage events
    event UserRoleAssigned(
        address indexed userAddress,
        userRole role
    );

    // PRODUCT
    struct Product {
        uint256 productCode;
        string name;
        uint256 price;
        string batch;
        uint256 batchID;
        string productionDate;
        string expiryDate;
        string productDescription;
        uint256 quantity;
        uint256 availableQuantity; // Quantity still with manufacturer
        string productImage;
        ProductStatus status;
    }

    // MANUFACTURER
    struct Manufacturer {
        string brandName;
        bool verify;
        string nafdac_no;
        string registration_no;
        uint256 yearOfRegistration;
        string location;
        userRole role;
        uint256 totalProducts;
        mapping(uint256 => Product) inventory;
    }

    // LOGISTICS PERSONNEL
    struct LogisticsPersonnel {
        address logisticsAddress;
        uint256 uid;
        string brandName;
        bool active;
        userRole role;
    }

    // RETAILER
    struct Retailer {
        string brandName;
        userRole role;
        mapping(uint256 => RetailerStock) inventory; // productId => RetailerStock
    }

    // RETAILER STOCK
    struct RetailerStock {
        uint256 quantity;
        uint256 receivedDate;
        uint256 remainingQuantity;
        uint256 batchID;
        address logisticPersonnelToDeliver;
    }

   // CONSUMER
    struct Consumer {
        userRole role;
        mapping(uint256 => uint256) purchaseQuantities; // productId => quantity
        mapping(uint256 => uint256) purchaseTimes; // productId => purchaseTime
        mapping(uint256 => bool) hasPurchased; // productId => whether purchased
        uint256 batchID;
    }


    struct Admin {
        userRole role;
    }

    // Tracking Product and Status updates
    enum ProductStatus {
        MANUFACTURED,         
        IN_TRANSIT_TO_LOGISTICPERSONNEL,  
        IN_TRANSIT_TO_RETAILER, 
        WITH_RETAILER,      
        SOLD_TO_CONSUMER,    
        RETURNED,  
        RECALLED
    }

    struct ManufacturerToLogisticStatus {
        bool manufacturerDelivered;
        bool logisticAccepted;
    }

    struct LogisticToRetailerStatus {
        bool logisticDelivered;
        bool RetailerAccepted;
    }

    struct RetailerToLogisticStatus{
        bool retailerDelivered;
        bool logisticReceived;
    }

    struct LogisticToCustomerStatus{
        bool logisticDelivered;
        bool customerReceived;
    }

    struct TrackingStruct {
        Manufacturer manufacturer;
        LogisticsPersonnel logisticsPersonnel;
        Retailer retailer;
        Consumer consumer;
        ManufacturerToLogisticStatus manufacturerToLogistic;
        LogisticToRetailerStatus logisticToRetailer;
        RetailerToLogisticStatus retailerToLogistic;
        LogisticToCustomerStatus logisticToCustomer;
        ProductStatus productStatus;
    }


    //mapping to retrieve users
    mapping (address => Manufacturer) manufacturer;
    mapping (address => LogisticsPersonnel) logisticsPersonnel;
    mapping (address => Retailer) retailer;
    mapping (address => Consumer) consumer;
    mapping(address => Admin) admin;
    mapping(uint256 => address[]) public productTrail;

    //tracking based on product code to tracking struct
    mapping(uint256 => TrackingStruct) trackingHistory;

    // private functions for access control
    function onlyManfacturer() private view {
        if(uint(manufacturer[msg.sender].role) != 2) {
            revert Errors.NotAManufacturer();
        }
    }

    function onlyRetailer() private view {
        if(uint(retailer[msg.sender].role) != 4) {
            revert Errors.NotARetailer();
        }
    }

    function onlyAdmin() private view {
        if(uint(admin[msg.sender].role) != 5) {
            revert Errors.NotAnAdmin();
        }
    }

    function onlyadminUser() private view {
        if(msg.sender != adminUser) {
            revert Errors.NotAnAdminUser();
        }
    }


    /**
     * Registering a manufacturer 
     * @param _brandName: the name of the manufacturer
     */
    function registerManufacturer(
        string memory _brandName,
        string memory _nafdac_no,
        string memory _registration_no,
        uint256 _yearOfRegistration,
        string memory _location
    ) external {
        // Create the manufacturer in storage directly instead of memory
        manufacturer[msg.sender].brandName = _brandName;
        manufacturer[msg.sender].verify = false;
        manufacturer[msg.sender].nafdac_no = _nafdac_no;
        manufacturer[msg.sender].registration_no = _registration_no;
        manufacturer[msg.sender].yearOfRegistration = _yearOfRegistration;
        manufacturer[msg.sender].role = userRole.Default;
        manufacturer[msg.sender].location = _location;
        manufacturer[msg.sender].totalProducts = 0;

        emit Events.ManufacturerRegistered(msg.sender, _brandName, _nafdac_no, _yearOfRegistration);
    }



    /**
     * Adding a product to the inventory of a manufacturer
     * @param _productCode: the code of the product
     * @param _productName: the name of the product
     */
    
   function addToInventory(
        uint256 _productCode,
        string memory _productName,
        string memory _description,
        uint256 _price,
        string memory _expiryDate,
        uint256 _batchID,
        uint256 _quantity,
        string memory _productionDate,
        string memory _batch,
        string memory _productImage
    ) public {
        onlyManfacturer();
        require(_quantity > 0, "Quantity must be greater than 0");

        Product memory newProduct = Product({
            productCode: _productCode,
            name: _productName,
            price: _price,
            batch: _batch,
            batchID: _batchID,
            productionDate: _productionDate,
            expiryDate: _expiryDate,
            productDescription: _description,
            quantity: _quantity,
            availableQuantity: _quantity,
            productImage: _productImage,
            status: ProductStatus.MANUFACTURED
        });

        manufacturer[msg.sender].inventory[_productCode] = newProduct;
        manufacturer[msg.sender].totalProducts++;
        
        emit Events.ProductAdded(_productCode, _productName, _quantity, msg.sender);
    }

    /**
     * Registering a logistics personnel
     */
    function registerLogisticsPersonnel(
        address _logisticsAddress,
        uint256 _uid,
        string memory _brandName
    ) external {
        onlyManfacturer();
        if(manufacturer[msg.sender].verify != true) {
            revert Errors.ManufacturerNotVerified();
        }
        LogisticsPersonnel memory logisticsPersonnelData = LogisticsPersonnel({
            logisticsAddress: _logisticsAddress,
            uid: _uid,
            brandName: _brandName,
            active: true,
            role: userRole.Default
        });

        logisticsPersonnel[_logisticsAddress] = logisticsPersonnelData;
    }

    /**
     * Registering a retailer
     * @param _brandName: the name of the retailer
     */
    function registerRetailer(
        string memory _brandName
    ) external {
        // Initialize directly in storage instead of using struct constructor
        retailer[msg.sender].brandName = _brandName;
        retailer[msg.sender].role = userRole.Retailers;

        emit Events.RetailerRegistered(msg.sender, _brandName);
    }
   
    function registerConsumer() external {
        consumer[msg.sender].role = userRole.Default;
        emit Events.RetailerRegistered(msg.sender, "Consumer");
    }

    /**
     * Transfer a product from a manufacturer to a retailer
     * @param _productCode: the code of the product
     * @param _quantity: the quantity of the product to transfer
     */
    function transferToRetailer(
        uint256 _productCode,
        address _retailer,
        uint256 _quantity,
        address _logisticPersonnelAddress
    ) public {
        onlyManfacturer();
        // checks if the retailer is present or verified to be a retailer
        require(retailer[_retailer].role == userRole.Retailers, "Retailer not verified");
        // fetches product details from manufacturer
        Product storage product = manufacturer[msg.sender].inventory[_productCode];
        // is this product manufactured and or listed to the market
        require(product.status == ProductStatus.MANUFACTURED, "Product not available for transfer");

        require(product.availableQuantity >= _quantity, "Insufficient quantity available");

        if(logisticsPersonnel[_logisticPersonnelAddress].active == false){
            revert NotARetailer();
        }
    
        // Update manufacturer's available quantity
        product.availableQuantity -= _quantity;
    
        // Update retailer's inventory with batchID
        RetailerStock storage newStock = retailer[_retailer].inventory[_productCode];
        newStock.quantity = _quantity;
        newStock.receivedDate = block.timestamp;
        newStock.remainingQuantity = _quantity;
        newStock.batchID = product.batchID;  // Add the batchID from the product
        newStock.logisticPersonnelToDeliver = _logisticPersonnel;
        
        Manufacturer storage manufact = manufacturer[msg.sender];
        TrackingStruct storage trackProduct = trackingHistory[newStock.batchID];
        trackProduct.manufacturer.brandName =  manufact.brandName;
        trackProduct.manufacturer.verify = manufact.verify;
        trackProduct.manufacturer.nafdac_no = manufact.nafdac_no;
        trackProduct.manufacturer.registration_no = manufact.registration_no;
        trackProduct.manufacturer.yearOfRegistration = manufact.yearOfRegistration;
        trackProduct.manufacturer.location = manufact.location;
        trackProduct.manufacturer.role = manufact.role;
        trackProduct.manufacturer.totalProducts = manufact.totalProducts;
        trackProduct.manufacturer.inventory[_productCode] = manufact.inventory[_productCode];

        LogisticsPersonnel storage logist = logisticsPersonnel[_logisticPersonnel];
        trackProduct.logisticsPersonnel.logisticsAddress = logist.logisticsAddress;
        trackProduct.logisticsPersonnel.uid = logist.uid;
        trackProduct.logisticsPersonnel.brandName = logist.brandName;
        trackProduct.logisticsPersonnel.active = logist.active;
        trackProduct.logisticsPersonnel.role = logist.role;

        Retailer storage reta = retailer[_retailer];
        trackProduct.retailer.brandName = reta.brandName;
        trackProduct.retailer.role = reta.role;
        trackProduct.retailer.inventory[_productCode] = newStock;

        trackProduct.manufacturerToLogistic.manufacturerDelivered = true;
        trackProduct.productStatus = ProductStatus.IN_TRANSIT_TO_LOGISTICPERSONNEL;
        emit Events.ProductToRetailer(_productCode, _retailer, _quantity);
}

    /**
     * Transfer a product from a retailer to a consumer
     * @param _productCode: the code of the product
     * @param _quantity: the quantity of the product to transfer
     */
    function sellToConsumer(
        uint256 _productCode,
        address _consumerAddress,
        uint256 _quantity
) public {
    onlyRetailer();
    
    RetailerStock storage currentStock = retailer[msg.sender].inventory[_productCode];
    require(currentStock.remainingQuantity >= _quantity, "Insufficient quantity in stock");
    
    // Update retailer's remaining quantity
    currentStock.remainingQuantity -= _quantity;
    
    // Update consumer record with batch information
    Consumer storage consumerData = consumer[_consumerAddress];
    consumerData.role = userRole.Consumers;
    consumerData.purchaseQuantities[_productCode] = _quantity;
    consumerData.purchaseTimes[_productCode] = block.timestamp;
    consumerData.hasPurchased[_productCode] = true;
    consumerData.batchID = currentStock.batchID; // Store the batchID
    
    emit Events.ProductSoldToConsumer(_productCode, _consumerAddress, _quantity);
}


    // function to register admin

    function registerAdmin(address adminAddress) external {
        onlyadminUser();
        Admin memory adminData = Admin({
            role: userRole.Admin
        });

        admin[adminAddress] = adminData;
    }


   
    function verifyManufacturer(
        address manufacturerAddress
    ) external {
        onlyAdmin();
        Manufacturer storage m = manufacturer[manufacturerAddress];

        m.verify = true;
    }


    // function assignAdmin(address adminAddress) external {
    //     onlyadminUser();
    //     admin[adminAddress].role = userRole.Admin;
    // }


    // handles assigning user roles
    function assignUserRoles(address userAddress, userRole role) external {
        onlyAdmin();
        if(uint(role) == 2) {
            manufacturer[userAddress].role = userRole.Manufacturer;
        }

        if(uint(role) == 3) {
            manufacturer[userAddress].role = userRole.LogisticsPersonnel;
        }

        if(uint(role) == 1) {
            manufacturer[userAddress].role = userRole.Consumers;
        }

        if(uint(role) == 4) {
            manufacturer[userAddress].role = userRole.Retailers;
        }

        
    }

    // getters functions

    function getManufacturer(address manufacturerAddress) external view returns(
        string memory brandName,
        bool verify,
        string memory nafdac_no,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        userRole role,
        uint256 totalProducts
    ) {
        Manufacturer storage manufacturerData = manufacturer[manufacturerAddress];
        return (
            manufacturerData.brandName,
            manufacturerData.verify,
            manufacturerData.nafdac_no,
            manufacturerData.registration_no,
            manufacturerData.yearOfRegistration,
            manufacturerData.location,
            manufacturerData.role,
            manufacturerData.totalProducts
        );
    }

    function getLogisticsPersonnel(address logisticsPersonnelAddress) external view returns(LogisticsPersonnel memory LogisticsPersonnelDetails) {
        LogisticsPersonnelDetails = logisticsPersonnel[logisticsPersonnelAddress];
    }

    function getRetailer() external view returns(
        string memory brandName,
        userRole role
    ) {
        // Get retailer data for msg.sender
        return (
            retailer[msg.sender].brandName,
            retailer[msg.sender].role
        );
    }

    

    function getConsumer() external view returns(
        userRole role,
        bool hasRegistered
    ) {
        return (
            consumer[msg.sender].role,
            consumer[msg.sender].role != userRole.Default
        );
    }

    function getAdmin(address adminAddress) external view returns(Admin memory adminDetails) {
        adminDetails = admin[adminAddress];
    }
}