# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le
from starkware.cairo.common.uint256 import uint256_mul, uint256_unsigned_div_rem
from starkware.cairo.common.memcpy import memcpy

from starkware.starknet.common.syscalls import get_tx_info, get_block_number, get_block_timestamp

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.interface.IOracle import IOracle
from contracts.interface.IPolicyManager import IPolicyManager
from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.find_element import find_element

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
)

# from starkware.cairo.common.uint256 import
from openzeppelin.security.safemath import uint256_checked_add, uint256_checked_sub_le

from contracts.interface.IVault import VaultAction, IVault

from contracts.interface.IExternalPosition import IExternalPosition

from contracts.interface.IFeeManager import FeeConfig, IFeeManager

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent

@storage_var
func vault_proxy_addr(vault : felt) -> (addr : felt):
end

# this has pontis address
@storage_var
func oracle_addr() -> (addr : felt):
end

@storage_var
func policy_mgr_addr() -> (addr : felt):
end

@storage_var
func fee_mgr_addr() -> (res : felt):
end

# Define a storage variable.
@storage_var
func deno_asset() -> (res : felt):
end

# set the balance by the given amount.
@external
func set_deno_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : felt
):
    deno_asset.write(amount)
    return ()
end

# Returns the current deno_asset
@view
func get_deno_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    let (res) = deno_asset.read()
    return (res)
end

# This add pair str as felt to the comptroller
# because I haven't found out the way to handle str as felt in cairo
# ex.  weth -> weth/usdt
# TODO - This should be removed after we find str_cat_by_felt approach in cairo.
@storage_var
func deno_pair(token : felt) -> (pair : felt):
end

# This returns deno_pair str
# ex. deno_pair_str("dai") -> "dai/usdt" : felt
@view
func get_deno_pair{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt
) -> (key : felt):
    alloc_locals
    let (name) = IERC20.name(token_address)

    let (pair) = deno_pair.read(name)
    return (key=pair)
end

@external
func add_deno_pair{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt, pair : felt
):
    deno_pair.write(token, pair)
    return ()
end

func __get_treasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    treasury : felt
):
    let (fee_mgr) = get_fee_mgr()
    let (treasury) = IFeeManager.get_treasury(fee_mgr)

    return (treasury=treasury)
end

func __get_stacking_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    stacking_vault : felt
):
    let (fee_mgr) = get_fee_mgr()
    let (stacking_vault) = IFeeManager.get_stacking_vault(fee_mgr)

    return (stacking_vault=stacking_vault)
end

# @view
# func assert_maxmin_range{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     vault : felt, amount : Uint256
# ) -> (le_max : felt, be_min : felt):
#     alloc_locals
#     let (policy_addr) = get_policy_mgr()
#     let (max, min) = IPolicyManager.get_maxmin_amount(policy_addr, vault)
#     with_attr error_message("amount is out of (min, max) range"):
#         let (le_max) = uint256_le(amount, max)
#         let (be_min) = uint256_le(min, amount)
#         return (le_max, be_min)

#         # let in_range = le_max * be_min
#         # assert in_range = 1
#     end
#     # return ()
# end

@external
func buy_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset : felt, amount : Uint256
):
    alloc_locals

    let (caller : felt) = get_caller_address()
    let (vault) = get_vault_proxy()

    let (fee, fee_treasury, fee_stacking_vault) = __get_fee(FeeConfig.EXIT_FEE, amount)

    # transfer fee to fee_treasury, stacking_vault
    let (treasury) = __get_treasury()
    let (stacking_vault) = __get_stacking_vault()

    IERC20.transferFrom(asset, caller, treasury, fee_treasury)
    IERC20.transferFrom(asset, caller, stacking_vault, fee_stacking_vault)

    # assert_maxmin_range(vault, amount)

    let (amount_without_fee) = uint256_sub(amount, fee)
    # send token to the vault
    IERC20.transferFrom(asset, caller, vault, amount_without_fee)
    # calculate GAV as usdt
    let (gav) = calc_gav()
    let (share_price) = calc_share_price()

    let (asset_value) = calc_asset_value(asset, amount_without_fee)
    # calculate share_amount = amount / share_price

    let (share_amount) = uint256_div(asset_value, share_price)

    # mint share
    __mint_share(caller, share_amount, share_price)

    return ()
end

# func transfer_fee(asset, amount, from)
func __mint_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    caller : felt, share_amount : Uint256, share_price : Uint256
):
    alloc_locals
    let (vault) = get_vault_proxy()

    # TODO - share_amount.low, share_price.low should be updated like uint256_to_felt(share_amount)
    let (call_data : felt*) = alloc()
    assert [call_data] = caller
    # TODO - vault_lib should change share_amount type into Uint256, which is felt atm
    assert [call_data + 1] = share_amount.low
    assert [call_data + 2] = share_price.low

    IVault.receiveValidatedVaultAction(vault, VaultAction.MintShares, 3, call_data)

    return ()
end

@external
func claim_management_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256
):
    # TODO - should check if the caller is vault manager
    alloc_locals

    let (fee_mgr) = get_fee_mgr()
    let (caller) = get_caller_address()
    let (vault) = get_vault_proxy()
    # let (claimed_amount) = felt_to_uint256(0)

    let (current_timestamp) = get_block_timestamp()
    let (claimed_timestamp) = IFeeManager.get_claimed_timestamp(fee_mgr, vault)

    let (gav) = calc_gav()
    let interval_stamps = current_timestamp - claimed_timestamp
    let STAMPS_PER_DAY = 86400
    let interval_days = interval_stamps / STAMPS_PER_DAY

    let (APY, _, _) = __get_fee(FeeConfig.MANAGEMENT_FEE, gav)
    let (interval_days_uint256) = felt_to_uint256(interval_days)
    let (year_uint256) = felt_to_uint256(360)
    let (temp_total, temp_total_high) = uint256_mul(APY, interval_days_uint256)
    # TODO - High value should be considered
    assert temp_total_high.high = 0
    let (claim_amount) = uint256_div(temp_total, year_uint256)

    let (asset) = get_deno_asset()
    __transfer_asset_to(asset, claim_amount, caller)

    return ()
end

@external
func sell_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256,
    share_amount : Uint256,
    assets_len : felt,
    assets : felt*,
    percents_len : felt,
    percents : felt*,
):
    alloc_locals

    let (caller) = get_caller_address()
    let (vault) = get_vault_proxy()
    # calc value of share
    let (share_value) = __share_value_of_amount(share_amount)
    # calc price of each asset in the list
    let (share_value) = __share_value_of_amount(share_amount)
    # calc value of each asset
    # calc amount of each asset
    # assert_maxmin_range(vault, share_value)

    assert assets_len = percents_len

    let len = assets_len

    # Todo - Should be Uint256*
    let (amounts : felt*) = alloc()
    calc_amount_of_each_asset(share_value, len, assets, percents, amounts)
    # transfer token of each amount to the caller
    __transfer_each_asset(caller, len, assets, amounts)

    # burn share
    __burn_share(token_id, share_amount)

    return ()
end

func calc_amount_of_each_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    total_value : Uint256, len : felt, assets : felt*, percents : felt*, amounts : felt*
):
    alloc_locals

    if len == 0:
        return ()
    end
    # asset_value = total_value * 100 / percents[0]
    let (percent) = felt_to_uint256(percents[0])

    let (asset_value) = uint256_percent(total_value, percent)

    let (asset_price) = get_asset_price(assets[0])
    # asset_amount = asest_value / asset_price
    # Todo - Consider the update of div operation
    let (asset_amount) = uint256_div(asset_value, asset_price)

    # Todo - should be change if amounts is Uint256
    assert [amounts] = asset_amount.low
    # assert [amounts] = 1

    calc_amount_of_each_asset(
        total_value=total_value,
        len=len - 1,
        assets=assets + 1,
        percents=percents + 1,
        amounts=amounts + 1,
    )

    return ()
end

func __is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(x : felt) -> (
    res : felt
):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end

@view
func __get_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    key : felt, amount : Uint256
) -> (fee : Uint256, fee_treasury : Uint256, fee_stacking_vault : Uint256):
    alloc_locals
    let (key_enable : felt*) = alloc()
    let (vault) = get_vault_proxy()
    let (is_entrance) = __is_zero(key - FeeConfig.ENTRANCE_FEE)
    let (is_exit) = __is_zero(key - FeeConfig.EXIT_FEE)
    let (is_performance) = __is_zero(key - FeeConfig.PERFORMANCE_FEE)

    let entrance_fee = is_entrance * FeeConfig.ENTRANCE_FEE
    let exit_fee = is_exit * FeeConfig.EXIT_FEE
    let performance_fee = is_performance * FeeConfig.PERFORMANCE_FEE

    let config = entrance_fee + exit_fee + performance_fee

    let (fee_addr) = get_fee_mgr()
    let (percent) = IFeeManager.get_fee_config(fee_addr, vault, config)
    let (percent_uint256) = felt_to_uint256(percent)

    let (fee) = uint256_percent(amount, percent_uint256)
    # 20% to DAO treasury, 80% to stacking vault
    let (twenty) = felt_to_uint256(20)

    let (fee_treasury) = uint256_percent(fee, twenty)
    let (fee_stacking_vault) = uint256_sub(fee, fee_treasury)
    # let sub = key - FeeConfig.ENTRANCE_FEE
    return (fee=fee, fee_treasury=fee_treasury, fee_stacking_vault=fee_stacking_vault)
end

func __transfer_each_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    caller : felt, len : felt, assets : felt*, amounts : felt*
):
    alloc_locals
    if len == 0:
        return ()
    end

    let (vault) = get_vault_proxy()

    let (amount) = felt_to_uint256(amounts[0])
    let asset = assets[0]
    let (fee, fee_treasury, fee_stacking_vault) = __get_fee(FeeConfig.EXIT_FEE, amount)
    let (treasury) = __get_treasury()
    let (stacking_vault) = __get_stacking_vault()
    # transfer to the treasurey dao
    __transfer_asset_to(asset, fee_treasury, treasury)
    __transfer_asset_to(asset, fee_stacking_vault, stacking_vault)

    let (amount_without_fee) = uint256_sub(amount, fee)

    __transfer_asset_to(assets[0], amount_without_fee, caller)
    __transfer_each_asset(caller, len - 1, assets + 1, amounts + 1)

    return ()
end

func __transfer_asset_to{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset : felt, amount : Uint256, to : felt
):
    alloc_locals

    let (vault) = get_vault_proxy()
    # transfer asset to the user
    let (call_data : felt*) = alloc()
    assert [call_data] = asset
    # TODO - vault_lib should change share_amount type into Uint256, which is felt atm
    assert [call_data + 1] = to
    # Todo - should consider chaning amount to Uint256
    assert [call_data + 2] = amount.low

    assert amount.high = 0

    IVault.receiveValidatedVaultAction(vault, VaultAction.WithdrawAssetTo, 3, call_data)

    return ()
end

func __share_value_of_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256
) -> (value : Uint256):
    alloc_locals
    let (share_price) = calc_share_price()
    let (value_low, value_high) = uint256_mul(share_price, amount)

    assert value_high.low = 0
    assert value_high.high = 0

    # TODO - maybe we should consider value_high
    return (value=value_low)
end

func __burn_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, amount : Uint256
):
    alloc_locals

    let (vault) = get_vault_proxy()
    let (call_data : felt*) = alloc()
    assert [call_data] = token_id.low
    assert token_id.high = 0
    # TODO - vault_lib should change share_amount type into Uint256, which is felt atm
    assert [call_data + 1] = amount.low
    IVault.receiveValidatedVaultAction(vault, VaultAction.BurnShares, 2, call_data)

    return ()
end

@view
func calc_share_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    price : Uint256
):
    alloc_locals

    let (gav) = calc_gav()
    let (vault) = get_vault_proxy()
    let (total_supply) = IVault.getSharesTotalSupply(vault)

    let (price : Uint256) = uint256_div(gav, total_supply)
    return (price=price)
end

@view
func get_asset_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset : felt
) -> (price : Uint256):
    let (oracle) = get_oracle()
    let (deno_pair) = get_deno_pair(asset)
    let (price, _) = IOracle.get_value(oracle, deno_pair)

    return (price=price)
end

@view
func calc_asset_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset : felt, amount : Uint256
) -> (value : Uint256):
    let (price) = get_asset_price(asset)
    let (value_low, value_high) = uint256_mul(price, amount)

    assert value_high.low = 0
    assert value_high.high = 0

    return (value=value_low)
end

# calculate certain asset's value
# call this like calc_asset_value(usdt_address_as_felt)
@view
func calc_asset_value_in_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset : felt
) -> (value : Uint256):
    alloc_locals
    let (vault) = get_vault_proxy()
    let (balance) = IVault.getAssetBalance(vault, asset)
    let (value) = calc_asset_value(asset, balance)

    return (value=value)
end

# TODO - Should let the deno token be configurable since current one is usdt.
# calculate the entire value of assets that the vault has
@view
func calc_gav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    gav : Uint256
):
    alloc_locals
    let (vault) = get_vault_proxy()
    let (asset_len : felt, assets : felt*) = IVault.getTrackedAssets(vault)
    # get tracked asset ids
    let (gav) = __calc_gav(asset_len, assets)

    return (gav=gav)
end

# this is recursive function that calculates the sum of value of asset list in the vault
# this is called in calc_gav function

func __calc_gav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets_len : felt, assets : felt*
) -> (gav : Uint256):
    alloc_locals

    if assets_len == 0:
        return (gav=Uint256(0, 0))
    end

    let (gav_of_rest) = __calc_gav(assets_len=assets_len - 1, assets=assets + 1)
    let (asset_value) = calc_asset_value_in_vault(assets[0])
    let (gav, _) = uint256_add(asset_value, gav_of_rest)
    return (gav=gav)
end

@external
func set_vault_proxy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, addr : felt
):
    vault_proxy_addr.write(vault, addr)
    return ()
end

@view
func get_vault_proxy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    addr : felt
):
    let (caller) = get_caller_address()
    let (res) = vault_proxy_addr.read(caller)
    return (addr=res)
end

@external
func set_fee_mgr{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(addr : felt):
    # Todo - Considering change this as `extension_addr.write(FEE_MGR, addr)`
    fee_mgr_addr.write(addr)
    return ()
end

@view
func get_fee_mgr{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    addr : felt
):
    let (res) = fee_mgr_addr.read()
    return (addr=res)
end

@external
func set_policy_mgr{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(addr : felt):
    # Todo - Considering change this as `extension_addr.write(FEE_MGR, addr)`
    policy_mgr_addr.write(addr)
    return ()
end

@view
func get_policy_mgr{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    addr : felt
):
    let (res) = policy_mgr_addr.read()
    return (addr=res)
end

@external
func set_oracle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(addr : felt):
    oracle_addr.write(addr)
    return ()
end

@view
func get_oracle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    addr : felt
):
    let (res) = oracle_addr.read()
    return (addr=res)
end
