//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface ISanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}
