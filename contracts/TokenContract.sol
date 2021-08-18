pragma solidity 0.5.5;

import "../lib/ERC1155Mintable.sol";  
// import "../lib/ERC1155MixedFungibleMintable.sol";

contract TokenContract is ERC1155Mintable {                 //when writing a contract it will be ranned across all nodes on network
         address public governance;                         // by governance thihs should mean the person that created the contract this line should be designed as to whom will be the minter. a var has been created                               
         mapping(address => bool) public minters;           // minter boolean creating multiple minters?
                 constructor() public {                     //by constructor this means this will be the code to be executed first when contract deploys
                               governance = msg.sender;     //this code will b initially deployed becuase it is insidd the constructor func. msg.sender can mint as many tokens as they want. msg.sender refers to the person that created this contract.  
                               }
                        //made create() internal instead of external ERC1155Mintable
                        // function create(uint256 _initialSupply, string memory _uri)  
                        
                        // // onlyMinter() 
                        // // onlyGovernance()
                        // public
                        // // returns(uint256 _id) 
                        // {
                        //     require(msg.sender == governance || minters[msg.sender], "!governance && !minter");
                        //     _create(_initialSupply, _uri);
                        // }
        function create(uint256 _initialSupply, string memory _uri)  
                 // onlyMinter() 
                 // onlyGovernance()
                 public                                      //??
                 // returns(uint256 _id) 
    {
        require(msg.sender == governance || minters[msg.sender], "!governance && !minter");  //require() is a convenience func. it can be used to check for conditions and throw an exception if the condition is not met. 
        _create(_initialSupply, _uri);
    }   
    function setGovernance(address _governance) public onlyGovernance returns(address){
        governance = _governance;
    }
    
    function addMinter(address _minter) public onlyGovernance() {                           //since its public, anyone on the blockchain can execute these funcs
       
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public onlyGovernance() {
        
        minters[_minter] = false;
    }
    
    // modifier onlyMinter() {
    //     require(minters[msg.sender] == true || msg.sender == governance, 'must be minter or governance');
    //     _;
    // }
     modifier onlyGovernance() {
        require(msg.sender == governance, 'only governance');
        _;
     }

}