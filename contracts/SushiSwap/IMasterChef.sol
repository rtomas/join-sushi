// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function poolLength() external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}
