pragma solidity >= 0.5.0;

import "./OwnerShip.sol";
import "./ERC20.sol";



contract HCTMarketplace is OwnerShip {
  
  
    // Events
    event PosterCreated      (address indexed party, uint indexed postID, string ipfsHash);
    event PostUpdated        (address indexed party, uint indexed postID, bytes32 ipfsHash);
    event BidCreated         (address indexed party, uint indexed postID, uint indexed bidID, bytes32 ipfsHash);
    event RuleExecuted       (address indexed party, uint indexed postID, uint indexed bidID, bytes32 ipfsHash);
    event BidFinalized       (address indexed party, uint indexed postID, uint indexed bidID, bytes32 ipfsHash);
    event PostWithdrawn      (address indexed party, uint indexed postID, bytes32 ipfsHash);
    event PostDisabled       (address indexed party, uint indexed postID, bytes32 ipfsHash);
    event BidRevoked         (address indexed party, uint indexed postID, uint indexed bidID, bytes32 ipfsHash);
    event AffiliateAdded     (address indexed party, bytes32 ipfsHash);
    event AffiliateRemoved   (address indexed party, bytes32 ipfsHash);
    event MarketplaceData    (address indexed party, bytes32 ipfsHash);
    event BidData            (address indexed party, uint indexed postID, uint indexed bidID, bytes32 ipfsHash);
    event PostData           (address indexed party, uint indexed postID, bytes32 ipfsHash);
    event BidDisputed        (address indexed party, uint indexed postID, uint indexed bidID, bytes32 ipfsHash);

    // Variables
    enum ObjectType {Painting, Carpet, Clay, Glass, Metal, Others}        // type of objects posted on market
    ERC20 public tokenAddress;    // HCT Token address
    
    struct Poster {
        address seller;           // address of seller wallet
        ObjectType objectType;    // type of product
        string ipfsHash;
        address escrowAgent;      // agent that decides token distribution
        address auditor;          // checks for spam and non related posts
        bool isPostActive;        // auditor deactive the post if it break the terms of law
        uint escrow;              // amount of token escrow 
    }
    
    struct Bid {
        uint amount;              // amount in Eth or ERC20 buyer is bidding
        uint commission;          // amount of commission for affiliate
        uint time;                // bid creation Timestamp
        ERC20 currency;           // currency of listing
        address payable buyer;    // buyer wallet address
        address affiliate;        // affiliate wallet address
        address arbitrator;       // arbitrator wallet address
        bool isActive;            // status
        bool isBuyerApproved;     // status
        bool isSellerApproved;    // status
        bool isDisputed;          // status
        bool isFinilised;         // status
    }
    
    Poster[] public posts;
    mapping(uint => Bid[])  bids; // PosterID => Bids
    mapping(address => bool)  allowedAffiliates;
    
    constructor() public payable{
       
        owner = msg.sender;
        tokenAddress = ERC20(0x692a70D2e424a56D2C6C27aA97D1a86395877b3A);        // HCT Token contract
        allowedAffiliates[address(0)] = true;        // allow null affiliate by default
    }

    function createPost(string memory _ipfsHash, ObjectType _type, uint _escrow, address _auditor, address _escrowAgent)
        public
        payable
    {
        _createPost(msg.sender, _type, _ipfsHash, _escrow, _auditor, _escrowAgent);
    }
    
    // private function for creating post
    function _createPost(
        address _seller,
        ObjectType _type,
        string memory _ipfsHash,        // IPFS hash witch details in price, availablity count and more details
        uint _escrow,        // escrow in HCT token
        address _auditor,
        address _escrowAgent        // address of listing escrowAgent
    )
        private
    {
        
        require(_escrowAgent != address(0), "Must specify depositManager");
        posts.push(Poster({seller: _seller, objectType:_type, ipfsHash: _ipfsHash, escrow: _escrow, auditor: _auditor,
        isPostActive: true, escrowAgent: _escrowAgent}));
    
        if (_escrow > 0) {
            /* require(
                tokenAddress.approve(_seller,_escrow) &&
                tokenAddress.transferFrom(_seller, address(this), _escrow),        // Transfer HCT Token
                "transferFrom failed"
            ); */
        }
        emit PosterCreated(_seller, posts.length - 1, _ipfsHash);
    }

    function getPost(uint index) public view returns(address, ObjectType, string memory ,address ,address, bool, uint){
        return (posts[index].seller, posts[index].objectType, posts[index].ipfsHash, posts[index].escrowAgent,
        posts[index].auditor, posts[index].isPostActive, posts[index].escrow);
    }
    
    function updatePost(uint _postID, bytes32 _ipfsHash, uint _additionalEscrow) public {
        _updatePost(msg.sender, _postID, _ipfsHash, _additionalEscrow);
    }
    
    // private function for updating post
    function _updatePost(
        address _seller,
        uint _postID,
        bytes32 _ipfsHash,        // updated IPFS hash
        uint _additionalEscrow         // additional escrow
    ) private {
        Poster storage post = posts[_postID];
        require(post.seller == _seller, "you need to be a seller for updating the post");
        
        if (_additionalEscrow > 0) {
            post.escrow += _additionalEscrow;
            require(tokenAddress.transferFrom(_seller, address(this), _additionalEscrow),"you dont have enough currency to update your listing");
        }
        emit PostUpdated(post.seller, _postID, _ipfsHash);
    }
    
    // Return the total number of posts
    function totalPosts() public view returns (uint) {
        return posts.length;
    }

    // Return the total number of bids
    function totalBids(uint postID) public view returns (uint) {
        return bids[postID].length;
    }
    
    // Poster escrowAgent withdraws post. IPFS hash contains reason for withdrawl.
    function auditPost(uint postID, bytes32 _ipfsHash) public {
        Poster storage post = posts[postID];
        require(msg.sender == post.auditor, "Must be a auditor");
        
        post.isPostActive = false; 
        
        emit PostDisabled(post.auditor, postID, _ipfsHash);
    }
    
    // Poster escrowAgent withdraws post. IPFS hash contains reason for withdrawl.
    function withdrawPostEscrow(uint postID, address _target, bytes32 _ipfsHash) public {
        Poster storage post = posts[postID];
        require(msg.sender == post.escrowAgent, "Must be a escrowAgent");
        require(_target != address(0), "No target");
        uint escrow = post.escrow;
        post.escrow = 0; // Prevent multiple deposit withdrawals
        tokenAddress.transfer(_target, escrow);                      // Send escrow to target
        emit PostWithdrawn(_target, postID, _ipfsHash);
    }
    
    function createBid(
        uint postID,
        bytes32 _ipfsHash,   // IPFS hash containing bid data
        address _affiliate,  // Address to send any required commission to
        uint256 _commission, // Amount of commission to send in HCT Token to affiliate if offer finalizes
        uint _value,         // bid amount in ERC20 
        ERC20 _currency,     // ERC20 token address 
        address _arbitrator  // Escrow arbitrator
    )
        public
        payable
    {
        bool affiliateWhitelistDisabled = allowedAffiliates[address(this)];
        require(affiliateWhitelistDisabled || allowedAffiliates[_affiliate], "Affiliate not allowed");
            
        if (_affiliate == address(0)) {
            // avoid commission tokens being trapped in marketplace contract.
            require(_commission == 0, "no affiliate, no commission");
        }
        Poster storage post = posts[postID];
        require(post.isPostActive == true, "this post is no longer active due to voilation of service");

        bids[postID].push(
            Bid
            ({amount: _value,
            commission: _commission,
            time: now,
            currency: _currency,
            buyer: msg.sender,
            affiliate: _affiliate,
            arbitrator: _arbitrator,
            isActive: true,
            isBuyerApproved: false,
            isSellerApproved: false,
            isDisputed:false,
            isFinilised:false    
            }));
     
        if (address(_currency) == address(0)) {                                     // offer is in ETH
            require(msg.value == _value, "ETH value doesn't match offer");
        } else {                                                                    // listing is in ERC20
            require(msg.value == 0, "ETH would be lost");
            require(_currency.transferFrom(msg.sender, address(this), _value), "failed");
        }
        emit BidCreated(msg.sender, postID, bids[postID].length-1, _ipfsHash);
    }
    
    function buyerOrSellerRevokeBid(uint postID, uint bidID, bytes32 _ipfsHash) public {
        Poster storage post = posts[postID];
        Bid memory bid = bids[postID][bidID];
        require(msg.sender == bid.buyer || msg.sender == post.seller,"you need to be buyer or seller");
        require(bid.isActive == true, "the bid is no longer available");
        _refundBuyer(bid.buyer, bid.currency, bid.amount);
        delete bids[postID][bidID];
        emit BidRevoked(msg.sender, postID, bidID, _ipfsHash);
    }
    
    
     function finaliseBid(uint postID, uint bidID, bytes32 _ipfsHash) public {
        Poster storage post = posts[postID];
        Bid storage bid = bids[postID][bidID];
        require(msg.sender == bid.buyer || msg.sender == post.seller, "You need to be a buyer or seller ");
        require(post.isPostActive== true, "this post had violated our policy");
        require(bid.isFinilised == false, "this bid is Already finalized");
        require(bid.isActive == true, "this bid is no longer available");
        
        require(post.escrow >= bid.commission, "amount of escrow must be than higher commission");
        require (bid.time + 1000000000 > now , "The bid has expired");                           // Relative accept deadLine
        if (msg.sender == bid.buyer) {
            bid.isBuyerApproved = true;
        } else if (msg.sender == post.seller) {
            bid.isSellerApproved = true;
        }
        if (bid.isBuyerApproved == true && bid.isSellerApproved == true) {
            bid.isFinilised = true;
            uint new_escrow = post.escrow - bid.commission; // Accepting an offer puts hct Token into escrow
            _payCommission(bid.affiliate, bid.commission);
            uint seller_fund = new_escrow + bid.amount;
            _paySeller(post.seller, seller_fund, bid.currency);
            delete bids[postID][bidID];
        } 
        emit BidFinalized(msg.sender, postID, bidID, _ipfsHash);
    }
    
    // Buyer or seller can dispute transaction before finalized window
    function dispute(uint postID, uint bidID, bytes32 _ipfsHash) public {
        Poster storage post = posts[postID];
        Bid storage bid = bids[postID][bidID];
        require( msg.sender == bid.buyer || msg.sender == post.seller, "Must be seller or buyer");
    /*    require(bid.isSellerApproved == false && bid.isBuyerApproved == false ||
        bid.isSellerApproved == true && bid.isBuyerApproved == false ||
        bid.isSellerApproved == false && bid.isBuyerApproved == true , "Bid is finalized"); */
        require(post.isPostActive== true, "this post had violated our policy");
        require(bid.isFinilised == false, "this bid is Already finalized");
        require(bid.isActive == true, "this bid is no longer available");
        bid.isDisputed = true;                                              // Set status to "Disputed"
        emit BidDisputed(msg.sender, postID, bidID, _ipfsHash);
    }
    
    // arbitrator calls this
    function executeRuling(
        uint postID,
        uint bidID,
        bytes32 _ipfsHash,
        uint _rule // 0: Seller, 1: Buyer, 2: Com + Seller, 3: Com + Buyer
    ) public {
        Poster storage post = posts[postID];
        Bid memory bid = bids[postID][bidID];
        require(msg.sender == bid.arbitrator, "Must be arbitrator to call vote");
        require(bid.isDisputed == true, "status != disputed");
        
        uint seller_value = post.escrow + bid.amount;               // the escrow and bid amount
    
        if (_rule == 0){
            _paySeller(post.seller, seller_value, bid.currency);
        } else if (_rule == 1){
            _refundBuyer(bid.buyer, bid.currency, bid.amount);
        } else if (_rule == 2){
            require(post.escrow >= bid.commission, "amount of escrow must be than higher commission");
            _payCommission(bid.affiliate, bid.commission);
            uint refund_seller = seller_value - bid.commission;
            _paySeller(post.seller, refund_seller, bid.currency);
        } else if (_rule == 3){
            require(post.escrow >= bid.commission, "amount of escrow must be than higher commission");
            _payCommission(bid.affiliate, bid.commission);
            _refundBuyer(bid.buyer, bid.currency, bid.amount);
        }
        bid.isFinilised = true;
        bid.isActive = false;
        delete bids[postID][bidID];
        emit RuleExecuted(msg.sender, postID, bidID, _ipfsHash);
    }
    
    // adds Associate ipfs data with the marketplace
    function addMarketData(bytes32 ipfsHash) public {
        emit MarketplaceData(msg.sender, ipfsHash);
    }

    // adds Associate ipfs data with a post
    function addPostData(uint postID, bytes32 ipfsHash) public {
        emit PostData(msg.sender, postID, ipfsHash);
    }

    // adds Associate ipfs data with an bid
    function addBidData(uint postID, uint bidID, bytes32 ipfsHash) public {
        emit BidData(msg.sender, postID, bidID, ipfsHash);
    }
    
    // owner Adds affiliate to whitelist. Set to address(this) to disable.
    function addAffiliate(address _affiliate, bytes32 ipfsHash) public onlyOwner {
        allowedAffiliates[_affiliate] = true;
        emit AffiliateAdded(_affiliate, ipfsHash);
    }

    // owner Removes affiliate from whitelist.
    function removeAffiliate(address _affiliate, bytes32 ipfsHash) public onlyOwner {
        delete allowedAffiliates[_affiliate];
        emit AffiliateRemoved(_affiliate, ipfsHash);
    }
    
    // Pays
    
    // Pay commission to affiliate
    function _payCommission(address affiliate, uint commission) private {
        if (affiliate != address(0)) {
            tokenAddress.transfer(affiliate, commission);
        }
    }
    
    // Pay seller in ETH or ERC20
    function _paySeller(address seller, uint value, ERC20 currency) private {
        if(seller != address(0)){
           currency.transfer(seller, value);
        }
    }
    
    // Refunds buyer - used by 1) executeRuling() and 2) to allow a seller to refund a purchase
    function _refundBuyer(address payable buyer, ERC20 currency, uint value) private  {
        if (address(currency) == address(0)) {
            buyer.transfer(value);                          // ether transfer
        } else {
                currency.transfer(buyer, value);
        }
    }
    
    
}