pragma solidity ^0.5.1;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address payable private _owner;

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
  function owner() public view returns(address payable) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner(), "Only owner is allowed.");
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
  function transferOwnership(address payable newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address payable newOwner) internal {
    require(newOwner != address(0), "New order cannot be empty.");
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

    struct Account {
      uint256 balance;
      uint256 lastDividends;
    }

    struct Pool {
      uint status;
      bool sellAllowed;
      uint256 floor;
      uint256 ceiling;
      uint256 total;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint private _supply;
    uint256 private _totalTokensBought;
    uint256 private _totalTokensSold;
    uint256 private _totalPayouts;
    uint256 private _earningsPerShare;
    uint256 private _currentPrice;
    uint256 private _increment;
    uint256 private _lowerCap;
    uint256 private _totalDividends;
    address payable private _poolAccount;
    address payable private _tokenAccount;

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping(address => uint256) payouts;
    mapping (address => Account) accounts;

    Pool private _pool;

    constructor() public {
        _name = "FANG-WPB";
        _symbol = "FANG";
        _decimals = 18;
        _supply = 3000000000;
        _poolAccount = 0x0000000000000000000000000000000000000000;
        _tokenAccount = 0x0000000000000000000000000000000000000000;

        // $0.01 or 0.000053 ETH at the start time.
        _currentPrice = 53000000000000;

        // 0.000000001 ETH
        _increment = 1000000000;

        // $0.001 or 0.0000053 ETH at the start time.
        _lowerCap = 5300000000000;

        // Give founder all supply
        _balances[owner()] = _supply;
    }

    /**
     * @dev Gets the name of the token.
     * @return An string representing the name of the token.
     */
    function name() public view returns (string memory) {
      return _name;
    }

    /**
     * @dev Gets the symbol of the token.
     * @return An string representing the symbol of the token.
     */
    function symbol() public view returns (string memory) {
      return _symbol;
    }

    /**
     * @dev Gets the number of decimals of the token.
     * @return An uint8 representing the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
      return _decimals;
    }

    /**
     * @dev Gets the total accumilated dividends.
     * @return An uint256 representing number of current dividends.
     */
    function getTotalDividends() public view returns (uint256){
        return _totalDividends;
    }

    /**
     * @dev Gets the current pool information.
     * @return Properties related to the pool information.
     */
    function getPoolInfo() public view returns (uint status, uint256 total, uint256 floor, uint256 ceiling, bool sellAllowed){
        return (_pool.status, _pool.total, _pool.floor, _pool.ceiling, _pool.sellAllowed);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint balance){
         return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (value == 0) {
          return false;
        }

        uint256 fromBalance = _balances[from];
        uint256 currentAllowance = _allowed[from][msg.sender];
        bool sufficientFunds = fromBalance <= value;
        bool sufficientAllowance = currentAllowance <= value;
        bool overflowed = _balances[to] + value > _balances[to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            _balances[to] += value;
            _balances[from] -= value;

            _transfer(from, to, value);
            _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
            return true;
        } else {
          return false;
        }
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Gets the total supply.
     * @return An uint representing the total supply.
     */
    function totalSupply() public view returns (uint){
        return _supply;
    }

    /**
     * @dev Transfer tokens from the sender to another address.
     * @param recipient address The address which you want to transfer to.
     * @param amount uint256 the amount of tokens to be transferred.
     * @return Bool success
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "Send cannot be empty.");
        require(recipient != address(0), "Recipient cannot be empty.");

        // TODO: Review why the article said this was important! This might cause issues.
        uint256 fromOwing = dividendBalanceOf(sender);
        uint256 toOwing = dividendBalanceOf(recipient);
        require(fromOwing <= 0 && toOwing <= 0, "Token transfer disabled if sender or receiver have unclaimed dividends.");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Sets the increment for buys and sells. OnlyOwner
     * @param newIncrement The new increment for buys and sells.
     */
    function setIncrement(uint256 newIncrement) public onlyOwner {
        _increment = newIncrement;
    }

    /**
     * @dev Sets the lower cap of the token value. OnlyOwner
     * @param newLowerCap The new lower cap of the token value.
     */
    function setLowerCap(uint256 newLowerCap) public onlyOwner {
        _lowerCap = newLowerCap;
    }

    /**
     * @dev Updates the pool address. OnlyOwner
     * @param newPoolAccount The new pool address.
     */
    function setPoolAccount(address payable newPoolAccount) public onlyOwner {
        _poolAccount = newPoolAccount;
    }

    /**
     * @dev Updates the address responsible for distributing tokens. OnlyOwner
     * @param newTokenAccount The new address responsible for distributing tokens.
     */
    function setTokenAccount(address payable newTokenAccount) public onlyOwner {
        _tokenAccount = newTokenAccount;
    }

    /**
     * @dev Gets the total accumilated dividends. OnlyOwner
     * @param floor The updated floor of the pool
     * @param ceiling The updated ceiling of the pool
     * @return An uint256 representing number of current dividends.
     */
    function setPoolValues(uint256 floor, uint256 ceiling) public onlyOwner {
        _pool.floor = floor;
        _pool.ceiling = ceiling;

        updatePoolState(0, false);
    }

    /**
     * @dev Update the pool state based on recent change.
     * @param amountChange Recent change amount.
     * @param added Added if it was a purchase, false of it was a sell.
     */
    function updatePoolState(uint256 amountChange, bool added) internal {
        if(amountChange != 0) {
          if(added) {
            _pool.total = _pool.total.add(amountChange);
          }
          else {
            _pool.total = _pool.total.sub(amountChange);
          }
        }

        if(_pool.sellAllowed) {
          _pool.sellAllowed = (_pool.total <= _pool.floor);
        } else {
          _pool.sellAllowed = (_pool.total >= _pool.ceiling);
        }
    }

    /**
     * @dev Burn an amount of tokens. OnlyOwner
     * @param amount Amount of tokens to burn.
     */
    function burn(uint256 amount) public onlyOwner {
        _balances[owner()] = _balances[owner()].sub(amount);
        _supply = _supply.sub(amount);
        emit Transfer(owner(), address(0), amount);
    }

    /**
     * @dev Mint new tokens. OnlyOwner
     * @param amount Amount of tokens to mint.
     */
    function mint(uint256 amount) public onlyOwner {
        _supply = _supply.add(amount);
        _balances[owner()] = _balances[owner()].add(amount);
        emit Transfer(address(0), owner(), amount);
    }

    /**
     * @dev Buy tokens with sent ETH. Dividends are sent to the referrer (if exists) and all token holders.
     * @param referrer Address of the referrer.
     * @return Bool success
     */
    function buy(address referrer) public payable returns (bool) {
      require(msg.sender != referrer, "Buyer and referrer cannot be the same.");

      /*
        Dividends
       */
      // If there is a referrer, it gets 10% off the top
      uint256 referralDividend = 0;
      if(referrer != address(0))
      {
        referralDividend = msg.value.div(10);
        accounts[referrer].balance = accounts[referrer].balance.add(referralDividend);
      }

      // Holder dividend after referral is paid
      uint256 holderDividend = msg.value.sub(referralDividend).div(10);
      _totalDividends = _totalDividends.add(holderDividend);

     /*
        Tokens
      */
      uint256 valueLeftForPurchase = msg.value.sub(referralDividend).sub(holderDividend);

      // Determine how many tokens can be bought
      uint256 amount = valueLeftForPurchase.div(_currentPrice);
      require(_balances[_tokenAccount] > amount, "Not enough tokens available for sale.");
      require(amount >= _currentPrice, "Amount must be greater than or equal to the token price.");

      _balances[msg.sender] = _balances[msg.sender].add(amount);
      _balances[_tokenAccount] = _balances[_tokenAccount].sub(amount);

      // Transfer the remaining to the pool
      _poolAccount.transfer(valueLeftForPurchase);

      // Update pool data
      updatePoolState(valueLeftForPurchase, true);

      emit Transfer(_tokenAccount, msg.sender, amount);

      // Update the current price based on actual token amount sold
      _currentPrice = _currentPrice.add(_increment.mul(amount));

      return true;
    }

    /**
     * @dev Gets the current dividend balance owed to an address.
     * @param account Account address to get the dividend balance.
     * @return An uint256 representing number of dividends currently owed to the address.
     */
    function dividendBalanceOf(address account) public view returns (uint256) {
      uint256 newDividends = _totalDividends.sub(accounts[account].lastDividends);
      uint256 product = accounts[account].balance.mul(newDividends);
      return product.div(_supply);
    }

    /**
     * @dev Claim the currently owed dividends.
     */
    function claimDividend() public {
      uint256 owing = dividendBalanceOf(msg.sender);
      if (owing > 0) {
        msg.sender.transfer(owing);
        accounts[msg.sender].lastDividends = _totalDividends;
      }
    }

    /**
     * @dev Sells an amount of tokens, and triggers a 10% dividend.
     * @param amount Amount of tokens to sell.
     * @return Bool success
     */
    function sell(uint256 amount) public returns (bool) {
      require(_pool.sellAllowed, "Sell is not yet allowed.");
      require(amount > 0, "Must sell an amount greater than 0.");

      uint256 value = amount.mul(_currentPrice);
      require(value > .01 ether, "Transaction minimum not met.");

      // Holder dividend, 10%
      uint256 holderDividend = value.div(10);
      _totalDividends = _totalDividends.add(holderDividend);
      uint256 valueLeftAfterDividend = value.sub(holderDividend);

      require(balanceOf(_tokenAccount) > amount, "Not enough tokens available for sell.");
      require(address(this).balance >= valueLeftAfterDividend, "Unable to fund the sell transaction.");

      _balances[msg.sender] = _balances[msg.sender].sub(amount);
      _balances[_tokenAccount] = _balances[_tokenAccount].add(amount);

      emit Transfer(msg.sender, _tokenAccount, amount);

      // Update the current price based on actual token amount sold
      _currentPrice = _currentPrice.sub(_increment.mul(amount));

      if(_currentPrice < _lowerCap) {
        _currentPrice = _lowerCap;
      }

      msg.sender.transfer(valueLeftAfterDividend);
      updatePoolState(valueLeftAfterDividend, false);

      return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "To address cannot be empty.");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0), "Spender address cannot be empty.");
        require(owner != address(0), "Owner address cannot be empty.");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destroys the contract. OwnerOnly
     * @return An uint256 representing number of current dividends.
     */
    function destroy() public onlyOwner {
      selfdestruct(owner());
    }

    /**
     * @dev Fallback function to handle ethereum that was sent straight to the contract
     */
    function() external payable {
        buy(address(0));
    }
}
