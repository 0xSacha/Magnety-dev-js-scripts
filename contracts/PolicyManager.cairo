# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
struct MaxMin:
    member max: Uint256
    member min: Uint256
end
# Define a storage variable.
@storage_var
func maxmin_amount(vault: felt) -> (res: MaxMin):
end

# TODO - should give ACCESS only to XXX
# set the balance by the given amount.
@external
func set_maxmin_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        vault: felt, max : Uint256, min:Uint256):
    
    maxmin_amount.write(vault, MaxMin(max, min))
    return ()
end

# TODO - should give ACCESS only to XXX
# Returns the current max_amount
@view
func get_maxmin_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault: felt) -> (
        max : Uint256, min: Uint256):
    let (res) = maxmin_amount.read(vault)
    return (max=res.max, min=res.min)
end


# Define a storage variable.
@storage_var
func min_amount() -> (res : felt):
end

# set the balance by the given amount.
@external
func set_min_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : felt):
    min_amount.write(amount)
    return ()
end

# Returns the current min_amount
@view
func get_min_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        res : felt):
    let (res) = min_amount.read()
    return (res)
end


