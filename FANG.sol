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
    uint private supply;
    uint256 private totalTokensBought;
    uint256 private totalTokensSold;
    uint256 private totalPayouts;
    uint256 private earningsPerShare;
    uint256 public currentPrice;
    uint256 private increment;
    uint256 private lowerCap;
    mapping(address => uint) public balances;
    mapping(address => int256) payouts;
    event Transfer(address indexed from, address indexed to, uint tokens);

    uint256 public totalDividends;
    struct Account {
      uint256 balance;
      uint256 lastDividends;
    }
    mapping (address => Account) accounts;
    address payable pool;
    address payable tokens;

    constructor() public{
        name = "FANG-WPB";
        symbol = "FANG";
        decimals = 18;
        supply = 3000000000;
        pool = "0x0000000000000000000000000000000000000000";
        tokens = "0x0000000000000000000000000000000000000000";
        
        // $0.01 or 0.000053 ETH at the start time.
        currentPrice = 53000000000000;

        // 0.000000001 ETH
        increment = 1000000000;

        // $0.001 or 0.0000053 ETH at the start time.
        lowerCap = 5300000000000;

        // Give founder all supply
        balances[owner()] = supply;
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

        uint256 fromOwing = dividendBalanceOf(sender);
        uint256 toOwing = dividendBalanceOf(recipient);
        require(fromOwing <= 0 && toOwing <= 0, "Token transfer disabled if sender or receiver have unclaimed dividends");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setIncrement(uint256 newIncrement) public onlyOwner {
        increment = newIncrement;
    }

    function setLowerCap(uint256 newLowerCap) public onlyOwner {
        lowerCap = newLowerCap;
    }

    function setPool(address payable newPool) public onlyOwner {
        pool = newPool;
    }

    function setTokens(address payable newTokens) public onlyOwner {
        tokens = newTokens;
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

    function buy(address referrer) public payable returns (bool) {
      require(msg.sender != referrer, "Buyer and referrer cannot be the same");

      /*
        Dividends
       */
      // If there is a referrer, it gets 10% off the top
      uint256 referralDividend = 0;
      if(referrer != address(0))
      {
        referralDividend = msg.value.div(10);
        accounts[referrer].balance += referralDividend;
      }

      // Holder dividend after referral is paid
      uint256 holderDividend = msg.value.sub(referralDividend).div(10);
      totalDividends = totalDividends.add(holderDividend);

     /*
        Tokens
      */
      uint256 valueLeftForPurchase = msg.value.sub(referralDividend).sub(holderDividend);

      // Determine how many tokens can be bought
      uint256 amount = valueLeftForPurchase.div(currentPrice);
      require(balances[tokens] > amount, "Not enough tokens available for sale.");
      require(amount >= currentPrice, "Amount must be greater than or equal to the token price.");

      balances[msg.sender] = balances[msg.sender].add(amount);
      balances[tokens] = balances[tokens].sub(amount);

      // Transfer the remaining to the pool
      pool.transfer(valueLeftForPurchase);

      emit Transfer(tokens, msg.sender, amount);

      // Update the current price based on actual token amount sold
      currentPrice = currentPrice.add(increment.mul(amount));

      return true;
    }

    // https://medium.com/@dejanradic.me/pay-dividend-in-ether-using-token-contract-104499de116a
    function dividendBalanceOf(address account) public view returns (uint256) {
      uint256 newDividends = totalDividends.sub(accounts[account].lastDividends);
      uint256 product = accounts[account].balance.mul(newDividends);
      return product.div(supply);
    }

    function claimDividend() public {
      uint256 owing = dividendBalanceOf(msg.sender);
      if (owing > 0) {
        msg.sender.transfer(owing);
        accounts[msg.sender].lastDividends = totalDividends;
      }
    }
}
