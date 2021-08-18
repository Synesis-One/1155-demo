pragma solidity 0.5.5;                                              
pragma experimental ABIEncoderV2;                                    

import "../lib/SafeMath.sol";                                       
import "../lib/IERC1155.sol";                                         
import "./TokenContract.sol";                                         

contract Dex1155 {                          
                using SafeMath for uint;                              
                TokenContract public tokenContract;                    
                // function distribute(uint256 _quantity) {              
                //     _mint
                //  }
                enum SIDE {BUY,SELL}                                   
                     SIDE side;                                         
                
                struct Token {                                        
                       uint tokenId;
                        // string name;
                        // uint price;
                        }
                struct Order {
                        uint id;
                        address payable trader;
                        Side side;                                   
                        uint tokenId;
                        uint amount;
                        uint filled;
                        uint price;
                        uint date;
                        }
                mapping(uint => bool) orderCancelled;                                
                mapping(uint => mapping(uint => uint)) public orderAmount;           
                mapping(address => uint) public etherBalance;                         
                mapping(address => mapping(uint => uint)) public etherOnHold;        
                mapping(uint => Token) public tokenIds;                               
                mapping(uint => mapping(address => uint)) public traderBalances;     
                mapping(address => mapping(address => uint256)) public tokens;       
                                                                                      
                mapping(uint => mapping(uint => Order[])) public orderBook;           
                
                uint[] public tokenIdList;
                uint public tokenIdCount;
                uint public nextOrderId;
                uint public nextTradeId;
                uint256 public feePercent;                                          
                address public admin;
                address public feeAccount;                                          

                constructor(                                                         
                    address _tokenContract,
                    address _feeAccount, 
                    uint _feePercent) 
                        public {
                        admin = msg.sender;
                        tokenContract = TokenContract(_tokenContract);
                        // require(address(token) != address(0));
                        // _token = token;
                        feeAccount = _feeAccount;
                        feePercent = _feePercent;     
                        }


    event Deposit(address indexed trader, uint amount, uint balance);     //args will b logged to chain 
    event Withdraw(address indexed trader, uint amount, uint balance);    //args will b logged to chain
	event TokenAdded(uint256 tokenId                                      //args will b logged to chain
    // , uint256 releaseTime
    );
    event NewTrade(                                                      
        uint tradeId,
        uint orderId,
        uint indexed tokenId,
        address payable indexed trader1,
        address payable indexed trader2,
        uint amount,
        uint price,
        uint date
    );
    
    // function setTokenContractAddress(address tokenContractAddress) public onlyAdmin {
    //     tokenContract = IERC1155(tokenContractAddress);
    // }  

    function dexBalance(uint _tokenId, address _addr) external view tokenExist(_tokenId) returns(uint) {   
        return traderBalances[_tokenId][_addr];
    }
    function availableDepositBalance(uint _tokenId, address _addr) external view tokenExist(_tokenId) returns(uint) {
        tokenContract.balanceOf(_addr, _tokenId);    //tokenId here is from NewTrade event. heres an example of a new feature as part of new interface of 1155 token standard. balanceOf() 
    }
    function ethBalance(address addr) external view returns(uint) {
        return etherBalance[addr];
    }
    function adminTransferToken(address _to, uint256 tokenId, uint _amount) external onlyAdmin(){
        IERC1155(tokenContract).safeTransferFrom(address(this), _to, tokenId, _amount, "");
    }

    function adminTransferAllocate(address _to, uint256 tokenId, uint _amount) external onlyAdmin(){
        traderBalances[tokenId][_to] = traderBalances[tokenId][_to].add(_amount);

    }    function transferToken(address _to, uint256 tokenId, uint _amount) external {
        require(traderBalances[tokenId][msg.sender] >= _amount, 'not enough tokens');
        traderBalances[tokenId][msg.sender] = traderBalances[tokenId][msg.sender].sub(_amount);
        IERC1155(tokenContract).safeTransferFrom(address(this), _to, tokenId, _amount, "");
    }
    
    function setApproval(address _operator) external {
        tokenContract.setApprovalForAll(_operator, true);
    }

    function createToken(uint _initialSupply, string memory _uri, uint _tokenId) public onlyAdmin() {
        tokenContract.create(_initialSupply, _uri);
        addToken(_tokenId);
    }


    function mintToken(uint id, address[] memory to, uint[] memory quantities ) public onlyAdmin() {
        tokenContract.mint(id, to, quantities);
    }
    
    function depositEther() payable public {
        etherBalance[msg.sender] = etherBalance[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value, etherBalance[msg.sender]);
    }
    
    function withdrawEther(uint _amount) public returns(uint){
        require(etherBalance[msg.sender] >= _amount);
        etherBalance[msg.sender] = etherBalance[msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _amount, etherBalance[msg.sender]);
        return etherBalance[msg.sender];
    }

    function depositToken(uint _tokenId, uint _amount) public tokenExist(_tokenId) {

        tokenContract.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        traderBalances[_tokenId][msg.sender] = traderBalances[_tokenId][msg.sender].add(_amount);
        
    }
    function withdrawToken(uint _tokenId, uint _amount) public tokenExist(_tokenId) returns(uint){
        require(traderBalances[_tokenId][msg.sender] >= _amount);
        traderBalances[_tokenId][msg.sender] = traderBalances[_tokenId][msg.sender].sub(_amount);
        tokenContract.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        return traderBalances[_tokenId][msg.sender];
        
    }

    // function safeBatchTransferFrom(address _from, address _to, uint[] calldata _tokenIds, uint[] calldata _amounts, bytes calldata _data) external {
    //     // require(traderBalances[_tokenIds][msg.sender] >= _amounts, 'not enough tokens');
    //     // require(_to != address(0x0), "destination address must be non-zero.");
    //     // require(_tokenIds.length == _amounts.length, "_ids and _values array lenght must match.");

    //     for (uint i = 0; i < _tokenIds.length; ++i) {
    //         uint tokenId =    _tokenIds[i];
    //         uint amount = _amounts[i];

    //         // SafeMath will throw with insuficient funds _from
    //         // or if _id is not valid (balance will be 0)
    //         traderBalances[tokenId][_from] = traderBalances[tokenId][_from].sub(amount);
    //         traderBalances[tokenId][_to]   = traderBalances[tokenId][_to].add(amount);
    //     }
    //     tokenContract.safeBatchTransferFrom(address(this), _to, _tokenIds, _amounts, _data);
    // }


    // function getOrders(
    //   bytes32 ticker, 
    //   Side side
    //   ) 
    //   external 
    //   view

    //   returns(uint[] memory, address[] memory, uint[] memory, bytes32[] memory, Side[] memory, uint[] memory) {
    //   Order[] storage orders = orderBook[ticker][uint(side)];
    //   uint[] memory ids = new uint[](orders.length);
    //   address[] memory traders = new address[](orders.length);
    //   uint[] memory prices = new uint[](orders.length);
    //   bytes32[] memory _ticker = new bytes32[](orders.length);
    //   Side[] memory ordersSide = new Side[](orders.length);
    //   uint[] memory amounts = new uint[](orders.length);
    //   for(uint i = 0; i < orders.length; i++) {
    //     ids[i] = orders[i].id;
    //     traders[i] = orders[i].trader;
    //     prices[i] = orders[i].price;
    //     _ticker[i] = orders[i].ticker;
    //     ordersSide[i] = orders[i].side;
    //     amounts[i] = orders[i].amount;
    //   }
    //   return (
    //       ids, 
    //       traders, 
    //       prices,
    //       _ticker, 
    //       ordersSide,
    //       amounts
    //       );
    // }
    // function getOrders(
    //   uint tokenId, 
    //   Side side
    //   ) 
    //   external 
    //   view
    //   tokenExist(tokenId)
    //   returns(uint[] memory, uint[] memory, uint[] memory, Side[] memory, uint[] memory, uint[] memory, uint[] memory) {
    // //   return orderBook[tokenId][uint(side)];
    // //   Order[] memory orders = orderBook[tokenId][uint(side)];
    //   Order[] storage orders = orderBook[tokenId][uint(side)];
    //   uint[] memory ids = new uint[](orders.length);
    // //   address[] memory traders = new address[](orders.length);
    //   uint[] memory prices = new uint[](orders.length);
    //   uint[] memory _tokenId = new uint[](orders.length);
    //   Side[] memory ordersSide = new Side[](orders.length);
    //   uint[] memory amounts = new uint[](orders.length);
    //   uint[] memory ordersfilled = new uint[](orders.length);
    //   uint[] memory dates = new uint[](orders.length);
    //   for(uint i = 0; i < orders.length; i++) {
    //     ids[i] = orders[i].id;
    //     // traders[i] = orders[i].trader;
    //     prices[i] = orders[i].price;
    //     _tokenId[i] = orders[i].tokenId;
    //     ordersSide[i] = orders[i].side;
    //     amounts[i] = orders[i].amount;
    //     ordersfilled[i] = orders[i].filled;
    //     dates[i] = orders[i].date;
    //   }
    //   return (
    //       ids, 
    //     //   traders,
    //       prices,
    //       _tokenId, 
    //       ordersSide, 
    //       amounts,
    //       ordersfilled,
    //       dates
    //       );
    // }

    function getOrders(
      uint tokenId, 
      Side side) 
      external 
      view
      returns(Order[] memory) {
      return orderBook[tokenId][uint(side)];
    }

    // function getTokenIds() 
    //   external 
    //   view 
    //   returns(
    //     uint[] memory
    //     // , string[] memory
    //   ) {
    // //   Token[] memory _tokenIds = new Token[](tokenIdList.length);
    // //   uint[] memory _tokenIds = new uint[](tokenIdList.length + 1);
    //   uint[] memory _tokenIds = new uint[](tokenIdList.length);
    // //   string[] memory _tokenNames = new string[](tokenIdList.length);
    // //   uint j;
    // //   for (uint i = 1; i < tokenIdList.length + 1; i++) {
    //   for (uint i = 0; i < tokenIdList.length; i++) {
    //     // Token storage _token = tokenIds[i];
    //     //   ids[i] = _tokenIds[i].tokenId;
    //     _tokenIds[i] = tokenIds[tokenIdList[i]].tokenId;
    //     // _tokenNames[i] = tokenIds[i].name;
    //     // _tokenIds[i] = Token(
    //     //   tokenIds[tokenIdList[i]].tokenId,
    //     //   tokenIds[tokenIdList[i]].name
    //     // );
    //   }
    //   return (_tokenIds
    // //   , _tokenNames
    //   );
    // }

    function getTokens() 
      external 
      view 
      returns(Token[] memory) {                                    //memory is temporary place to store data
      Token[] memory _tokens = new Token[](tokenIdList.length);
      for (uint i = 0; i < tokenIdList.length; i++) {
        _tokens[i] = Token(
          tokenIds[tokenIdList[i]].tokenId
        );
      }
      return _tokens;
    }
    
    // function _addToken(
    //     // uint tokenId,
    //     string memory _name
    //     // uint _tier
    //     )
    //     // onlyAdmin()
    //     internal {
    //     tokenIdCount++;
    //     tokenIds[tokenIdCount] = Token(
    //         tokenIdCount, 
    //         _name
    //         // _tier
    //         );
    //     tokenIdList.push(tokenIdCount);
    // }

    function addToken(
        uint _tokenId
        )
        public
        onlyAdmin()
         {
        // tokenIdCount++;
        tokenIds[_tokenId] = Token(
            _tokenId 
            // _tier
            );
        tokenIdList.push(_tokenId);
		emit TokenAdded(_tokenId);
    }

    function cancelOrder(uint tokenId, uint _orderId, Side side) external {
        Order[] storage orders = orderBook[tokenId][uint(side)];
        uint i = 0; 
        while(i < orders.length && 
        orderCancelled[_orderId] == false
        ) {
        if(orders[i].trader == msg.sender && orders[i].id == _orderId){
        orderCancelled[orders[i].id] = true;
        
        if(orderCancelled[orders[i].id] == true ){
            for(uint j = i; j < orders.length - 1; j++ ) {
            orders[j] = orders[j + 1];
        }
        orders.pop();
        }    
        // emit Cancel        
        i = i.add(1);
        }
        if(side == Side.SELL) {                           //from enum. i declared the side in the enum (top of contract) but not sure if this is the same 'side' 
            traderBalances[tokenId][msg.sender] = traderBalances[tokenId][msg.sender].add(orderAmount[tokenId][_orderId]);
            orderAmount[tokenId][_orderId] = orderAmount[tokenId][_orderId].sub(orderAmount[tokenId][_orderId]);
        }
        if(side == Side.BUY) {
            etherBalance[msg.sender] = etherBalance[msg.sender].add(etherOnHold[msg.sender][_orderId]);
            etherOnHold[msg.sender][_orderId] = etherOnHold[msg.sender][_orderId].sub(etherOnHold[msg.sender][_orderId]);
        }
    }
    }
    function createLimitOrder(
        uint tokenId,
        uint amount,
        uint price,
        Side side)
        tokenExist(tokenId)
        membershipRequire(tokenId)
        external {
        if (orderBook[tokenId][uint(Side.BUY)].length > 0 && side == Side.SELL && price <= orderBook[tokenId][uint(Side.BUY)][0].price){
                createMarketOrder(tokenId, amount, side);
            }
        else if (orderBook[tokenId][uint(Side.SELL)].length > 0 && side == Side.BUY && price >= orderBook[tokenId][uint(Side.SELL)][0].price){
                createMarketOrder(tokenId, amount, side);
            }
        else {
        if(side == Side.SELL) {
            require(
                traderBalances[tokenId][msg.sender] >= amount, 
                'token balance too low'
            );
            orderAmount[tokenId][nextOrderId] = orderAmount[tokenId][nextOrderId].add(amount);
            traderBalances[tokenId][msg.sender] = traderBalances[tokenId][msg.sender].sub(orderAmount[tokenId][nextOrderId]);
        } else {
            require(
                etherBalance[msg.sender] >= amount.mul(price),
                'ETHER balance too low'
            );
            etherOnHold[msg.sender][nextOrderId] = etherOnHold[msg.sender][nextOrderId].add(amount.mul(price));
            etherBalance[msg.sender] = etherBalance[msg.sender].sub(etherOnHold[msg.sender][nextOrderId]);
        }
        Order[] storage orders = orderBook[tokenId][uint(side)];
        orders.push(Order(
            nextOrderId,
            msg.sender,
            side,
            tokenId,
            amount,
            0,
            price,
            now 
        ));
        
        uint i = orders.length > 0 ? orders.length - 1 : 0;
        while(i > 0) {
            if(side == Side.BUY && orders[i - 1].price > orders[i].price) {
                break;   
            }
            if(side == Side.SELL && orders[i - 1].price < orders[i].price) {
                break;   
            }
            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;
            i--;
        }
        nextOrderId++;
        }
    }
    
    function createMarketOrder(
        uint tokenId,
        uint amount,
        Side side)
        tokenExist(tokenId)
        membershipRequire(tokenId)        
        public {
        if(side == Side.SELL) {
            require(
                traderBalances[tokenId][msg.sender] >= amount, 
                'token balance too low'
            );
        }
        Order[] storage orders = orderBook[tokenId][uint(side == Side.BUY ? Side.SELL : Side.BUY)];
        uint i;
        uint remaining = amount;
        
        while(i < orders.length && remaining > 0) {
            uint available = orders[i].amount.sub(orders[i].filled);
            uint matched = (remaining > available) ? available : remaining;
            remaining = remaining.sub(matched);
            orders[i].filled = orders[i].filled.add(matched);
            emit NewTrade(
                nextTradeId,
                orders[i].id,
                tokenId,
                orders[i].trader,
                msg.sender,
                matched,
                orders[i].price,
                now
            );
            uint256 _feeAmount = matched.mul(orders[i].price).mul(feePercent).div(100);
            if(side == Side.SELL) {
                traderBalances[tokenId][msg.sender] = traderBalances[tokenId][msg.sender].sub(matched);
                etherBalance[msg.sender] = etherBalance[msg.sender].add(matched.mul(orders[i].price).sub(_feeAmount));
                etherBalance[feeAccount] = etherBalance[feeAccount].add(_feeAmount);
                traderBalances[tokenId][orders[i].trader] = traderBalances[tokenId][orders[i].trader].add(matched);
                etherOnHold[orders[i].trader][orders[i].id] = etherOnHold[orders[i].trader][orders[i].id].sub(matched.mul(orders[i].price));
            }
            if(side == Side.BUY) {
                require(
                    etherBalance[msg.sender] >= matched.mul(orders[i].price),
                    'ETHER balance too low'
                );
                traderBalances[tokenId][msg.sender] = traderBalances[tokenId][msg.sender].add(matched);
                etherBalance[msg.sender] = etherBalance[msg.sender].sub(matched.mul(orders[i].price).add(_feeAmount));
                etherBalance[feeAccount] = etherBalance[feeAccount].add(_feeAmount);
                etherBalance[orders[i].trader] = etherBalance[orders[i].trader].add(matched.mul(orders[i].price));
                orderAmount[tokenId][orders[i].id] = orderAmount[tokenId][orders[i].id].sub(matched);
            }
            nextTradeId++;
            i++;
        }
        
        i = 0;
        while(i < orders.length && orders[i].filled == orders[i].amount) {
            for(uint j = i; j < orders.length - 1; j++ ) {
                orders[j] = orders[j + 1];
            }
            orders.pop();
            i++;
        }
    }


    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }    
    // function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4){
    //     return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
        
    // }
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
  
    modifier tokenExist(uint tokenId) {                   //this is a way to check for safety
        require(
            tokenId != 0 && tokenId <= tokenIdList.length,
            'this token does not exist'
        );
        _;
    }
    modifier membershipRequire(uint tokenId) {
        if(traderBalances[1][msg.sender] < 1){
        require(tokenId == 1, 'Can only trade membership token. Please make sure membership balance is at lease 1');
        }
        _;
    }
}

