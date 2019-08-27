pragma solidity ^0.5.1;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    
    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  
  //function renounceOwnership() public onlyOwner {
  //  emit OwnershipTransferred(_owner, address(0));
  //  _owner = address(0);
  //}

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract FangToken is ERC20Interface, Ownable{

    using SafeMath for uint;

    string private name;
    string private symbol;
    uint private decimals;
    uint private decimalMult;
    uint private supply;
    uint256 totalTokensBought;
    uint256 totalTokensSold;
    uint256 totalPayouts;
    uint256 earningsPerShare;
    uint256 initialPrice;
    uint256 increment;
    uint256 lowerCap;

    mapping(address => uint) public balances;
    mapping(address => int256) payouts;
    event Transfer(address indexed from, address indexed to, uint tokens);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _supply) public{
        // Set variables
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        supply = _supply;
        decimalMult = 10**decimals;

        // $0.01 or 0.000053 ETH at the start time.
        initialPrice = 53000000000000;

        // 0.000000001 ETH
        increment = 1000000000;

        // $0.001 or 0.0000053 ETH at the start time.
        lowerCap = 5300000000000;

        // Give founder all supply
        balances[owner()] = _supply;
    }
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
     }
     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        address sender = msg.sender;
        require(sender != address(0));
        require(recipient != address(0));

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
     
     function burn(uint256 amount) public onlyOwner {
        balances[owner()] = balances[owner()].sub(amount);
        supply = supply.sub(amount);
        emit Transfer(owner(), address(0), amount);
    }
     
      function mint(uint256 amount) public onlyOwner {
        supply = supply.add(amount);
        balances[owner()] = balances[owner()].add(amount);
        emit Transfer(address(0), owner(), amount);
    }

    function tokenPrice() public view returns (uint256){
      uint256 price = initialPrice + (increment * totalTokensBought) - (increment * totalTokensSold);
      if(price < lowerCap)
      {
        price = lowerCap;
      }

        return price;
    }

    function buy() public payable returns (bool) {
      uint256 currentPrice = tokenPrice();
      require(msg.value >= currentPrice, "Must send enough for at least 1 token");

      address sender = msg.sender;

      // More logic needed


    }
}
