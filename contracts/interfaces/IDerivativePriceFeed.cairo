# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@contract_interface
namespace IDerivativePriceFeed:
    func calcUnderlyingValues(_derivative: felt, _amount: Uint256):
    end
end
