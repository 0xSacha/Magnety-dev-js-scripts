# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct FundDeployerEvents:
    member Create_Vault : felt
    member REMOVE_VAULT : felt
end

#
# Events
#

# createVault event
@event
func CreateVault(event_tp : felt, owner : felt):
end

@event
func RemoveVault(event_tp : felt):
end

#
# External
#

@external
func create_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    # emit event
    CreateVault.emit(FundDeployerEvents.Create_Vault, owner)

    return ()
end

@external
func remove_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # emit event
    RemoveVault.emit(FundDeployerEvents.REMOVE_VAULT)

    return ()
end
