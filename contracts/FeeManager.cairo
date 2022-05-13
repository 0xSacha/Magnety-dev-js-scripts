# Declare this file as a StarkNet contract.
%lang starknet
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interface.IFeeManager import FeeConfig

@storage_var
func fee_config(vault : felt, key : felt) -> (res : felt):
end

@storage_var
func vaultFactory() -> (vaultFactoryAddress : felt):
end


# Define a storage variable.
@storage_var
func claimed_timestamp(vault: felt) -> (res : felt):
end

# set the balance by the given amount.
@external
func set_claimed_timestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        vault: felt, timestamp : felt):
    claimed_timestamp .write(vault, timestamp)
    return ()
end

# Returns the current created_timestam
@view
func get_claimed_timestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault: felt) -> (
        timestamp : felt):
    let (res) = claimed_timestamp .read(vault)
    return (timestamp=res)
end


# Define a storage variable.
@storage_var
func treasury() -> (res : felt):
end

# TODO - should give ACCESS only to XXX
# set the balance by the given amount.
@external
func set_treasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : felt):
    treasury.write(amount)
    return ()
end

# Returns the current treasury
@view
func get_treasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        res : felt):
    let (res) = treasury.read()
    return (res)
end


# Define a storage variable.
@storage_var
func stacking_vault() -> (res : felt):
end

# TODO - should give ACCESS only to XXX
# set the balance by the given amount.
@external
func set_stacking_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : felt):
    stacking_vault.write(amount)
    return ()
end

# Returns the current stacking_vault
@view
func get_stacking_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        res : felt):
    let (res) = stacking_vault.read()
    return (res)
end




#
# Modifiers
#

func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    # let (vaultFactory_) = vaultFactory.read()
    # let (caller_) = get_caller_address()
    # with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
    #     assert (vaultFactory_ - caller_) = 0
    # end
    return ()
end


#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        # _vaultFactory: felt,
    ):
    # vaultFactory.write(_vaultFactory)
    return ()
end


@external
func set_entrance_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.ENTRANCE_FEE, fee)
    return ()
end

@external
func set_entrance_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.ENTRANCE_FEE_ENABLED, is_enabled)
    return ()
end

@view
func get_entrance_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = fee_config.read(vault, FeeConfig.ENTRANCE_FEE)
    return (fee=fee)
end

@view
func is_entrance_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = fee_config.read(vault, FeeConfig.ENTRANCE_FEE_ENABLED)
    return (is_enabled=is_enabled)
end

@external
func set_exit_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.EXIT_FEE, fee)
    return ()
end

@external
func set_exit_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.EXIT_FEE_ENABLED, is_enabled)
    return ()
end

@view
func get_exit_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = fee_config.read(vault, FeeConfig.EXIT_FEE)
    return (fee=fee)
end

@view
func is_exit_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = fee_config.read(vault, FeeConfig.EXIT_FEE_ENABLED)
    return (is_enabled=is_enabled)
end

@external
func set_performance_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.PERFORMANCE_FEE, fee)
    return ()
end

@external
func set_performance_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.PERFORMANCE_FEE_ENABLED, is_enabled)
    return ()
end

@view
func get_performance_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = fee_config.read(vault, FeeConfig.PERFORMANCE_FEE)
    return (fee=fee)
end

@view
func is_performance_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = fee_config.read(vault, FeeConfig.PERFORMANCE_FEE_ENABLED)
    return (is_enabled=is_enabled)
end

@external
func set_management_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.MANAGEMENT_FEE, fee)
    return ()
end

@external
func set_management_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    fee_config.write(vault, FeeConfig.MANAGEMENT_FEE_ENABLED, is_enabled)
    return ()
end

@view
func get_management_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = fee_config.read(vault, FeeConfig.MANAGEMENT_FEE)
    return (fee=fee)
end

@view
func is_management_fee_enabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = fee_config.read(vault, FeeConfig.MANAGEMENT_FEE_ENABLED)
    return (is_enabled=is_enabled)
end


# TODO - should give ACCESS only to XXX
@external
func set_fee_config{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, key : felt, value : felt
):
    onlyVaultFactory()
    fee_config.write(vault, key, value)
    return ()
end

@view
func get_fee_config{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, key : felt
) -> (value : felt):
    let (value) = fee_config.read(vault, key)
    return (value=value)
end
