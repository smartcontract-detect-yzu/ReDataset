// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.5.17;



import "Api3Interfaces.sol";



contract Api3DapiServerMock /* is Api3IDapiServer */ {

    int224 valueMock;

    uint32 timestampMock;



    constructor(int224 _valueMock, uint32 _timestampMock) public {

        valueMock = _valueMock;

        timestampMock = _timestampMock;

    }



    function readDataFeedWithDapiName(bytes32 /* dapiName */) external view returns (int224 value, uint32 timestamp) {

        return (valueMock, timestampMock);

    }

}

