// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    // 添加事件以便跟踪
    event Deposit(address indexed depositor, uint256 amount);
    event WithdrawRequest(address indexed user, uint256 amount);
    event WithdrawComplete(address indexed user, uint256 amount);
    
    // 存款函数
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // 有漏洞的提款函数
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        
        require(amount > 0, "Insufficient balance");
        emit WithdrawRequest(msg.sender, amount);
        
        // 危险：在更新状态变量前进行外部调用
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // 状态变量在外部调用后才更新
        balances[msg.sender] = 0;
        emit WithdrawComplete(msg.sender, amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getUserBalance(address user) public view returns (uint256) {
        return balances[user];
    }
}