pragma solidity ^0.5.1;

/*


  $$$$$$$$\  $$$$$$\  $$\   $$\  $$$$$$\          $$\      $$\ $$$$$$$\  $$$$$$$\
  $$  _____|$$  __$$\ $$$\  $$ |$$  __$$\         $$ | $\  $$ |$$  __$$\ $$  __$$\
  $$ |      $$ /  $$ |$$$$\ $$ |$$ /  \__|        $$ |$$$\ $$ |$$ |  $$ |$$ |  $$ |
  $$$$$\    $$$$$$$$ |$$ $$\$$ |$$ |$$$$\ $$$$$$\ $$ $$ $$\$$ |$$$$$$$  |$$$$$$$\ |
  $$  __|   $$  __$$ |$$ \$$$$ |$$ |\_$$ |\______|$$$$  _$$$$ |$$  ____/ $$  __$$\
  $$ |      $$ |  $$ |$$ |\$$$ |$$ |  $$ |        $$$  / \$$$ |$$ |      $$ |  $$ |
  $$ |      $$ |  $$ |$$ | \$$ |\$$$$$$  |        $$  /   \$$ |$$ |      $$$$$$$  |
  \__|      \__|  \__|\__|  \__| \______/         \__/     \__|\__|      \_______/


 */

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
      uint256 lastDividends;
    }

    struct Pool {
      uint status;
      bool sellAllowed;
      uint256 floor;
      uint256 ceiling;
      uint256 total;
      uint256 operatingPercent;
      uint256 operatingTotal;
      uint256 treasuryPercent;
      uint256 treasuryTotal;
      uint256 totalDividends;
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
    uint256 private _minimumEthSellAmount;
    uint256 private _tokenHolderDividend;
    uint256 private _referrerDividend;
    uint256 private _percentBase;
    address payable private _poolAccount;
    address payable private _tokenAccount;

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping(address => uint256) payouts;
    mapping (address => Account) accounts;

    Pool private _pool;

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

  /*
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    */

    event onClaimDividend(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    constructor(uint256 _initialFloor, uint256 _initialCeiling, uint256 _tokenAccountSupply) public {
        _name = "FANG-WPB";
        _symbol = "FANG";
        _decimals = 18;
        _supply = 3000000000;
        _poolAccount = address(0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C);
        _tokenAccount = address(0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB);
        _currentPrice = .000053 ether;
        _increment = .000000001 ether;
        _lowerCap = .0000053 ether;
        _minimumEthSellAmount = .01 ether;
        _tokenHolderDividend = 10; // this is a percentage
        _referrerDividend = 30;// this is a percentage of tokenholder dividend
        _percentBase = 100; // _percentBase.div(uint256) will return a whole integer percentage value you can divide large numbers with

        // Give founder all supply
        _balances[owner()] = _supply.sub(_tokenAccountSupply);
        _balances[_tokenAccount] = _tokenAccountSupply;

        // Set the pool initial values
        require(_initialFloor < _initialCeiling, "Ceiling must be greater than the floor.");
        _pool.floor = _initialFloor;
        _pool.ceiling = _initialCeiling;
        _pool.operatingPercent = 10;
        _pool.treasuryPercent = 10;
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
        return _pool.totalDividends;
    }

    /**
     * @dev Gets the current price for 1 token.
     * @return An uint256 representing the current price for 1 token.
     */
    function currentPrice() public view returns (uint256){
        return _currentPrice;
    }

    /**
     * @dev Gets the minimum ETH sell amount.
     * @return An uint256 representing the minimum number of ETH for a sell.
     */
    function minimumEthSellAmount() public view returns (uint256){
        return _minimumEthSellAmount;
    }

    /**
     * @dev Gets the dividend for token holders.
     * @return An uint256 representing the dividend for token holders.
     */
    function tokenHolderDividend() public view returns (uint256){
        return _tokenHolderDividend;
    }

    /**
     * @dev Gets the dividend of a referrer
     * @return An uint256 representing the dividend for the referrer.
     */
    function referrerDividend() public view returns (uint256){
        return _referrerDividend;
    }

    /**
     * @dev Gets the dividend of a referrer
     * @return An uint256 representing the dividend for the referrer.
     */
    function divideByPercent(uint256 percent) private view returns (uint256){
        uint256 result = _percentBase.div(percent);
        return result;
    }

    /**
     * @dev Gets the current pool information.
     * @return Properties related to the pool information.
     */
    function getPoolInfo() public view returns (uint status, uint256 total, uint256 floor, uint256 ceiling, uint256 operatingTotal, uint256 treasuryTotal, uint256 totalDividends, bool sellAllowed){
        return (_pool.status, _pool.total, _pool.floor, _pool.ceiling, _pool.operatingTotal, _pool.treasuryTotal, _pool.totalDividends, _pool.sellAllowed);
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

        // Withdraw all outstanding dividends first
        uint256 owing = dividendBalanceOf(msg.sender);
        if (owing > 0) {
          claimDividend();
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Sets the name of the token. OnlyOwner
     * @param newName The new token name.
     */
    function setName(string memory newName) public onlyOwner {
        _name = newName;
    }

    /**
     * @dev Sets the symbol of the token. OnlyOwner
     * @param newSymbol The new symbol for the token.
     */
    function setSymbol(string memory newSymbol) public onlyOwner {
        _symbol = newSymbol;
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
     * @dev Updates the minimum ETH sell amount. OnlyOwner
     * @param newMinimumEthSellAmount The new minimum amount of ETH for a sell.
     */
    function setMinimumEthSellAmount(uint256 newMinimumEthSellAmount) public onlyOwner {
        _minimumEthSellAmount = newMinimumEthSellAmount;
    }

    /**
     * @dev Updates the token holder dividend. OnlyOwner
     * @param newTokenHolderDividend The new token holder dividend.
     */
    function setTokenHolderDividend(uint256 newTokenHolderDividend) public onlyOwner {
        _tokenHolderDividend = newTokenHolderDividend;
    }

    /**
     * @dev Updates the referral dividend. OnlyOwner
     * @param newReferrerDividend The new referral dividend.
     */
    function setReferrerDividend(uint256 newReferrerDividend) public onlyOwner {
        _referrerDividend = newReferrerDividend;
    }

    /**
     * @dev Gets the total accumilated dividends. OnlyOwner
     * @param floor The updated floor of the pool
     * @param ceiling The updated ceiling of the pool
     * @return An uint256 representing number of current dividends.
     */
    function setPoolValues(uint256 floor, uint256 ceiling) public onlyOwner {
        require(floor < ceiling, "Ceiling must be greater than the floor.");
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
              require(_pool.total.sub(amountChange) >= 0, "Pool total can not go below 0.");
                _pool.total = _pool.total.sub(amountChange);
          }
        }

        // If selling was allowed, only turn it off if <= floor
        if(_pool.sellAllowed && _pool.total <= _pool.floor)
        {
            _pool.sellAllowed = false;
        }
        // If selling wasn't allowed, turn it back on if >= ceiling
        else if(!_pool.sellAllowed && _pool.total >= _pool.ceiling)
        {
            _pool.sellAllowed = true;
        }
    }

     /**
     * @dev Frontend function to calculate how many tokens could be bought with an amount of ETH.
     * @param weiToSpend Amount of ETH to spend.
     */
    function calculateTokensReceived(uint256 weiToSpend) public view returns(uint256) {
      uint256 totalDividend = weiToSpend.div(divideByPercent(_tokenHolderDividend));
      uint256 ethValueLeftForPurchase = weiToSpend.sub(totalDividend);
      return ethValueLeftForPurchase.div(_currentPrice);
    }

     /**
     * @dev Frontend function to calculate how much ETH would be returned after a sell.
     * @param tokensToSell Amount of tokens to sell.
     */
    function calculateEthReceived(uint256 tokensToSell) public view returns(uint256) {
        require(tokensToSell > 0, "Must sell an amount greater than 0.");
        require(tokensToSell <= _balances[msg.sender], "Cannot sell more than the balance.");

        uint256 ethValue = tokensToSell.mul(_currentPrice);
        uint256 holderDividend = ethValue.div(divideByPercent(_tokenHolderDividend));
        return ethValue.sub(holderDividend);
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
     * @dev Withdraw operating. OnlyOwner
     */
    function withdrawOperatingBalance() public onlyOwner {
        address payable owner = owner();
        owner.transfer(_pool.operatingTotal);
        _pool.operatingTotal = 0;
        // TODO: need event for withdrawing operating
        //emit Transfer(address(0), owner(), amount);
    }

    /**
     * @dev Withdraw treasury. OnlyOwner
     */
    function withdrawTreasuryBalance() public onlyOwner {
        address payable owner = owner();
        owner.transfer(_pool.treasuryTotal);
        _pool.treasuryTotal = 0;
        // TODO: need event for withdrawing treasury
        //emit Transfer(address(0), owner(), amount);
    }
    
    /**
     * @dev Fund Total dividends.  "Rain on holders propertionally."
     */
    function fundTotalDividends() public payable {
        _pool.totalDividends = _pool.totalDividends.add(msg.value);
        // TODO: need event for funding dividends
        //emit Transfer(address(0), owner(), amount);
    }

    /**
     * @dev Buy tokens with sent ETH. Dividends are sent to the referrer (if exists) and all token holders.
     * @param referrer Address of the referrer.
     * @return Bool success
     */
    function buy(address payable referrer) public payable returns (bool) {
      require(msg.sender != referrer, "Buyer and referrer cannot be the same.");
      claimDividendByAddress(msg.sender);

      /*
        Dividends
       */
      uint256 tokenAmount = 0; 
        uint256 referralDividend = 0;
        uint256 actualTokenHolderDividend = 0;
        uint256 operatingCut = 0;
        uint256 treasuryCut = 0;
        uint256 poolIncrease = 0;
        bool hasReferrer = false;

      if(referrer != address(0))
      {
          hasReferrer = true;
      }

      (tokenAmount, referralDividend, actualTokenHolderDividend, operatingCut, treasuryCut, poolIncrease) = estimateBuy(msg.value, hasReferrer);
      
     /*
        Tokens
      */
      require(_balances[_tokenAccount] > tokenAmount, "Not enough tokens available for sale.");
      require(poolIncrease >= _currentPrice, "Amount must be greater than or equal to the token price.");

      _balances[msg.sender] = _balances[msg.sender].add(tokenAmount);
      _balances[_tokenAccount] = _balances[_tokenAccount].sub(tokenAmount);
      
      
      // Adjust pool values
      _pool.operatingTotal = _pool.operatingTotal.add(operatingCut);

      _pool.treasuryTotal = _pool.treasuryTotal.add(treasuryCut);
      
      _pool.totalDividends = _pool.totalDividends.add(actualTokenHolderDividend);
      
      updatePoolState(poolIncrease, true);
      
      // Pay Referrer if necessary
      if(hasReferrer)
      {
          referrer.transfer(referralDividend);
      }

      emit Transfer(_tokenAccount, msg.sender, tokenAmount);
      emit onTokenPurchase(msg.sender, msg.value, tokenAmount, referrer);

      // Update the current price based on actual token amount sold
      _currentPrice = _currentPrice.add(_increment.mul(tokenAmount));

      return true;
    }
    
    /**
     * @dev Calculate buy numbers
     */
    function estimateBuy(uint256 value, bool hasReferrer) public view returns(uint256 tokens, uint256 referrerValue, uint256 totalDividendIncrease, uint256 operatingIncrease, uint256 treasuryIncrease, uint256 poolIncrease) {
        uint256 tokenAmount; 
        uint256 referralDividend;
        uint256 actualTokenHolderDividend;
        uint256 operatingCut;
        uint256 treasuryCut;
        uint256 poolIncreaseAmt;
        
         /*
        Dividends
       */
      uint256 totalDividend = calculateTotalDividend(value);

      if(hasReferrer)
      {
        referralDividend = calculateReferralDividend(totalDividend); 
      }

      actualTokenHolderDividend = totalDividend.sub(referralDividend);

     /*
        Tokens
      */
      
      operatingCut = calculateOperatingCut(value);

      treasuryCut = calculateTreasuryCut(value);

      poolIncreaseAmt = calculatePoolIncrease(value, totalDividend, operatingCut, treasuryCut);

      // Determine how many tokens can be bought
      tokenAmount = poolIncreaseAmt.div(_currentPrice);
      require(_balances[_tokenAccount] > tokenAmount, "Not enough tokens available for sale.");
      require(poolIncreaseAmt >= _currentPrice, "Amount must be greater than or equal to the token price.");
        
      return (tokenAmount, referralDividend, actualTokenHolderDividend, operatingCut, treasuryCut, poolIncreaseAmt);
    }
    
    
    function calculateTotalDividend(uint256 valueIn) private view returns(uint256 valueOut)
    {
        return(valueIn.div(divideByPercent(_tokenHolderDividend)));
    }
    
    function calculateReferralDividend(uint256 valueIn) private view returns(uint256 valueOut)
    {
        return(valueIn.div(divideByPercent(_referrerDividend)));
    }
    
    function calculatePoolIncrease(uint256 valueIn, uint256 valueSubDividends, uint256 valueSubOperating, uint256 valueSubTreasury) private pure returns(uint256 valueOut)
    {
        return(valueIn.sub(valueSubDividends).sub(valueSubOperating).sub(valueSubTreasury));
    }
    
    function calculateOperatingCut(uint256 valueIn) private view returns(uint256 valueOut)
    {
        return(valueIn.div(divideByPercent(_pool.operatingPercent)));
    }
    
    function calculateTreasuryCut(uint256 valueIn) private view returns(uint256 valueOut)
    {
        return(valueIn.div(divideByPercent(_pool.treasuryPercent)));
    }

    /**
     * @dev Gets the current dividend balance owed to an address.
     * @param account Account address to get the dividend balance.
     * @return An uint256 representing number of dividends currently owed to the address.
     */
    function dividendBalanceOf(address account) public view returns (uint256) {
      uint256 newDividends = _pool.totalDividends.sub(accounts[account].lastDividends);
      uint256 product = _balances[account].mul(newDividends);
      return product.div(_supply);
    }

    /**
     * @dev Claim the currently owed dividends.
     */
    function claimDividend() public {
      claimDividendCore(msg.sender);
    }

    /**
     * @dev Claim the currently owed dividends.
     */
    function claimDividendByAddress(address payable sender) private {
      claimDividendCore(sender);
    }

    function claimDividendCore(address payable sender) private {
      uint256 owing = dividendBalanceOf(sender);
      if (owing > 0) {
        sender.transfer(owing);
        accounts[sender].lastDividends = _pool.totalDividends;
        emit onClaimDividend(sender, owing);
      }
    }

    /**
     * @dev Sells an amount of tokens, and triggers a dividend.
     * @param tokenAmount Amount of tokens to sell.
     * @return Bool success
     */
    function sell(uint256 tokenAmount) public returns (bool) {
      require(_pool.sellAllowed, "Sell is not yet allowed.");
      require(tokenAmount > 0, "Must sell an amount greater than 0.");

      uint256 ethValue = tokenAmount.mul(_currentPrice);
      require(ethValue >= _minimumEthSellAmount, "Transaction minimum not met.");

      claimDividendByAddress(msg.sender);

      uint256 holderDividend = ethValue.div(divideByPercent(_tokenHolderDividend));
      _pool.totalDividends = _pool.totalDividends.add(holderDividend);
      uint256 ethValueLeftAfterDividend = ethValue.sub(holderDividend);

      require(tokenAmount <= _balances[_tokenAccount], "Cannot sell more than the balance.");
      require(address(this).balance >= ethValueLeftAfterDividend, "Unable to fund the sell transaction.");

      claimDividendByAddress(msg.sender);

      _balances[msg.sender] = _balances[msg.sender].sub(tokenAmount);
      _balances[_tokenAccount] = _balances[_tokenAccount].add(tokenAmount);

      emit Transfer(msg.sender, _tokenAccount, tokenAmount);

      // Update the current price based on actual token amount sold
      _currentPrice = _currentPrice.sub(_increment.mul(tokenAmount));

      if(_currentPrice < _lowerCap) {
        _currentPrice = _lowerCap;
      }

      msg.sender.transfer(ethValueLeftAfterDividend);
      updatePoolState(ethValueLeftAfterDividend, false);

      emit onTokenSell(msg.sender, tokenAmount, holderDividend);

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
     * @dev Alias to sell and claim all dividends
     */
    function exit() public {
        uint256 _tokens = _balances[msg.sender];
        if(_tokens > 0) {
          sell(_tokens);
        }

        claimDividend();
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
