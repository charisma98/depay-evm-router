// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5 <0.8.0;

interface IDePayPaymentProcessorV1 {

  function pay(
    address[] calldata path,
    uint amountIn,
    uint amountOut,
    address payable receiver
  ) external payable returns(bool);

  function withdraw(
    address tokenAddress, 
    uint amount
  ) external returns(bool);
  
}
