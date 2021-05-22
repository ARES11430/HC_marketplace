pragma solidity >= 0.4.0 < 0.6.4;

contract Reputation {
    
    // Reputation Variables
    struct SoldWithoutDispute{
        address seller;      // address seller
    }
    // Reputation Variables
    struct SellerWonDispute{
        address seller;      // address seller
    }
    // Reputation Variables
    struct BuyerWonDispute{
        address seller;      // address seller
    }
    
    // Reputation Variables
    struct HonestBuyer{
        address buyer;      // address seller
    }
    
     struct NotHonestBuyer{
        address buyer;      // address seller
    }
    
    mapping(address => SoldWithoutDispute[]) soldWithoutDispute;  // seller => soldWithoutDispute
    mapping(address => SellerWonDispute[]) sellerWonDispute;  // seller => sellerWonDispute
    mapping(address => BuyerWonDispute[]) buyerWonDispute;  // seller => buyerWonDispute
    mapping(address => HonestBuyer[]) buyerHonestPoints;  // buyer => HonestBuyer
    mapping(address => NotHonestBuyer[]) buyerNotHonestPoints;  // buyer => NotHonestBuyer
    
    // Return the number of successful sellings w/o dispute for spesific seller
    // It is used to measure seller's reputation
    function getSuccessfulSoldsWithoutDispute(address seller) public view returns (uint) {
        return soldWithoutDispute[seller].length;
    }
    // Return the number of disputes that seller won...
    function getSellerWonDispute(address seller) public view returns(uint){
        return sellerWonDispute[seller].length;
    }
    // Return the number of disputes that seller lost and buyer won...
    // This number would be a negative point for seller 
    function getSellerLostDispute(address seller) public view returns(uint){
        return buyerWonDispute[seller].length;
    }
    
    // point of honest buyer that finalized sale
    function getBuyerHonestPoints(address buyer) public view returns(uint){
        return buyerHonestPoints[buyer].length;
    }
    
    // point of no honest buyer that did not finalize sale
    function getBuyerNotHonestPoints(address buyer) public view returns(uint){
        return buyerNotHonestPoints[buyer].length;
    }
    
}
