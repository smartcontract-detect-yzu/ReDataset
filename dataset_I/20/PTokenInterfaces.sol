// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.5.17;



import "ComptrollerInterfaces.sol";

import "InterestRateModelInterface.sol";

import "EIP20NonStandardInterface.sol";



contract PTokenStorage {

    /// @dev Guard variable for reentrancy checks

    bool internal _notEntered;



    /// @notice EIP-20 token name for this token

    string public name;



    /// @notice EIP-20 token symbol for this token

    string public symbol;



    /// @notice EIP-20 token decimals for this token

    uint8 public decimals;



    /// @notice Maximum borrow rate that can ever be applied (.0005% / block)

    uint internal constant borrowRateMaxMantissa = 0.0005e16;



    /// @notice Maximum fraction of interest that can be set aside for reserves

    uint internal constant reserveFactorMaxMantissa = 1e18;



    /// @notice Administrator for this contract

    address payable public admin;



    /// @notice Pending administrator for this contract

    address payable public pendingAdmin;



    /// @notice Contract which oversees inter-pToken operations

    ComptrollerNoNFTInterface public comptroller;



    /// @notice Model which tells what the current interest rate should be

    InterestRateModelInterface public interestRateModel;



    /// @notice Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)

    uint internal initialExchangeRateMantissa;



    /// @notice Fraction of interest currently set aside for reserves

    uint public reserveFactorMantissa;



    /// @notice Block number that interest was last accrued at

    uint public accrualBlockNumber;



    /// @notice Accumulator of the total earned interest rate since the opening of the market

    uint public borrowIndex;



    /// @notice Total amount of outstanding borrows of the underlying in this market

    uint public totalBorrows;



    /// @notice Total amount of reserves of the underlying held in this market

    uint public totalReserves;



    /// @notice Total number of tokens in circulation

    uint public totalSupply;



    /// @notice Official record of token balances for each account

    mapping (address => uint) internal accountTokens;



    /// @notice Approved token transfer amounts on behalf of others

    mapping (address => mapping (address => uint)) internal transferAllowances;



    /**

     * @notice Container for borrow balance information

     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action

     * @member interestIndex Global borrowIndex as of the most recent balance-changing action

     */

    struct BorrowSnapshot {

        uint principal;

        uint interestIndex;

    }



    /// @notice Mapping of account addresses to outstanding borrow balances

    mapping(address => BorrowSnapshot) internal accountBorrows;



    /// @notice Share of seized collateral that is added to reserves

    uint public protocolSeizeShareMantissa = 5e16; // 5%;  0% == disabled



    /// @notice First MINIMUM_LIQUIDITY minted pTokens gets locked on address(0) to prevent totalSupply being 0

    uint public constant MINIMUM_LIQUIDITY = 10000;

}



contract PTokenInterface is PTokenStorage {

    /// @notice Indicator that this is a PToken contract (for inspection)

    bool public constant isPToken = true;



    /*** Market Events ***/



    /// @notice Event emitted when interest is accrued

    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);



    /// @notice Event emitted when tokens are minted

    event Mint(address indexed minter, uint mintAmount, uint mintTokens);



    /// @notice Event emitted when tokens are redeemed

    event Redeem(address indexed redeemer, uint redeemAmount, uint redeemTokens);



    /// @notice Event emitted when underlying is borrowed

    event Borrow(address indexed borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);



    /// @notice Event emitted when a borrow is repaid

    event RepayBorrow(address indexed payer, address indexed borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);



    /// @notice Event emitted when a borrow is liquidated

    event LiquidateBorrow(address indexed liquidator, address indexed borrower, uint repayAmount, address indexed pTokenCollateral, uint seizeTokens);



    /// @notice EIP20 Transfer event

    event Transfer(address indexed from, address indexed to, uint amount);



    /// @notice EIP20 Approval event

    event Approval(address indexed owner, address indexed spender, uint amount);



    /// @notice Failure event

    event Failure(uint error, uint info, uint detail);



    /*** Admin Events ***/



    /// @notice Event emitted when pendingAdmin is changed

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);



    /// @notice Event emitted when pendingAdmin is accepted, which means admin is updated

    event NewAdmin(address oldAdmin, address newAdmin);



    /// @notice Event emitted when comptroller is changed

    event NewComptroller(address oldComptroller, address newComptroller);



    /// @notice Event emitted when interestRateModel is changed

    event NewMarketInterestRateModel(InterestRateModelInterface oldInterestRateModel, InterestRateModelInterface newInterestRateModel);



    /// @notice Event emitted when the reserve factor is changed

    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);



    /// @notice Event emitted when the reserves are added

    event ReservesAdded(address indexed benefactor, uint addAmount, uint newTotalReserves);



    /// @notice Event emitted when the reserves are reduced

    event ReservesReduced(address indexed admin, uint reduceAmount, uint newTotalReserves);



    /// @notice Event emitted when protocolSeizeShareMantissa is changed

    event NewProtocolSeizeShareMantissa(uint oldProtocolSeizeShareMantissa, uint newProtocolSeizeShareMantissa);



    /*** User Interface ***/



    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function balanceOfUnderlyingStored(address owner) external view returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint);

    function borrowRatePerBlock() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) public view returns (uint);

    function exchangeRateCurrent() public returns (uint);

    function exchangeRateStored() public view returns (uint);

    function getCash() external view returns (uint);

    function getRealBorrowIndex() external view returns (uint);

    function accrueInterest() public;

    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);



    /*** Admin Functions ***/



    function _setPendingAdmin(address payable newPendingAdmin) external;

    function _acceptAdmin() external;

    function _setComptroller(address newComptroller) public;

    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);

    function _reduceReserves(uint reduceAmount) external returns (uint);

    function _setInterestRateModel(InterestRateModelInterface newInterestRateModel) public returns (uint);

    function _setProtocolSeizeShareMantissa(uint newProtocolSeizeShareMantissa) external;

}



contract PErc20Storage {

    /// @notice Underlying asset for this PToken

    address public underlying;

}



contract PErc20Interface is PErc20Storage, PTokenInterface {

    /*** User Interface ***/



    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function liquidateBorrow(address borrower, uint repayAmount, PTokenInterface pTokenCollateral) external returns (uint);

    function sweepToken(EIP20NonStandardInterface token) external;



    /*** Admin Functions ***/



    function _addReserves(uint addAmount) external returns (uint);

}



contract PTokenDelegationStorage {

    /// @notice Implementation address for this contract

    address public implementation;

}



contract PTokenDelegatorInterface is PTokenDelegationStorage {

    /// @notice Emitted when implementation is changed

    event NewImplementation(address oldImplementation, address newImplementation);



    /**

     * @notice Called by the admin to update the implementation of the delegator

     * @param implementation_ The address of the new implementation for delegation

     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation

     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation

     */

    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;

}



contract PTokenDelegateInterface is PTokenInterface, PTokenDelegationStorage {

    /**

     * @notice Called by the delegator on a delegate to initialize it for duty

     * @dev Should revert if any issues arise which make it unfit for delegation

     * @param data The encoded bytes data for any initialization

     */

    function _becomeImplementation(bytes calldata data) external;



    /// @notice Called by the delegator on a delegate to forfeit its responsibility

    function _resignImplementation() external;

}

