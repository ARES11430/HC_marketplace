pragma solidity >= 0.5.0;

contract OwnerShip {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  //Sets owner
  constructor() public {
    owner = msg.sender;
  }

  //Only owner has permission to call the function, when function uses this modifier
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  //Allows the current owner to transfer control of the contract to a newOwner.
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}