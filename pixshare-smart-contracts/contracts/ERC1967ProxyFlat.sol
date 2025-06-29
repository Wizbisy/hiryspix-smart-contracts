// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ----------- Proxy.sol (OpenZeppelin) ----------- */
abstract contract Proxy {
    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _implementation() internal view virtual returns (address);

    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    fallback () external payable virtual { _fallback(); }
    receive () external payable virtual { _fallback(); }
}

/* ----------- ERC1967Utils.sol (OpenZeppelin) ----------- */
library ERC1967Utils {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function getImplementation() internal view returns (address impl) {
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success, ) = newImplementation.delegatecall(data);
            require(success, "ERC1967Proxy: init call failed");
        }
    }

    function _setImplementation(address newImplementation) private {
        require(newImplementation.code.length > 0, "ERC1967: new impl is not a contract");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }
}

/* ----------- ERC1967Proxy.sol ----------- */
contract ERC1967Proxy is Proxy {
    constructor(address implementation, bytes memory _data) payable {
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
