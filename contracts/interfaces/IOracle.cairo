# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IOracle:
    func get_value(key : felt) -> (value : Uint256, last_updated_timestamp : felt):
    end
end
