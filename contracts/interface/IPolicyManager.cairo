# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPolicyManager:
    func set_maxmin_amount(vault: felt, max : Uint256, min:Uint256):
    end
    func get_maxmin_amount(vault: felt) -> (max : Uint256, min: Uint256):
    end
end