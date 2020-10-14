pragma solidity >= 0.4.0 < 0.6.4;

import "./OwnerShip.sol";
import "./ERC20.sol";
import "./Reputation.sol";

contract SimpleHCTMarket is Reputation, OwnerShip {
    

    enum ObjectType {Jewelry, Clothing, HomeFurniture, Toy, OtherCrafts}        // type of objects posted on market
    ERC20 public tokenAddress;    // HCT Token address
    
    struct Post {
        address seller;           // address of seller wallet
        ObjectType objectType;    // type of product
        address auditor;          // checks for spam and non related posts
        uint price;               // price of craft
        uint quantity;            // quantity of goods
        bool isPostActive;        // status
    }
    
    struct Order {
        ERC20 currency;           // currency of listing
        address buyer;            // address of buyer wallet
        address affiliate;        // address of affiliate wallet
        address arbitrator;       // address of arbitrator
        uint commission;          // affiliate commission
        bool isBuyerApproved;     // status
        bool isSellerApproved;    // status
        bool isDisputed;          // status
    }
    
    Post[] public posts;
    mapping(uint => Order[])  orders; // PostID => order
    mapping(address => bool)  allowedAffiliates;
    
    constructor() public{
        owner = msg.sender;
        tokenAddress = ERC20(0x349C255455d2e977ee4E26DEA888C119267f2E42);        // HCT Token contract
        allowedAffiliates[address(0)] = true;        // allow null affiliate by default
    } 
    
    function createPost(
    ObjectType _type,
    uint _price,
    address _auditor,
    uint _quantity
    )
    public

    {
        posts.push(Post({
        seller: msg.sender,
        objectType:_type,
        auditor: _auditor,
        price: _price,
        quantity: _quantity,
        isPostActive: true
        }));
    }
    
    function auditPost(uint postID) public {
        Post storage post = posts[postID];
        require(msg.sender == post.auditor, "Must be a auditor");
        
        post.isPostActive = false; 
    }
    
    function purchase(
        uint postID,
        uint _orderQuantity,
        address _affiliate,
        address _arbitrator,
        uint _commission,
        ERC20 _currency) public {
        
        Post storage post = posts[postID];
        require(_orderQuantity != 0 && post.quantity >= _orderQuantity,
        "this post is out of order or the amount of order is not available");
        require(_commission < post.price, "commission is too high");
        require(post.isPostActive == true, "this post had violated our policy");
        require(msg.sender != post.seller,"You can't purchase your own post");
        
        orders[postID].push(Order({
          currency: _currency,
          buyer: msg.sender,
          affiliate: _affiliate,
          commission: _commission,
          arbitrator: _arbitrator,
          isBuyerApproved: false,
          isSellerApproved: false,
          isDisputed: false
        }));

        post.quantity = post.quantity - _orderQuantity;
        post.price = post.price * _orderQuantity;
        
        // extra token is taken from buyer to assure finizing order and releasing seller fund
        // this extra tokens will be send back after process
        _currency.transferFrom(msg.sender, address(this), post.price + 10);
         
    }
    
    // if seller calls this function: they have sent the order
    // if buyer calls this function: they have recieved the order and calling this would give back their extra token
    function finalizePurchase(uint postID, uint orderID) public {
        
        Post storage post = posts[postID];
        Order storage order = orders[postID][orderID];
        require(post.isPostActive == true, "this post had violated our policy");
        require(order.isDisputed == false, "already disputed, wait for vote");
        require(msg.sender == order.buyer || msg.sender == post.seller, "You need to be a buyer or seller");
        
         if (msg.sender == post.seller) {
            require(order.isSellerApproved == false, "You have already approved");
            order.isSellerApproved = true;
        } else if (msg.sender == order.buyer) {
            require(order.isBuyerApproved == false, "You have already approved");
            order.isBuyerApproved = true;
        }
        if (order.isBuyerApproved == true && order.isSellerApproved == true) {
            soldWithoutDispute[post.seller].push(SoldWithoutDispute({seller: post.seller}));  // Reputation
            
            order.currency.transfer(post.seller, post.price - order.commission);     // pay seller
            order.currency.transfer(order.affiliate, order.commission);              // pay handiCraftExpert
            order.currency.transfer(order.buyer, 10);                                // pay back extra tokens         
        } 
    }
    
    // Buyer or seller can dispute for arbitration
    function dispute(uint postID, uint orderID) public {
        Post storage post = posts[postID];
        Order storage order = orders[postID][orderID];
        require(msg.sender == order.buyer || msg.sender == post.seller, "Must be seller or buyer");
        require(order.isDisputed == false, "you have already called this, please wait");
        if (msg.sender == order.buyer && order.isBuyerApproved == true){
            revert(); 
            // after buyer approves the finalized bid , they cant call dispute anymore... for sake of seller reputation
        }
        require(
        order.isSellerApproved == true && order.isBuyerApproved == false ||
        order.isSellerApproved == false && order.isBuyerApproved == true , 
        "can't call dispute now because The purchase is not accepted by seller yet");
        require(post.isPostActive == true, "this post had violated our policy");
        order.isDisputed = true;                                                  // Set status to "Disputed"
    }
    
    // arbitrator calls this
    function executeRuling(
        uint postID,
        uint orderID,
        uint _rule       // 1: Seller, 2: Buyer
    ) public 
    {   
        Post storage post = posts[postID];
        Order storage order = orders[postID][orderID];
        require(order.isDisputed == true, "status != disputed");
        require(msg.sender == order.arbitrator, "Must be arbitrator to call vote");
        
        if (_rule == 1){
            order.currency.transfer(post.seller, post.price - order.commission + 10);     // pay seller
            order.currency.transfer(order.affiliate, order.commission);              // pay handiCraftExpert
            sellerWonDispute[post.seller].push(SellerWonDispute({seller: post.seller}));
        } else if (_rule == 2){
            order.currency.transfer(order.buyer, post.price + 10);  // pay back all tokens
            buyerWonDispute[post.seller].push(BuyerWonDispute({seller: post.seller}));
        }
        
        // 2 lines: they can not call finalized function anymore
        order.isSellerApproved = true; 
        order.isBuyerApproved = true;

    }
    
    // owner Adds affiliate
    function addAffiliate(address _affiliate) public onlyOwner {
        allowedAffiliates[_affiliate] = true;
    } 
}
