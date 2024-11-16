// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../lib/event.sol";

contract ProductManagement {

    uint256 batchId;

    struct Product {
        string name;
        uint256 price;
        uint256 originalQuantityFromCreation;
        uint256 quantityInStock;
        uint256 productionDate;
        uint256 expiryDate;
        string productDescription;
        string productImage;
        address[] listOfAllOwners;  // Track owner of the product
        bool available;
    }

    mapping(uint256 => Product) public products;
    
    uint256[] public productList;

    event ProductSold(uint256 productCode, address buyer, uint256 quantity);
    event ProductStatusUpdated(uint256 productCode, string newStatus);

    // Add new product
    function createProduct(
        string memory name,
        uint256 _expiryDate,
        string memory productDescription,
        uint256 quantity,
        uint256 _productionDate,
        string memory productImage
    ) internal returns(uint256) {
        //require(products[batchId].productCode == 0, "Product already exists");

        batchId += 1;
        Product storage newProduct = products[batchId];
        newProduct.name = name;
        newProduct.price = 0;
        newProduct.originalQuantityFromCreation = quantity;
        newProduct.quantityInStock = quantity;
        newProduct.productionDate = _productionDate;
        newProduct.expiryDate = _expiryDate;
        newProduct.productDescription = productDescription;
        newProduct.productImage = productImage;
        newProduct.listOfAllOwners.push(msg.sender); 
        newProduct.available = true;
        
        productList.push(batchId);

        return batchId;
        
    }

    function verifyProductStats(uint256 _batchId) internal view returns (string memory) {
    require(products[_batchId].quantityInStock > 0, "Product not found");

        uint256 quantityInStock = products[_batchId].quantityInStock;
        uint256 originalQuantity = products[_batchId].originalQuantityFromCreation;

        if (quantityInStock == 0) {
            return "Out of Stock";
        } else if (quantityInStock < originalQuantity / 4) {
            // Here 'low stock' means less than 25% of the original quantity
            return "Low Stock";
        } else {
            return "Available";
        }
    }

    function listProductToMarket(uint256 _batchId, 
        uint256 _price, 
        uint256 _quantity) external {
        require(products[_batchId].price != 0, "Product Do not Exist");

        //need chainlink pricefeed here to convert price to USD

        Product storage productForMarket = products[_batchId];
        require(productForMarket.available == false, "Product Is Non Existence");

        productForMarket.price = _price;

        string prodName = productForMarket.name;
        uint256 quantityInStock = productForMarket.quantityInStock;
        uint256 prodDate = productForMarket.productionDate;
        uint256 expDate = productForMarket.expiryDate;
        string _status = verifyProductStats(batchId);
        // if(_status == "Available"){
        //     _status = "Listed";
        // }
        string prdImage = productForMarket.productImage;

        emit Events.ProductSuccessfullyListedToMarket(_batchId, prodName,
        quantityInStock, prodDate, expDate, _status, prdImage);
    }




        // Get product details
    function getProduct(uint256 productCode) public view returns (Product memory) {
        require(products[productCode].productCode != 0, "Product not found");
        return products[productCode];
    }

    // Check if product is available for sale
    function isProductAvailable(uint256 productCode) public view returns (bool) {
        return products[productCode].status == ProductStatus.AVAILABLE_FOR_SALE && products[productCode].availableQuantity > 0;
    }

    // Buy product function
    function buyProduct(uint256 productCode, uint256 quantity) public payable {
    
        require(products[productCode].productCode != 0, "Product not found");
        require(products[productCode].status == ProductStatus.AVAILABLE_FOR_SALE, "Product not available for sale");
        require(products[productCode].availableQuantity >= quantity, "Not enough stock available");
        
        uint256 totalPrice = products[productCode].price * quantity;
        require(msg.value >= totalPrice, "Insufficient payment");

        // Transfer ownership and reduce available quantity
        products[productCode].availableQuantity -= quantity;
        products[productCode].owner = msg.sender;

        emit ProductSold(productCode, msg.sender, quantity);
    }

    function getProductPrice(uint256 productId) public view returns (uint256) {
        require(products[productId].available, "Product is not available");
        
        return products[productId].price;
    }


    // Update product status
    // function updateProductStatus(uint256 productCode, ProductStatus newStatus) public {
    //     Product storage product = products[productCode];
        
    //     require(product.productCode != 0, "Product not found");
    //     require(msg.sender == product.owner, "Only the owner can update product status"); 

    //     product.status = newStatus;
    
    //     emit ProductStatusUpdated(productCode, newStatus);
    // }


    // Transfer product ownership (from manufacturer to retailer)
    function transferProduct(uint256 productCode, address newOwner) public {
        Product storage product = products[productCode];
        
        require(product.productCode != 0, "Product not found");
        require(msg.sender == product.owner, "Only the owner can transfer the product");
        
        product.owner = newOwner;
    }

    // Get all products
    function getAllProducts() public view returns (uint256[] memory) {
        return productList;
    }

    function getProductOwner(uint256 productCode) public view returns (address) {
        require(products[productCode].productCode != 0, "Product not found");
        return products[productCode].owner;
    }

    function markProductAsSold(uint256 productCode) public {
        Product storage product = products[productCode];
        
        require(product.productCode != 0, "Product not found");
        require(product.availableQuantity > 0, "No stock available");

        product.availableQuantity -= 1;  // Reduce available quantity by 1 
       
        if (product.availableQuantity == 0) {
            product.status = ProductStatus.SOLD_TO_CONSUMER; 
        }
    }

    function transferProductOwnership(uint256 productCode, address newOwner) public {
        Product storage product = products[productCode];
       
        require(product.productCode != 0, "Product not found");
        require(msg.sender == product.owner, "Only the owner can transfer the product");

        product.owner = newOwner;
    }

}
