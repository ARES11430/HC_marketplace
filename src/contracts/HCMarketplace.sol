pragma solidity >= 0.5.0;

import "./OwnerShip.sol";
import "./ERC20.sol";
import "./Reputation.sol";


contract HCMarketplace is Reputation, OwnerShip {
  
    // Variables
    enum ObjectType {Painting, Carpet, Clay, Glass, Metal, Others}        // type of objects posted on market
    ERC20 public tokenAddress;    // HCT Token address
    
    struct Poster {
        address seller;           // address of seller wallet
        ObjectType objectType;    // type of product
        address escrowAgent;      // agent that decides token distribution
        address auditor;          // checks for spam and non related posts
        address handiCraftExpert; // address of handiCraftExpert wallet
        string handiCraftHash;    // hash of the prooved Original handiCraft
        bool isPostActive;        // auditor deactive the post if it break the terms of law
        bool readyToDeliver;      // status
        bool isOutOfOrder;        // status
        bool isCraftBroken;       // status
        uint escrow;              // amount of token escrow
    }
    
    struct Bid {
        uint amount;              // amount in Eth or ERC20 buyer is bidding
        uint guaranteeFee;        // amount of fee for guranteeAgent
        uint expertFee;           // amount of fee taken by handiCraftExpert
        uint time;                // bid creation Timestamp
        ERC20 currency;           // currency of listing
        address buyer;            // buyer wallet address
        address guranteeAgent;    // guranteeAgent wallet address
        address arbitrator;       // arbitrator wallet address
        bool isActive;            // status
        bool isBuyerApproved;     // status
        bool isSellerApproved;    // status
        bool isDisputed;          // status
        bool isFinalized;         // status
        bool isInsurancePayed;    // status
    }
    
    struct InsuranceOffer {
        uint amount;              // amount of tokens insurer is willing to pay
        uint fee;                 // amount of tokens insurer takes as fee
        uint time;                // insuranceOffer creation Timestamp
        ERC20 currency;
        address insurer;
        address arbitrator;
        bool isActive;            // status
        bool isSellerApproved;    // status
        bool isFinalized;         // status
    }
    
    Poster[] public posts;
    
    mapping(uint => Bid[])  bids; // PosterID => Bids
    mapping(uint => InsuranceOffer[]) insuranceOffers; // PosterID => InsuranceOffers
    
    mapping(address => bool)  allowedGuranteeAgent;
    mapping(address => bool)  allowedHandiCraftExpert;
    mapping(address => bool)  allowedInsurer;
    
    constructor() public{
        owner = msg.sender;
        tokenAddress = ERC20(0x349C255455d2e977ee4E26DEA888C119267f2E42);        // HCT Token contract
        //allowedAffiliates[address(0)] = true;        // allow null affiliate by default
        allowedGuranteeAgent[address(0)] = true;       // allow null guranteeAgent by default
        allowedHandiCraftExpert[address(0)] = true;    // allow null handiCraftExpert by default
        allowedInsurer[address(0)] = true;             // allow null insurer by default
    }

    function createPost(
    ObjectType _type,
    uint _escrow,
    string memory _handiCraftHash,
    address _auditor,
    address _escrowAgent,
    address _handiCraftExpert)
    public

    {
        require(_escrow > 0 ,"deposit some token");
        require(_escrowAgent != address(0), "escrowAgent can not be null");
        require(allowedHandiCraftExpert[address(this)] || allowedHandiCraftExpert[_handiCraftExpert],
        "handiCraftExpert not allowed, Please register");
        posts.push(Poster({
        seller: msg.sender,
        objectType:_type,
        escrowAgent: _escrowAgent,
        auditor: _auditor,
        handiCraftExpert: _handiCraftExpert ,
        handiCraftHash: _handiCraftHash,
        isPostActive: true,
        readyToDeliver: false,
        isOutOfOrder: false,
        isCraftBroken: false,
        escrow: _escrow
        }));
    
        if (_escrow > 0) {
            tokenAddress.transferFrom(msg.sender, address(this), _escrow);        // Transfer HCT Token
        }
    }

    function updatePost(uint _postID, uint _additionalEscrow) public {
        Poster storage post = posts[_postID];
        require(post.seller == msg.sender, "you need to be a seller for updating the post");
        
        if (_additionalEscrow > 0) {
            post.escrow += _additionalEscrow;
            post.isOutOfOrder = false;
            require(tokenAddress.transferFrom(msg.sender, address(this), _additionalEscrow),"you dont have enough currency to update your listing");
        }
    }
 
    // Return the total number of posts
    function totalPosts() public view returns (uint) {
        return posts.length;
    }

    // Return the total number of bids
    function totalBids(uint postID) public view returns (uint) {
        return bids[postID].length;
    }

    function auditPost(uint postID) public {
        Poster storage post = posts[postID];
        require(msg.sender == post.auditor, "Must be a auditor");
        
        post.isPostActive = false; 
    }
    
    // Poster escrowAgent withdraws post.
    function withdrawPostEscrow(uint postID, address _target) public {
        Poster storage post = posts[postID];
        require(msg.sender == post.escrowAgent, "Must be a escrowAgent");
        require(_target != address(0), "No target");
        uint escrow = post.escrow;
        post.escrow = 0; // Prevent multiple deposit withdrawals
        tokenAddress.transfer(_target, escrow);                      // Send escrow to target
    }
    
    function createBid(
        uint postID,
        address _guranteeAgent,  // Address to send any required commission to
        uint _guaranteeFee,      // Amount of fee to send in HCT Token to guranteeAgent if offer finalizes
        uint _expertFee,         // Amount of fee to send in HCT Token to handiCraftExpert if offer finalizes
        uint _value,             // bid amount in ERC20 
        ERC20 _currency,         // ERC20 token address 
        address _arbitrator      // arbitrator
    )
        public
    {
        
        require(allowedGuranteeAgent[address(this)] || allowedGuranteeAgent[_guranteeAgent],
        "guranteeAgent not allowed, Please register");
      
        Poster storage post = posts[postID];
        require(msg.sender != post.seller,"You can't bid on your own post");
        require(post.isOutOfOrder == false, "This post is sold out");
        require(post.isPostActive == true, "this post is no longer active due to voilation of service");

        bids[postID].push(
            Bid
            ({amount: _value,
            guaranteeFee: _guaranteeFee,
            expertFee: _expertFee,
            time: now,
            currency: _currency,
            buyer: msg.sender,
            guranteeAgent: _guranteeAgent,
            arbitrator: _arbitrator,
            isActive: true,
            isBuyerApproved: false,
            isSellerApproved: false,
            isDisputed:false,
            isFinalized:false,
            isInsurancePayed: false
            }));

            _currency.transferFrom(msg.sender, address(this), _value + _guaranteeFee + _expertFee);
    }
    
    function makeInsuranceOffer(
        uint postID,
        uint _insuranceAmount,         // bid amount in ERC20 
        uint _fee,                     // insurer fee
        ERC20 _currency,               // ERC20 token address 
        address _arbitrator            // insurance arbitrator
    )
        public
    {
        
        require(allowedInsurer[address(this)] || allowedInsurer[msg.sender], "You are not an Insurer, Please contact developers");
            
        Poster storage post = posts[postID];
        require(msg.sender != post.seller,"You can't make insurance offer on your own post");
        require(post.isPostActive == true, "this post is no longer active due to voilation of service");
        require(post.isOutOfOrder == false, "This post is sold out");
        require(post.readyToDeliver == true, "This listing is not ready to be send to buyer yet");
        
        insuranceOffers[postID].push(InsuranceOffer({
        amount: _insuranceAmount,              
        fee: _fee,          
        time: now,                
        currency: _currency,
        insurer: msg.sender,
        arbitrator: _arbitrator,
        isActive: true,
        isSellerApproved: false,  
        isFinalized: false       
        }));
        
        _currency.transferFrom(msg.sender, address(this), _insuranceAmount);
       
    }
    
    function acceptInsuranceOffer(uint postID, uint insuranceID) public {
        Poster storage post = posts[postID];
        InsuranceOffer storage insurance = insuranceOffers[postID][insuranceID];
        require(post.isOutOfOrder == false, "This post is sold out");
        require(msg.sender == post.seller, "You need to be a seller");
        require(insurance.isSellerApproved == false, "you have accepted this offer once");
        require(insurance.isFinalized == false, "this insurance offer is already finalized");
        require(insurance.isActive == true, "this insurance offer is no longer available");
        require(insurance.time + 1000000000 > now , "The offer has expired"); // Relative accept deadLine
        
        insurance.isSellerApproved = true;
        require(insurance.currency.transferFrom(msg.sender, address(this), insurance.fee), "token transfer failed");
    }
    
    function payInsurerFee(uint postID, uint insuranceID, uint bidID) public{
        
        Bid storage bid = bids[postID][bidID];
        InsuranceOffer storage insurance = insuranceOffers[postID][insuranceID];
        require(msg.sender == insurance.insurer, "You need to be insurer");
        require(insurance.isSellerApproved == true, "seller is not accepted your offer yet");
        require(bid.isFinalized == true, "the craft is not delivered yet");
        require(bid.isInsurancePayed == false, "no insurance for this bid or the bid insurance is already payed");
        require(insurance.isFinalized == false ,"this offer is already finilized");

        insurance.currency.transfer(insurance.insurer, insurance.fee + insurance.amount);
        insurance.isFinalized = true;
        bid.isInsurancePayed = true;        // prevents multiple insurance pay for a bid
        
    }
    
    function paySellerInsurance(uint postID, uint insuranceID, uint bidID) public{
        Poster storage post = posts[postID];
        Bid storage bid = bids[postID][bidID];
        InsuranceOffer storage insurance = insuranceOffers[postID][insuranceID];
        require(msg.sender == post.seller, "You need to be seller");
        require(post.isCraftBroken == true, "the craft is not broken, you can not take the insurance money");
        require(bid.isFinalized == true, "the craft is not delivered yet");
        require(bid.isInsurancePayed == false, "no insurance for this bid or the bid insurance is already payed");
        require(insurance.isFinalized == false ,"this offer is already finilized");

        insurance.currency.transfer(post.seller, insurance.fee + insurance.amount + post.escrow);
        insurance.isFinalized = true;
        bid.isInsurancePayed = true;        // prevents multiple insurance pay for a bid
    }
    
    function withdrawInsuranceOffer(uint postID, uint insuranceID) public{
        Poster storage post = posts[postID];
        InsuranceOffer storage insurance = insuranceOffers[postID][insuranceID];
        require(msg.sender == insurance.insurer || msg.sender == post.seller, "You need to be a seller or insurer");
        require(insurance.isActive == true, "this insurance offer is no longer available");
        insurance.currency.transfer(insurance.insurer, insurance.amount);
        delete insuranceOffers[postID][insuranceID];
    }
    
    function buyerOrSellerRevokeBid(uint postID, uint bidID) public {
        Poster storage post = posts[postID];
        Bid storage bid = bids[postID][bidID];
        require(msg.sender == bid.buyer || msg.sender == post.seller,"you need to be buyer or seller");
        require(bid.isActive == true, "the bid is no longer available");
        bid.currency.transfer(bid.buyer, bid.amount);
        delete bids[postID][bidID];
    }
    
    function finalizeBid(uint postID, uint bidID) public {
        Poster storage post = posts[postID];
        Bid storage bid = bids[postID][bidID];
        require(msg.sender == bid.buyer || msg.sender == post.seller, "You need to be a buyer or seller");
        require(post.isOutOfOrder == false, "the post is out of order please update it again");
        require(bid.isDisputed == false," this post is already disputed, wait for vote");
        require(post.isPostActive == true, "this post had violated our policy");
        require(bid.isFinalized == false, "this bid is Already finalized");
        require(bid.isActive == true, "this bid is no longer available");
        
        require (bid.time + 1000000000 > now , "The bid has expired");                           // Relative accept deadLine
        if (msg.sender == bid.buyer) {
            require(bid.isBuyerApproved == false, "You have already approved");
            bid.isBuyerApproved = true;
        } else if (msg.sender == post.seller) {
            require(bid.isSellerApproved == false, "You have already approved");
            bid.isSellerApproved = true;
            post.readyToDeliver = true;
        }
        if (bid.isBuyerApproved == true && bid.isSellerApproved == true) {
            soldWithoutDispute[post.seller].push(SoldWithoutDispute({seller: post.seller}));
            bid.isFinalized = true;
            post.isOutOfOrder = true;
            bid.isActive = false;
            post.readyToDeliver = false;                        // insurer can not make offer on this post any anymore
            
            bid.currency.transfer(post.handiCraftExpert, bid.expertFee);        // pay handiCraftExpert
            bid.currency.transfer(bid.guranteeAgent, bid.guaranteeFee);         // pay guaranteeFee
            bid.currency.transfer(post.seller, post.escrow + bid.amount);       // pay seller
        } 
    }

    // Buyer or seller can dispute transaction before finalized window
    function dispute(uint postID, uint bidID) public {
        Poster storage post = posts[postID];
        Bid storage bid = bids[postID][bidID];
        require(msg.sender == bid.buyer || msg.sender == post.seller, "Must be seller or buyer");
        if (msg.sender == bid.buyer && bid.isBuyerApproved == true){
            revert(); 
            // after buyer approves the finalized bid , they cant call dispute anymore... for sake of seller reputation
        }
        require(
        bid.isSellerApproved == true && bid.isBuyerApproved == false ||
        bid.isSellerApproved == false && bid.isBuyerApproved == true , 
        "can't call dispute now because The bid is not accepted yet...Use the remove bid function");
        require(post.isPostActive == true, "this post had violated our policy");
        require(bid.isFinalized == false, "this bid is Already finalized");
        require(bid.isActive == true, "this bid is no longer available");
        bid.isDisputed = true;                                              // Set status to "Disputed"
    }
    
    // arbitrator calls this
    function executeRuling(
        uint postID,
        uint bidID,
        uint _rule // 1: Seller, 2: Buyer, 4:buyer won but no point for seller (broken craft)
    ) public 
    {   
        Poster storage post = posts[postID];
        Bid storage bid = bids[postID][bidID];
        require(bid.isDisputed == true, "status != disputed");
        require(msg.sender == bid.arbitrator, "Must be arbitrator to call vote");
        require(post.isOutOfOrder == false, "the post is out of order please update it again");

        if (_rule == 1){
            bid.currency.transfer(post.seller, post.escrow + bid.amount);
            bid.currency.transfer(post.handiCraftExpert, bid.expertFee);
            bid.currency.transfer(bid.guranteeAgent, bid.guaranteeFee);
            sellerWonDispute[post.seller].push(SellerWonDispute({seller: post.seller}));
        } else if (_rule == 2){
            bid.currency.transfer(bid.buyer, bid.amount + post.escrow + bid.guaranteeFee + bid.expertFee);
            buyerWonDispute[post.seller].push(BuyerWonDispute({seller: post.seller}));
        } else if (_rule == 3){
            bid.currency.transfer(bid.buyer, bid.amount + bid.guaranteeFee + bid.expertFee);
            post.isCraftBroken = true;
        }
        
        bid.isFinalized = true;
        bid.isActive = false;
        post.isOutOfOrder = true;
        post.readyToDeliver = false;
       
    }

    function addGuaranteeAgent(address _guaranteeAgent) public onlyOwner {
        allowedGuranteeAgent[_guaranteeAgent] = true;
    }
    function addHandiCraftExpert(address _handiCraftExpert) public onlyOwner {
        allowedHandiCraftExpert[_handiCraftExpert] = true;
    }
    function addInsurer(address _insurer) public onlyOwner {
        allowedInsurer[_insurer] = true;
    }
}
