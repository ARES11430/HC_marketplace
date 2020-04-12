pragma solidity >= 0.5.0;

contract ERC20{
   
    function name() external view   returns (string memory);
    function totalSupply() external view  returns (uint256);        //total amout of tokens
    
    function balanceOf(address account) external view  returns (uint256);        //shows balance of account address
    
    function transfer(address recipient, uint256 amount) external  returns (bool);        //returns a succeess or fail
    
    //owner lets someone else spend tokens and returns number of allowed tokens. default 0
    function allowance(address owner, address spender) external view  returns (uint256);  
    
    function approve(address spender, uint256 amount) external  returns (bool);        //sets amount of allowance retunrs success or fail
    
    //uses allowance mechanism for transfer
    function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool);        

    event Transfer(address indexed from, address indexed to, uint256 value);

    //Emited when apprive is called
    event Approval(address indexed owner, address indexed spender, uint256 value);
}