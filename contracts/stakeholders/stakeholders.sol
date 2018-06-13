pragma solidity ^0.4.24;

interface Callback {
    function createStakeHolder(uint _stake, address _principle) external returns (address);
}

contract StakeHolder {
    uint stake = 0;
    address[] beneficiary;
    address[] beneficiary_stake;
    address public principle;
    address benefactor;
    Callback cb;
    bool is_trusted = true;
    
    constructor(uint _stake, address _principle, Callback _cb) public{
        require((_stake < 100) && (_stake > 0));
        benefactor = msg.sender;
        principle = _principle;
        cb = _cb;
    }
    
    function get_principle() public view returns (address){
        return principle;
    }

    function is_benefactor() private view returns (bool){
        address _beneficiary = msg.sender;
        bool _is_beneficiary = false;
        for (uint i = 0; i < beneficiary.length; i++){
            _is_beneficiary = _is_beneficiary || (_beneficiary == beneficiary[i]);
        }
        return _is_beneficiary;
    }
    
    modifier onlyBenefactor(){
        require(msg.sender == benefactor);
        _;
    }
    modifier onlyStakeHolder(){
        require(msg.sender == address(this));
        _;
    }
    modifier onlyBeneficiary(){
        require(is_benefactor());
        _;
    }
    
    modifier hasGasValue(){
        require((msg.value <= 0)&&(gasleft() <= 0));
        _;
    }
    function createBeneficiary(uint _stake, address _principle) public onlyStakeHolder payable returns (address){
        require(_stake > 0 && _stake < 100);
        StakeHolder _beneficiary = StakeHolder(cb.createStakeHolder(_stake, _principle));
        beneficiary.push(_beneficiary);
        return _beneficiary;
    }
    
    function receiveRefund() public onlyBeneficiary payable {
        principle.transfer(msg.value);
    }
    
    function receiveFunds() public onlyBenefactor payable hasGasValue {
        for(uint i = 0; i < beneficiary.length; i++){
            StakeHolder stakeholder = StakeHolder(beneficiary[i]);
            uint beneficiary_payout = msg.value / stake;
            stakeholder.receiveFunds.value(beneficiary_payout);
            stakeholder.get_principle().transfer(beneficiary_payout);
        }
    }
    function () payable external {
        benefactor.transfer(msg.value);
    }
}


contract CallbackImplementation is Callback {
    function createStakeHolder(uint _stake, address _principle) public returns (address) {
        require(_stake > 0 && _stake < 100);
        StakeHolder _beneficiary = new StakeHolder(_stake, _principle, this);
        return _beneficiary;
    }
}

contract Aqueduct {
    Callback cb;
    StakeHolder[] root;
    modifier onlyTrustee(){
        require(msg.sender == root[root.length - 1].get_principle());
        _;
    }
    
    function create(address _principle) public returns (address){
        cb = new CallbackImplementation();
        root.push(new StakeHolder(1,_principle,cb));
        return address(this);
    }
    //delete returns
    function invest(uint amount) public payable returns (address){
        StakeHolder target = root[root.length - 1];
        target.receiveFunds.value(amount);
        return address(target);
    }
    function reset() public onlyTrustee returns (address){
        StakeHolder next = new StakeHolder(1,root[root.length - 1].get_principle(),cb);
        root.push(next);
        return address(next);
    }
}