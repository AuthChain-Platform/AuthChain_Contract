// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./UserRoleManager.sol";

    /**
    * @title ProductManagement
    * @dev A contract for managing products, tracking product history, registering manufacturers, and handling product purchases and transfers.
     */

contract ProductManagement {

    address public owner;
    UserRoleManager public userRoleManager;

    struct ProductHistoryEntry {
        address actor;
        string action;
        uint256 timestamp;
        string details;
    }



    ProductHistoryEntry[] public historyLogs;
    
    struct ItemAction {
        address actor;
        string action;
        uint256 timestamp;
    }

    mapping(uint256 => ItemAction[]) private itemHistory;

    
    enum ProductStatus {
        MANUFACTURED,         
        IN_TRANSIT_TO_LOGISTICPERSONNEL,  
        IN_TRANSIT_TO_RETAILER, 
        WITH_RETAILER,      
        SOLD_TO_CONSUMER,    
        RETURNED,  
        RECALLED,
        AVAILABLE_FOR_SALE,
        NON_EXISTENT
    }

    struct Product {
        uint256 productCode;
        string name;
        uint256 price;
        uint256 batchID;
        uint256 expiryDate;
        string productDescription;
        uint256 batchQuantity;
        uint256 availableQuantity;
        string productImage;
        ProductStatus status;
        address owner; 
        uint256 trackingID; 
    }
    
    
    Product[] public products; 
    mapping(uint256 => Product) public productID;
    
    mapping(uint256 => Product) public productDetails;
    mapping(uint256 => bool) public isAvailable;  


    struct ProductItem {
        uint256 itemID;
        uint256 productCode;
        uint256 batchID;
        address owner;
        ProductStatus status;
    }

    mapping(uint256 => ProductItem) public itemDetails;
    uint256 public nextItemID;

    
    struct Manufacturer {
        string brandName;
        bool verify;
        string nafdac_no;
        string registration_no;
        uint256 yearOfRegistration;
        string location;
        string state;
        string image;
        uint256 totalProducts;
        uint256[] productCodes;
    }

    mapping(uint256 => bool) public isVerified; 
    mapping(address => Manufacturer) public manufacturers;
    address[] public manufacturerAddresses;


    // =========================EVENTS=================================

    event ProductSold(uint256 indexed productId, address indexed buyer, uint256 quantity);
    event ProductStatusUpdated(uint256 indexed productCode, ProductStatus indexed newStatus);
    event ProductUpdated(uint256 indexed productCode, address indexed newOwner, uint256 indexed newQuantity);
    event ProductOrder(uint256 indexed productCode, address indexed buyer, uint256 indexed quantity);
    event ProductAdded(uint256 indexed productCode, address indexed owner, uint256 indexed trackingID);
    event OrderReceived(address indexed buyer, uint256 indexed productCode, uint256 quantity, uint256 totalPrice);
    event OrderReceivedusUpdated(uint256 indexed productCode, ProductStatus indexed newStatus);
    event ProductTransferred(uint256 indexed productCode, address indexed newOwner);
    event ManufacturerRegistered(address indexed manufacturerAddress, string indexed brandName, string indexed nafdac_no, string registration_no, uint256 yearOfRegistration, string location, string state, string image);
    event ManufacturerDeregistered(address indexed manufacturerAddress);
    event ManufacturerUpdated(address manufacturerAddress, string brandName, string nafdac_no, string registration_no, uint256 yearOfRegistration, string location, string state, string image);
    event ProductActionLogged(uint256 indexed productId, address indexed actor, string action, uint256 timestamp, string indexed details);

    mapping(uint256 => ProductHistoryEntry[]) public productHistories;




    constructor(address _userRoleManager) {
        require(_userRoleManager != address(0), "Invalid UserRoleManager address");

        userRoleManager = UserRoleManager(_userRoleManager);
        owner = msg.sender; 
    }


    // =========================PRODUCT HISTORY LOGGING=================================

    function logProductAction(uint256 productId, string memory action, string memory details) internal {
        address actor = msg.sender;

        ProductHistoryEntry memory newEntry = ProductHistoryEntry({
            actor: actor,
            action: action,
            timestamp: block.timestamp,
            details: details
        });
        productHistories[productId].push(newEntry);

        emit ProductActionLogged(productId, actor, action, block.timestamp, details);

    }


    // function getHistoryOfItem(uint256 itemId) external view returns (ItemAction[] memory) {
    //     return itemHistory[itemId];
    // }



    function generateTrackingID(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed)));
    }

    function getProductHistory(uint256 productId) public view returns (ProductHistoryEntry[] memory) {
        require(isAvailable[productId], "Product not found");

        return productHistories[productId];
    }

    function addProduct(
        uint256 _productCode,
        string memory _name,
        uint256 _price,
        uint256 _batchID,
        uint256 _expiryDate,
        string memory _productDescription,
        uint256 _batchQuantity,
        string memory _productImage

    ) public {
        
        require(!isAvailable[_productCode], "Product already exists");
        
        require(
        userRoleManager.getUserRole(msg.sender) == UserRoleManager.userRole.Manufacturer,
        "Only manufacturers can add products");

        uint256 _trackingID = generateTrackingID(_productCode);

        Product memory newProduct = Product({
            productCode: _productCode,
            name: _name,
            price: _price,
            batchID: _batchID,
            expiryDate: _expiryDate,
            productDescription: _productDescription,
            batchQuantity: _batchQuantity,
            availableQuantity: _batchQuantity,
            productImage: _productImage,
            status: ProductStatus.MANUFACTURED,
            owner: msg.sender,
            trackingID: _trackingID
        });

       products.push(newProduct);
        productDetails[_productCode] = newProduct;
        isAvailable[_productCode] = true;

        // Register individual items
        for (uint256 i = 0; i < _batchQuantity; i++) {
            nextItemID++;
            itemDetails[nextItemID] = ProductItem({
                itemID: nextItemID,
                productCode: _productCode,
                batchID: _batchID,
                owner: msg.sender,
                status: ProductStatus.MANUFACTURED
            });

        logProductAction(_productCode, "Added", "Product added with initial batch quantity");

        emit ProductAdded(_productCode, msg.sender, _trackingID);

        }

    }
  
    function getProductDetails(uint256 productCode) public view returns (
        string memory name,
        uint256 price,
        uint256 batchID,
        uint256 expiryDate,
        string memory productDescription,
        uint256 availableQuantity, 
        string memory productImage,
        ProductStatus status,
        address _owner,
        uint256 trackingID
    ) {
        require(isAvailable[productCode], "Product not found");
        
        Product memory product = productDetails[productCode];
        return (
            product.name,
            product.price,
            product.batchID,
            product.expiryDate,
            product.productDescription,
            product.availableQuantity, 
            product.productImage,
            product.status,
            product.owner,
            product.trackingID
        );
    }

    function updateProductStock(uint256 productId, uint256 newQuantity) public {
        
        require(products[productId].productCode != 0, "Product does not exist");

        products[productId].availableQuantity = newQuantity;
    }


    // returns a single item from a batch
    function getItemDetails(uint256 itemID) public view returns (
        uint256 productCode,
        uint256 batchID,
        address _owner,
        ProductStatus status

    ) 
    {
        require(itemDetails[itemID].itemID == itemID, "Item not found");

        ProductItem memory item = itemDetails[itemID];

        return (item.productCode, item.batchID, item.owner, item.status);
    }


    function getProductLength() public view returns (uint256) {
        return products.length;
    }


    function getProductByCode(uint256 productCode) public view returns (Product memory) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].productCode == productCode) {
                return products[i];
            }
        }
        revert("Product not found");
    }

    function checkProductAvailability(uint256 _productCode) public view returns (string memory name, string memory productImage, string memory description, address _owner, uint256 price) {
        require(isAvailable[_productCode], "Product not found");

        Product memory product = productDetails[_productCode];
        return (product.name, product.productImage, product.productDescription, product.owner, product.price);
    }

    function orderProduct(uint256 productId, uint256 numberOfUnits) external {

        require(isAvailable[productId], "Product not available for sale");

        Product storage product = productDetails[productId];
        require(product.availableQuantity >= numberOfUnits, "Not enough stock");

        uint256 totalPrice = product.price * numberOfUnits;

        product.availableQuantity -= numberOfUnits;

        if (product.availableQuantity == 0) {
            isAvailable[productId] = false;
        }

        for (uint256 i = 1; i <= numberOfUnits; i++) {
            uint256 itemID = nextItemID - product.availableQuantity - i;
            itemDetails[itemID].owner = msg.sender;
            itemDetails[itemID].status = ProductStatus.SOLD_TO_CONSUMER;
        }

        product.owner = msg.sender;
        product.trackingID = generateTrackingID(productId);

        logProductAction(productId, "Product Purchased", string(abi.encodePacked("Quantity: ", (numberOfUnits), " Total Price: ", (totalPrice))));

        emit ProductOrder(productId, msg.sender, numberOfUnits);

    }


    function updateProductStatus(uint256 productCode, ProductStatus newStatus) public {
        require(isAvailable[productCode], "Product not found");

        Product storage product = productDetails[productCode];

        product.status = newStatus;

        logProductAction(productCode, "Product Status Updated", string(abi.encodePacked("New Status: ", (uint256(newStatus)))));
        emit ProductStatusUpdated(productCode, newStatus);
    }


    // function getProductOwner(uint256 productCode) public view returns (address) {
    //     Product memory product = getProductByCode(productCode);
    //     return product.owner;
    // }

    function getAllProducts() public view returns (Product[] memory) {
        return products;
    }


    // function getProductQuantity(uint256 productId) public view returns (uint256) {
    //     return products[productId].availableQuantity;
    // }


    function markProductAsSold(uint256 productId, uint256 numberOfUnits) public {
        require(products[productId].availableQuantity >= numberOfUnits, "Not enough stock to sell");

        products[productId].availableQuantity -= numberOfUnits;

        products[productId].trackingID = generateTrackingID(productId);

        if (products[productId].availableQuantity == 0) {
            isAvailable[productId] = false; 
        }

        logProductAction(productId, "Product Sold", string(abi.encodePacked("Quantity: ", (numberOfUnits))));
        emit ProductSold(productId, msg.sender, numberOfUnits);
    }

    function transferProductOwnership(uint256 productId, address newOwner) public {
        require(isAvailable[productId], "Product not found");

        Product storage product = productDetails[productId];

        product.owner = newOwner;
        product.trackingID = generateTrackingID(productId);

        logProductAction(productId, "Product Ownership Transferred", string(abi.encodePacked("New Owner: ", (newOwner))));
        emit ProductTransferred(productId, newOwner);
    }

    // Function to check if a product is expired
    function checkProductExpiration(uint256 productCode) public view returns (bool isExpired, uint256 expiryDate) {
        require(isAvailable[productCode], "Product not found");

        Product memory product = productDetails[productCode];

        // Compare the current timestamp with the product's expiry date
        if (block.timestamp > product.expiryDate) {
            return (true, product.expiryDate); // Product is expired
        } else {
            return (false, product.expiryDate); // Product is not expired
        }
    }



    // ==================Manufacturer Functions =================================

    function registerManufacturer(
        string memory brandName,
        string memory nafdac_no,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image
    ) public {
        require(!manufacturers[msg.sender].verify, "Manufacturer already registered");

        Manufacturer storage manufacturer = manufacturers[msg.sender];
        manufacturer.brandName = brandName;
        manufacturer.verify = true;
        manufacturer.nafdac_no = nafdac_no;
        manufacturer.registration_no = registration_no;
        manufacturer.yearOfRegistration = yearOfRegistration;
        manufacturer.location = location;
        manufacturer.state = state;
        manufacturer.image = image;

        manufacturerAddresses.push(msg.sender);

        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Manufacturer);


        emit ManufacturerRegistered(
            msg.sender, 
            brandName, 
            nafdac_no, 
            registration_no, 
            yearOfRegistration, 
            location, 
            state, 
            image
        );
    }


    function getAllManufacturers() public view returns (address[] memory) {
        return manufacturerAddresses;
    }


    function getProductsByManufacturer() public view returns (Product[] memory) {
        address manufacturer = msg.sender;
        uint256 count = 0;

        for (uint256 i = 0; i < products.length; i++) {
            if (products[i].owner == manufacturer) {
                count++;
            }
        }

        Product[] memory manufacturerProducts = new Product[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < products.length; i++) {
            if (products[i].owner == manufacturer) {
                manufacturerProducts[index] = products[i];
                index++;
            }
        }

        return manufacturerProducts;
    }



    // function checkMyRole() public view returns (UserRoleManager.userRole) {
    //     return userRoleManager.getUserRole(msg.sender);
    //     } 

}