// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./ProductManagement.sol";
import "./UserRoleManager.sol";

contract DistributorManagement {

    uint256 id;
    address public owner;
    UserRoleManager public userRoleManager; 
    ProductManagement public productManagement;

  // Distributor struct
    struct Distributor {
        uint256 id;
        string companyName;
        string location;
        bool verify;
        uint256 totalDistributions;
        mapping(uint256 => uint256) distributionIds;
    }

    mapping(address => Distributor) public distributors;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Constructor to set the owner
    constructor(address _userRoleManager, address _productManagementAddress) {
        owner = msg.sender;
        userRoleManager = UserRoleManager(_userRoleManager);
        productManagement = ProductManagement(_productManagementAddress);
    }

    
    // Register a new distributor
    function registerDistributor(
        address distributorAddress,
        string memory companyName,
        string memory location
    ) public onlyOwner {
        
        uint256 newDistributorId = id + 1;
        Distributor storage newDistributor = distributors[distributorAddress];
        newDistributor.id = newDistributorId;
        newDistributor.companyName = companyName;
        newDistributor.location = location;
        newDistributor.verify = true;
        newDistributor.totalDistributions = 0; 

        // Assign the Distributor role to the new distributor
        userRoleManager.assignRole(distributorAddress, UserRoleManager.userRole.Manufacturer);
    }

    // Deregister a distributor
    function deregisterDistributor(address distributorAddress) public onlyOwner {
        delete distributors[distributorAddress];
    }

    // Update distributor information
    function updateDistributorInfo(
        address distributorAddress,
        string memory companyName,
        string memory location
    ) public onlyOwner {

        Distributor storage distributor = distributors[distributorAddress];
        distributor.companyName = companyName;
        distributor.location = location;
    }

    // Function for a distributor to buy a product and transfer ownership to another address
    function buyProductAndTransferOwnership(

        address distributorAddress,
        uint256 productId,
        address recipientAddress

    ) public {

        Distributor storage distributor = distributors[distributorAddress];
        require(distributor.verify, "Distributor is not verified");
        require(productManagement.isProductAvailable(productId), "Product is not available");

        productManagement.transferProductOwnership(productId, recipientAddress);
        
        addDistribution(distributorAddress, productId);
    }

    // Verify or unverify a distributor
    function verifyDistributor(address distributorAddress, bool isVerified) public onlyOwner {
        distributors[distributorAddress].verify = isVerified;
    }


    // Get distributor details
    function getDistributorDetails(address distributorAddress) public view returns (string memory companyName, string memory location, bool verify) {
       
        Distributor storage distributor = distributors[distributorAddress];
        return (distributor.companyName, distributor.location, distributor.verify);
    }

    // View all distribution IDs of a distributor
    function viewDistributions(address distributorAddress) public view returns (uint256[] memory) {
        
        Distributor storage distributor = distributors[distributorAddress];
        uint256[] memory distributions = new uint256[](distributor.totalDistributions);
       
        for (uint256 i = 0; i < distributor.totalDistributions; i++) {
            distributions[i] = distributor.distributionIds[i];
        }

        return distributions;
    }

    function dispatchToLogistics(string memory batchId, address logisticsAddress) external {

       
       
        emit Events.ProductDispatched(batchId, logisticsAddress);

    }

    function receiveFromManufacturer(string memory productId) external {

     emit Events.ProductReceivedFromManufacturer(productId, msg.sender, block.timestamp);
    }
}
