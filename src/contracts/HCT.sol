pragma solidity >= 0.4.0 < 0.6.4;

import "hct/token/ERC20.sol";

contract HCTToken is ERC20 {
   
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 tokenPerEther = 10;

     constructor () public {
        _name = "Handicraft Token";
        _symbol = "HCT";
        _decimals = 0;
        _totalSupply = 1000000000;
        _balances[msg.sender] = _totalSupply;
    }
    
    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
         require(recipient != address(0), "transfer to the zero address");
       //  require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(msg.sender, recipient, amount);
    }
    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {        // msg.sender = owner
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
     //   require(_balances[sender] >= amount && _allowances[sender][msg.sender] >= amount && amount > 0);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        
        
        emit Transfer(sender,recipient,amount);
        return true;
    }
    
    function buyToken() public payable {
        
        require(msg.value != 0, "invalid amount of invest!");
        
        uint256 tokens = (msg.value * tokenPerEther) / 1 ether;

        _totalSupply = _totalSupply + tokens;
        _balances[msg.sender] = _balances[msg.sender] + tokens;
        emit Transfer(address(0), msg.sender, tokens);
    }
}
