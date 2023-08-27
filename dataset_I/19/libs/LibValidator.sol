// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../utils/fromOZ/ECDSA.sol";

library LibValidator {

 using ECDSA for bytes32;

 string public constant DOMAIN_NAME = "Orion Exchange";
 string public constant DOMAIN_VERSION = "1";
 uint256 public constant CHAIN_ID = 56;
 bytes32 public constant DOMAIN_SALT = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a557;

 bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
 abi.encodePacked(
 "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)"
 )
 );
 bytes32 public constant ORDER_TYPEHASH = keccak256(
 abi.encodePacked(
 "Order(address senderAddress,address matcherAddress,address baseAsset,address quoteAsset,address matcherFeeAsset,uint64 amount,uint64 price,uint64 matcherFee,uint64 nonce,uint64 expiration,uint8 buySide)"
 )
 );

 bytes32 public constant DOMAIN_SEPARATOR = keccak256(
 abi.encode(
 EIP712_DOMAIN_TYPEHASH,
 keccak256(bytes(DOMAIN_NAME)),
 keccak256(bytes(DOMAIN_VERSION)),
 CHAIN_ID,
 DOMAIN_SALT
 )
 );

 struct Order {
 address senderAddress;
 address matcherAddress;
 address baseAsset;
 address quoteAsset;
 address matcherFeeAsset;
 uint64 amount;
 uint64 price;
 uint64 matcherFee;
 uint64 nonce;
 uint64 expiration;
 uint8 buySide; // buy or sell
 bool isPersonalSign;
 bytes signature;
 }

 /**
 * @dev validate order signature
 */
 function validateV3(Order memory order) public pure returns (bool) {
 bytes32 digest = keccak256(
 abi.encodePacked(
 "\x19\x01",
 DOMAIN_SEPARATOR,
 getTypeValueHash(order)
 )
 );

 return digest.recover(order.signature) == order.senderAddress;
 }

 /**
 * @return hash order
 */
 function getTypeValueHash(Order memory _order)
 internal
 pure
 returns (bytes32)
 {
 return
 keccak256(
 abi.encode(
 ORDER_TYPEHASH,
 _order.senderAddress,
 _order.matcherAddress,
 _order.baseAsset,
 _order.quoteAsset,
 _order.matcherFeeAsset,
 _order.amount,
 _order.price,
 _order.matcherFee,
 _order.nonce,
 _order.expiration,
 _order.buySide
 )
 );
 }

 /**
 * @dev basic checks of matching orders against each other
 */
 function checkOrdersInfo(
 Order memory buyOrder,
 Order memory sellOrder,
 address sender,
 uint256 filledAmount,
 uint256 filledPrice,
 uint256 currentTime,
 address allowedMatcher
 ) public pure returns (bool success) {
 buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
 sellOrder.isPersonalSign ? require(validatePersonal(sellOrder), "E2SP") : require(validateV3(sellOrder), "E2S");

 // Same matcher address
 require(
 buyOrder.matcherAddress == sender &&
 sellOrder.matcherAddress == sender,
 "E3M"
 );

 if(allowedMatcher != address(0)) {
 require(buyOrder.matcherAddress == allowedMatcher, "E3M2");
 }


 // Check matching assets
 require(
 buyOrder.baseAsset == sellOrder.baseAsset &&
 buyOrder.quoteAsset == sellOrder.quoteAsset,
 "E3As"
 );

 // Check order amounts
 require(filledAmount <= buyOrder.amount, "E3AmB");
 require(filledAmount <= sellOrder.amount, "E3AmS");

 // Check Price values
 require(filledPrice <= buyOrder.price, "E3");
 require(filledPrice >= sellOrder.price, "E3");

 // Check Expiration Time. Convert to seconds first
 require(buyOrder.expiration/1000 >= currentTime, "E4B");
 require(sellOrder.expiration/1000 >= currentTime, "E4S");

 require( buyOrder.buySide==1 && sellOrder.buySide==0, "E3D");
 success = true;
 }

 function getEthSignedOrderHash(Order memory _order) public pure returns (bytes32) {
 return
 keccak256(
 abi.encodePacked(
 "order",
 _order.senderAddress,
 _order.matcherAddress,
 _order.baseAsset,
 _order.quoteAsset,
 _order.matcherFeeAsset,
 _order.amount,
 _order.price,
 _order.matcherFee,
 _order.nonce,
 _order.expiration,
 _order.buySide
 )
 ).toEthSignedMessageHash();
 }

 function validatePersonal(Order memory order) public pure returns (bool) {

 bytes32 digest = getEthSignedOrderHash(order);
 return digest.recover(order.signature) == order.senderAddress;
 }

 function checkOrderSingleMatch(
 Order memory buyOrder,
 address sender,
 address allowedMatcher,
 uint112 filledAmount,
 uint256 currentTime,
 address asset_spend,
 address asset_receive
 ) internal pure {
 buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
 require(buyOrder.matcherAddress == sender && buyOrder.matcherAddress == allowedMatcher, "E3M2");
 if(buyOrder.buySide==1){
 require(
 buyOrder.baseAsset == asset_receive &&
 buyOrder.quoteAsset == asset_spend,
 "E3As"
 );
 }else{
 require(
 buyOrder.quoteAsset == asset_receive &&
 buyOrder.baseAsset == asset_spend,
 "E3As"
 );
 }
 require(filledAmount <= buyOrder.amount, "E3AmB");
 require(buyOrder.expiration/1000 >= currentTime, "E4B");
 }
}
