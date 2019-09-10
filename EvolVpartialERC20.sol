pragma solidity ^0.5.1;

/*


   $$$$$$$$\                  $$\             $$\     $$\                           $$$$$$$$\        $$\                           
   $$  _____|                 $$ |            $$ |    \__|                          \__$$  __|       $$ |                          
   $$ |  $$\    $$\  $$$$$$\  $$ |$$\   $$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\           $$ | $$$$$$\  $$ |  $$\  $$$$$$\  $$$$$$$\  
   $$$$$\\$$\  $$  |$$  __$$\ $$ |$$ |  $$ |\_$$  _|  $$ |$$  __$$\ $$  __$$\          $$ |$$  __$$\ $$ | $$  |$$  __$$\ $$  __$$\ 
   $$  __|\$$\$$  / $$ /  $$ |$$ |$$ |  $$ |  $$ |    $$ |$$ /  $$ |$$ |  $$ |         $$ |$$ /  $$ |$$$$$$  / $$$$$$$$ |$$ |  $$ |
   $$ |    \$$$  /  $$ |  $$ |$$ |$$ |  $$ |  $$ |$$\ $$ |$$ |  $$ |$$ |  $$ |         $$ |$$ |  $$ |$$  _$$<  $$   ____|$$ |  $$ |
   $$$$$$$$\\$  /   \$$$$$$  |$$ |\$$$$$$  |  \$$$$  |$$ |\$$$$$$  |$$ |  $$ |         $$ |\$$$$$$  |$$ | \$$\ \$$$$$$$\ $$ |  $$ |
   \________|\_/     \______/ \__| \______/    \____/ \__| \______/ \__|  \__|         \__| \______/ \__|  \__| \_______|\__|  \__|
                                                                                                                                

 */

contract ERC20Interface {
    function transfer(address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address payable private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev he Ownable constructor sets the original `owner` of the contract to the sender
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

contract Freezable is Ownable {
    mapping (address => bool) _frozen;
    
      event AddressFrozen(
        address Address
      );
  
      event AddressUnfrozen(
        address Address
      );
    
    /**
  * @dev Allows the owner to freeze an address
  * @param account is the address used by the function to freeze
  */
        function freezeAddress(address account) public onlyOwner {
            require(_frozen[account] == false, "Freezable: Account already frozen, unable to freeze.");
            _frozen[account] = true;
            emit AddressFrozen(account);
        }
    
        /**
  * @dev Allows the owner to unfreeze an address
  * @param account is the address used by the function to unfreeze
  */
        function unfreezeAddress(address account) public onlyOwner {
            require(_frozen[account] == true, "Freezable: Account not frozen, unable to unfreeze.");
            _frozen[account] = false;
            emit AddressUnfrozen(account);
        }
    
        /**
      * @return if the address is frozen
      */
      function isFrozen(address account) public view returns(bool) {
        return _frozen[account];
      }
      
     /**
      * @return if the address is frozen
      */
      function requireUnfrozen(address account) internal view returns(bool) {
        require(!isFrozen(account), "Address involved in transaction is frozen.");
      }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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

contract EvolutionToken is ERC20Interface, Ownable, Pausable, Freezable{

    using SafeMath for uint;
    using SafeMath for uint8;
    using SafeMath for uint32;
    using SafeMath for uint64;
    using SafeMath for uint128;
    using SafeMath for uint256;

    struct Pool {
      bool sellAllowed;
      uint256 floor;
      uint256 ceiling;
      uint256 total;
      uint256 totalDividends;
      uint256 buyReferrerPercent;
      uint256 buyHolderPercent;
      uint256 sellHolderPercent;
      uint256 buyMintOwnerPercent;
      uint256 sellHoldOwnerPercent;
      uint256 totalDividendsClaimed;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint private _supply;
    uint256 private _totalTokensBought;
    uint256 private _totalTokensSold;
    uint256 private _currentPrice;
    uint256 private _increment;
    uint256 private _lowerCap;
    uint256 private _minimumEthSellAmount;
    uint256 private _percentBase; // Should be 100 if using whole int percents.

    mapping(address => uint256) private _balances;
    mapping (address => uint256) _lastDividends;

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

  
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokens
    );

    event onClaimDividend(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    event onDividendIncrease(
        uint256 totalDividendIncrease
    );
    
    
    event onSellEnabledChange(
        bool enabled
    );

    event onPriceChange(
        uint256 price
    );

    event onMint(
        uint256 amount,
        uint256 supply
    );
    
    event onBurn(
        uint256 amount,
        uint256 supply
    );

    constructor() public {
        _name = "Evolution Token";
        _symbol = "EvolV";
        _decimals = 0;
        _supply = 600000000;
        _currentPrice = .000053 ether;
        _increment = .000000001 ether;
        _lowerCap = .0000053 ether;
        _minimumEthSellAmount = .01 ether;
        _percentBase = 100; // _percentBase.div(uint256) will return a whole integer percentage value you can divide large numbers with

        // Give founder all supply
        _balances[owner()] = _supply;

        // Set the pool initial values
        _pool.floor = 1 ether;
        _pool.ceiling = 10 ether;
        _pool.buyReferrerPercent = 5;
        _pool.buyHolderPercent = 10;
        _pool.sellHolderPercent = 10;
        _pool.buyMintOwnerPercent = 10;
        _pool.sellHoldOwnerPercent = 10;
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
     * @dev Gets the dividend of a referrer
     * @return An uint256 representing the dividend for the referrer.
     */
    function divideByPercent(uint256 percent) private view returns (uint256){
        uint256 result = _percentBase.div(percent);
        return result;
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
     // ERC20
    function transfer(address recipient, uint256 amount) public whenNotPaused  returns (bool) {
        return transferCore(msg.sender, recipient, amount);
    }

    /**
     * @dev Transfer tokens from the sender to another address.
     * @param sender address The address which you want to transfer from.
     * @param recipient address The address which you want to transfer to.
     * @param amount uint256 the amount of tokens to be transferred.
     * @return Bool success
     */
    function transferCore(address payable sender, address recipient, uint256 amount) private whenNotPaused  returns (bool) {
        requireUnfrozen(sender);
        requireUnfrozen(recipient);
        require(sender != address(0), "Send cannot be empty.");
        require(recipient != address(0), "Recipient cannot be empty.");
        require(_balances[sender] >= amount, "Insufficient balance to send tokens.");
        
        address payable recip = address(uint160(recipient));

        // Withdraw all outstanding dividends first
        uint256 senderOwing = dividendBalanceOf(sender);
        if (senderOwing > 0) {
          claimDividendByAddress(sender);
        }
        uint256 recipOwing = dividendBalanceOf(recip);
        if (recipOwing > 0) {
          claimDividendByAddress(recip);
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
     * @dev Updates the minimum ETH sell amount. OnlyOwner
     * @param newMinimumEthSellAmount The new minimum amount of ETH for a sell.
     */
    function setMinimumEthSellAmount(uint256 newMinimumEthSellAmount) public onlyOwner {
        _minimumEthSellAmount = newMinimumEthSellAmount;
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
            emit onSellEnabledChange(_pool.sellAllowed);
        }
        // If selling wasn't allowed, turn it back on if >= ceiling
        else if(!_pool.sellAllowed && _pool.total >= _pool.ceiling)
        {
            _pool.sellAllowed = true;
            emit onSellEnabledChange(_pool.sellAllowed);
        }
    }

    /**
     * @dev Burn an amount of tokens. OnlyOwner
     * @param amount Amount of tokens to burn.
     */
    function burn(uint256 amount) public whenNotPaused {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _supply = _supply.sub(amount);
        emit Transfer(owner(), address(0), amount);
        emit onBurn(amount, _supply);
    }

    /**
     * @dev Mint new tokens. OnlyOwner
     * @param amount Amount of tokens to mint.
     */
    function mint(uint256 amount) public whenNotPaused onlyOwner {
        _supply = _supply.add(amount);
        _balances[owner()] = _balances[owner()].add(amount);
        emit Transfer(address(0), owner(), amount);
        emit onMint(amount, _supply);
    }
    
    /**
     * @dev Fund Total dividends.  "Rain on holders propertionally."
     */
    function fundTotalDividends() public whenNotPaused payable {
        increaseTotalDividends(msg.value);
        emit onDividendIncrease(msg.value);
    }
    
    /**
     * @dev Fund Total dividends.  "Rain on holders propertionally."
     */
    function increaseTotalDividends(uint256 value) private {
        _pool.totalDividends = _pool.totalDividends.add(value);
        emit onDividendIncrease(value);
    }

    /**
     * @dev Buy tokens with sent ETH. Dividends are sent to the referrer (if exists) and all token holders.
     * @param referrer Address of the referrer.
     * @return Bool success
     */
    function buy(address payable referrer) public payable whenNotPaused returns (bool) {
        requireUnfrozen(msg.sender);
      require(msg.sender != referrer, "Buyer and referrer cannot be the same.");
      claimDividendByAddress(msg.sender);
      buyCore(referrer, msg.value);
      return true;
    }
    
    /**
     * @dev Calculate buy numbers
     */
    function estimateBuy(uint256 value, bool hasReferrer) public view returns(uint256 tokens, uint256 referrerDividend, uint256 holdingDividend, uint256 poolIncrease) {
        uint256 tokenAmount; 
        uint256 referralDividend;
        uint256 holderDividend;
        uint256 poolIncreaseAmt;
        
         /*
        Dividends
       */

      if(hasReferrer)
      {
        referralDividend = value.div(divideByPercent(_pool.buyReferrerPercent)); 
        holderDividend = value.div(divideByPercent(_pool.buyHolderPercent)); 
      }
      else
      {
         holderDividend = value.div(divideByPercent(_pool.buyHolderPercent.add(_pool.buyReferrerPercent)));  
      }


     /*
        Tokens
      */
      
      uint256 allDividends = holderDividend.add(referralDividend);

      poolIncreaseAmt = value.sub(allDividends);

      // Determine how many tokens can be bought with original value
      tokenAmount = calculateTokenAmount(value);
        
      return (tokenAmount, referralDividend, holderDividend, poolIncreaseAmt);
    }
    
    function buyCore(address payable referrer, uint256 msgValue) private returns(uint256)
    {
        /*
        Dividends
       */
        uint256 tokenAmount = 0;
        uint256 referralDividend = 0;
        uint256 holderDividend = 0;
        uint256 poolIncrease = 0;
        bool hasReferrer = false;

      if(referrer != address(0))
      {
          hasReferrer = true;
      }

      (tokenAmount, referralDividend, holderDividend, poolIncrease) = estimateBuy(msgValue, hasReferrer);
      
     /*
        Tokens
      */
      require(poolIncrease >= _currentPrice, "Amount must be greater than or equal to the token price.");

      mintOnBuy(msg.sender, tokenAmount);
      
      increaseTotalDividends(holderDividend);
      
      updatePoolState(poolIncrease, true);
      
      // Pay Referrer if necessary
      if(hasReferrer)
      {
          referrer.transfer(referralDividend);
      }
      else
      {
          owner().transfer(referralDividend);
      }

      emit onTokenPurchase(msg.sender, msgValue, tokenAmount, referrer);

      // Update the current price based on actual token amount sold
      _currentPrice = _currentPrice.add(_increment.mul(tokenAmount));
      emit onPriceChange(_currentPrice);
      
      // Update total tokens purchased
      _totalTokensBought = _totalTokensBought.add(tokenAmount);
      
      return tokenAmount;
    }
    
    /**
     * @dev mintOnBuy
     */
     function mintOnBuy(address sender, uint256 tokenAmount) private returns(bool)
     {
         uint256 ownerMintedTokens = 0;
         uint256 totalMintedTokens = tokenAmount;
         
         // give owner their percent
         if(_pool.buyMintOwnerPercent > 0)
         {
            ownerMintedTokens = tokenAmount.div(divideByPercent(_pool.buyMintOwnerPercent));
            _balances[owner()] = _balances[owner()].add(ownerMintedTokens);
            totalMintedTokens = totalMintedTokens.add(ownerMintedTokens);
         }
         
         _balances[sender] = _balances[sender].add(tokenAmount);
         _supply = _supply.add(totalMintedTokens);
         
         emit onMint(totalMintedTokens, _supply);
         
         return true;
     }
     
    /**
     * @dev reinvest
     */
     function reinvest(address payable referrer) public returns(uint256 tokenAmount)
     {
         uint256 tokensFromReinvestment = 0;
         
         uint256 ethValue = dividendBalanceOf(msg.sender);
         require(ethValue > 0, "No dividends to reinvest.");
         
         _lastDividends[msg.sender] = _pool.totalDividends;
         
         tokensFromReinvestment = buyCore(referrer, ethValue);
         emit onReinvestment(msg.sender, ethValue, tokensFromReinvestment);
         
         return tokensFromReinvestment;
     }
    
    function calculateTokenAmount(uint256 valueIn) private view returns(uint256 valueOut)
    {
        return(valueIn.div(_currentPrice));
    }

    /**
     * @dev Gets the current dividend balance owed to an address.
     * @param account Account address to get the dividend balance.
     * @return An uint256 representing number of dividends currently owed to the address.
     */
    function dividendBalanceOf(address account) public view returns (uint256) {
      uint256 newDividends = _pool.totalDividends.sub(_lastDividends[account]);
      uint256 product = _balances[account].mul(newDividends);
      return product.div(_supply);
    }

    /**
     * @dev Claim the currently owed dividends.
     */
    function claimDividend() whenNotPaused public {
        requireUnfrozen(msg.sender);
        claimDividendCore(msg.sender);
    }

    /**
     * @dev Claim the currently owed dividends.
     */
    function claimDividendByAddress(address payable sender) private whenNotPaused {
        requireUnfrozen(sender);
        claimDividendCore(sender);
    }

    function claimDividendCore(address payable sender) private whenNotPaused {
      uint256 owing = dividendBalanceOf(sender);
      require(_pool.totalDividendsClaimed.add(owing) <= _pool.totalDividends, "Unable to fund dividend claim.");
      if (owing > 0) {
        sender.transfer(owing);
        _lastDividends[sender] = _pool.totalDividends;
        _pool.totalDividendsClaimed = _pool.totalDividendsClaimed.add(owing);
        emit onClaimDividend(sender, owing);
      }
    }

    /**
     * @dev Sells an amount of tokens, and triggers a dividend.
     * @param tokenAmount Amount of tokens to sell.
     * @return Bool success
     */
    function sell(uint256 tokenAmount) public whenNotPaused returns (bool) {
        requireUnfrozen(msg.sender);
      require(_pool.sellAllowed, "Sell is not yet allowed.");
      require(tokenAmount > 0, "Must sell an amount greater than 0.");

      uint256 ethValue = tokenAmount.mul(_currentPrice);
      require(ethValue >= _minimumEthSellAmount, "Transaction minimum not met.");

      claimDividendByAddress(msg.sender);

      uint256 holderDividend = 0;
      uint256 ethValueLeftAfterDividend = 0;
      (holderDividend, ethValueLeftAfterDividend) = estimateSell(tokenAmount);
      increaseTotalDividends(holderDividend);

      
      require(address(this).balance >= ethValueLeftAfterDividend, "Unable to fund the sell transaction.");

      burnOnSell(msg.sender, tokenAmount);

      // Update the current price based on actual token amount sold
      _currentPrice = _currentPrice.sub(_increment.mul(tokenAmount));

      if(_currentPrice < _lowerCap) {
        _currentPrice = _lowerCap;
      }

      emit onPriceChange(_currentPrice);

      msg.sender.transfer(ethValueLeftAfterDividend);
      updatePoolState(ethValueLeftAfterDividend, false);

      emit onTokenSell(msg.sender, tokenAmount, holderDividend);
      
      // Update total tokens sold
      _totalTokensSold = _totalTokensSold.add(tokenAmount);

      return true;
    }
    
    /**
     * @dev Calculate sell numbers
     */
    function estimateSell(uint256 tokenAmount) public view returns(uint256 ethValue, uint256 dividendValue) {
      // Value = tokens * price
        uint256 value = tokenAmount.mul(_currentPrice);

      // Dividends
      uint256 holderDividend = value.div(divideByPercent(_pool.sellHolderPercent));
      uint256 valueToReceive = value.sub(holderDividend);

      return (valueToReceive, holderDividend);
    }
    
    /**
     * @dev burnOnSell
     */
     function burnOnSell(address sender, uint256 tokenAmount) private returns(bool)
     {
         require(_balances[sender] > tokenAmount, "Sender unable to fund burn. Insufficient tokens.");
         uint256 ownerSavedTokens = 0;
         uint256 totalBurnedTokens = tokenAmount;
         
         if(_pool.sellHoldOwnerPercent > 0)
         {
             ownerSavedTokens = tokenAmount.div(divideByPercent(_pool.sellHoldOwnerPercent));
             totalBurnedTokens = totalBurnedTokens.sub(ownerSavedTokens);
         }
         
         
         _balances[sender] = _balances[sender].sub(tokenAmount);
         _balances[owner()] = _balances[owner()].add(ownerSavedTokens);
         _supply = _supply.sub(totalBurnedTokens);
         
         emit onBurn(totalBurnedTokens, _supply);
         
         return true;
     }

    /**
     * @dev Alias to sell and claim all dividends
     */
    function exit() public whenNotPaused {
        requireUnfrozen(msg.sender);
        uint256 _tokens = _balances[msg.sender];
        if(_tokens > 0) {
          sell(_tokens); //will auto claim dividends
        }
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
    
    /**
     * @dev Sets the pool floor
     * @param floor The updated floor of the pool
     * @return A bool to show it completed successfully
     */
    function setPoolFloor(uint256 floor) public onlyOwner returns(bool) {
        require(floor < _pool.ceiling, "Ceiling must be greater than the floor.");
        _pool.floor = floor;

        updatePoolState(0, false);

        return true;
    }

    /**
     * @dev Sets the pool ceiling
     * @param ceiling The updated ceiling of the pool
     * @return A bool to show it completed successfully
     */
    function setPoolCeiling(uint256 ceiling) public onlyOwner returns(bool) {
        require(ceiling > _pool.floor, "Ceiling must be greater than the ceiling.");
        _pool.ceiling = ceiling;

        updatePoolState(0, false);

        return true;
    }


    /**
     * @dev Sets the pool buyReferrerPercent
     * @param buyReferrerPercent The updated buyReferrerPercent of the pool
     * @return A bool to show it completed successfully
     */
    function setPoolBuyReferrerPercent(uint256 buyReferrerPercent) public onlyOwner returns(bool) {
        require(buyReferrerPercent >= 0, "Must be >= 0.");
        _pool.buyReferrerPercent = buyReferrerPercent;

        return true;
    }
    
    /**
     * @dev Sets the pool buyHolderPercent
     * @param buyHolderPercent The updated buyHolderPercent of the pool
     * @return A bool to show it completed successfully
     */
    function setPoolBuyHolderPercent(uint256 buyHolderPercent) public onlyOwner returns(bool) {
        require(buyHolderPercent >= 0, "Must be >= 0.");
        _pool.buyHolderPercent = buyHolderPercent;

        return true;
    }
    
    /**
     * @dev Sets the pool sellHolderPercent
     * @param sellHolderPercent The updated sellHolderPercent of the pool
     * @return A bool to show it completed successfully
     */
    function setPoolSellHolderPercent(uint256 sellHolderPercent) public onlyOwner returns(bool) {
        require(sellHolderPercent >= 0, "Must be >= 0.");
        _pool.sellHolderPercent = sellHolderPercent;

        return true;
    }
    
    /**
     * @dev Sets the pool buyMintOwnerPercent
     * @param buyMintOwnerPercent The updated buyMintOwnerPercent of the pool
     * @return A bool to show it completed successfully
     */
    function setPoolBuyMintOwnerPercent(uint256 buyMintOwnerPercent) public onlyOwner returns(bool) {
        require(buyMintOwnerPercent >= 0, "Must be >= 0.");
        _pool.buyMintOwnerPercent = buyMintOwnerPercent;

        return true;
    }
    
    /**
     * @dev Sets the pool sellHoldOwnerPercent
     * @param sellHoldOwnerPercent The updated sellHoldOwnerPercent of the pool
     * @return A bool to show it completed successfully
     */
    function setPoolSellHoldOwnerPercent(uint256 sellHoldOwnerPercent) public onlyOwner returns(bool) {
        require(sellHoldOwnerPercent >= 0, "Must be >= 0.");
        _pool.sellHoldOwnerPercent = sellHoldOwnerPercent;

        return true;
    }
    
    /**
     * @dev gets wether contract is funded for both the pool and unclaimed dividends
     * @return A bool to show if balanced
     */
    function getIsPoolBalanced() private view returns(bool) {
        uint256 dividendsUnclaimed = _pool.totalDividends.sub(_pool.totalDividendsClaimed);
        if(address(this).balance == _pool.total.add(dividendsUnclaimed))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    /**
     * @dev Gets the current pool information.
     * @return Properties related to the pool information.
     */
    function getPoolInfo() public view returns (uint256 total, uint256 floor, uint256 ceiling, uint256 totalDividends, bool sellAllowed, uint256 contractEthValue
                                                , uint256 buyReferrerPercent, uint256 buyHolderPercent, uint256 sellHolderPercent, uint256 buyMintOwnerPercent, uint256 sellHoldOwnerPercent
                                                , uint256 totalDividendsClaimed, uint256 totalDividendsUnclaimed, bool fundingBalanced){
                                                    uint256 dividendsUnclaimed = _pool.totalDividends.sub(_pool.totalDividendsClaimed);
        return (_pool.total, _pool.floor, _pool.ceiling, _pool.totalDividends, _pool.sellAllowed, address(this).balance
                , _pool.buyReferrerPercent, _pool.buyHolderPercent, _pool.sellHolderPercent, _pool.buyMintOwnerPercent, _pool.sellHoldOwnerPercent
                , _pool.totalDividendsClaimed, dividendsUnclaimed, getIsPoolBalanced());
    }

}
