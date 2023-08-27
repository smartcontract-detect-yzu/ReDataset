// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.5.17;



import "ErrorReporter.sol";

import "ComptrollerInterfaces.sol";



/**

 * @title ComptrollerCore

 * @dev Storage for the comptroller is at this address, while execution is delegated to the `comptrollerImplementation`.

 * PTokens should reference this contract as their comptroller.

 */

contract Unitroller is UnitrollerInterface {

    constructor() public {

        admin = msg.sender;

    }



    /// @notice Indicator that this is a Comptroller contract (for inspection)

    function isComptroller() external pure returns (bool) {

        return true;

    }



    /*** Admin Functions ***/

    function _setPendingImplementations(address newPendingPart1Implementation, address newPendingPart2Implementation) external {

        require(newPendingPart1Implementation != address(0) && newPendingPart2Implementation != address(0), "invalid argument");

        require(msg.sender == admin, "only admin");



        {

            ComptrollerNoNFTInterface part1 = ComptrollerNoNFTInterface(newPendingPart1Implementation);

            ComptrollerNoNFTInterface part2 = ComptrollerNoNFTInterface(newPendingPart2Implementation);

            require(part1.isComptrollerPart1() && !part1.isComptroller());

            require(part2.isComptrollerPart2() && !part2.isComptroller());

        }



        _setPendingImplementationsInternal(newPendingPart1Implementation, newPendingPart2Implementation);

    }



    function _setPendingImplementationsInternal(address newPendingPart1Implementation, address newPendingPart2Implementation) internal {

        emit NewPendingImplementations(pendingComptrollerPart1Implementation, newPendingPart1Implementation, pendingComptrollerPart2Implementation, newPendingPart2Implementation);



        pendingComptrollerPart1Implementation = newPendingPart1Implementation;

        pendingComptrollerPart2Implementation = newPendingPart2Implementation;

    }



    /**

    * @notice Accepts new implementation of comptroller. msg.sender must be pendingPart1Implementation or pendingPart2Implementation

    * @dev Admin function for new implementation to accept it's role as implementation

    */

    function _acceptImplementation() external {

        if (msg.sender == pendingComptrollerPart1Implementation) {

            emit NewImplementation(comptrollerPart1Implementation, pendingComptrollerPart1Implementation, comptrollerPart2Implementation, comptrollerPart2Implementation);

            comptrollerPart1Implementation = pendingComptrollerPart1Implementation;



            _setPendingImplementationsInternal(address(0), pendingComptrollerPart2Implementation);



        } else if (msg.sender == pendingComptrollerPart2Implementation) {

            emit NewImplementation(comptrollerPart1Implementation, comptrollerPart1Implementation, comptrollerPart2Implementation, pendingComptrollerPart2Implementation);

            comptrollerPart2Implementation = pendingComptrollerPart2Implementation;



            _setPendingImplementationsInternal(pendingComptrollerPart1Implementation, address(0));



        } else {

            require(false, "only pending implementation");

        }

    }



    /**

      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.

      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.

      * @param newPendingAdmin New pending admin.

      */

    function _setPendingAdmin(address newPendingAdmin) external {

        require(msg.sender == admin, "only admin");



        emit NewPendingAdmin(pendingAdmin, newPendingAdmin);

        pendingAdmin = newPendingAdmin;

    }



    /**

      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin

      * @dev Admin function for pending admin to accept role and update admin

      */

    function _acceptAdmin() external {

        require(msg.sender == pendingAdmin, "only pending admin");



        emit NewAdmin(admin, pendingAdmin);

        emit NewPendingAdmin(pendingAdmin, address(0));

        admin = pendingAdmin;

        pendingAdmin = address(0);

    }



    /// @dev Delegates execution to an implementation contract. It returns to the external caller whatever the implementation returns or forwards reverts.

    function() external payable {

        // delegate all other functions to current implementation. ComptrollerPart1 fallback function delegates to ComptrollerPart2

        (bool success,) = comptrollerPart1Implementation.delegatecall(msg.data);



        assembly {

            let free_mem_ptr := mload(0x40)

            returndatacopy(free_mem_ptr, 0, returndatasize)



            switch success

            case 0 {revert(free_mem_ptr, returndatasize)}

            default {return (free_mem_ptr, returndatasize)}

        }

    }

}

