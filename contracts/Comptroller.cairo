# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le
from starkware.cairo.common.memcpy import memcpy

from starkware.starknet.common.syscalls import get_tx_info, get_block_number, get_block_timestamp

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.interfaces.IOracle import IOracle
from contracts.interfaces.IPolicyManager import IPolicyManager
from contracts.interfaces.IValueInterpretor import IValueInterpretor
from contracts.interfaces.IIntegrationManager import IIntegrationManager
from contracts.interfaces.ISaver import ISaver

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.find_element import find_element

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)

# from starkware.cairo.common.uint256 import
from openzeppelin.security.safemath import uint256_checked_add, uint256_checked_sub_le

from openzeppelin.security.reentrancyguard import ReentrancyGuard

from openzeppelin.security.pausable import Pausable

from contracts.interfaces.IVault import VaultAction, IVault

from contracts.interfaces.IExternalPosition import IExternalPosition

from contracts.interfaces.IFeeManager import FeeConfig, IFeeManager

from contracts.interfaces.IVaultFactory import IVaultFactory

from contracts.interfaces.IPreLogic import IPreLogic

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent



@storage_var
func vaultFactory() -> (res : felt):
end

@storage_var
func assetManagerVaultAmount(assetManager: felt) -> (res: felt):
end

@storage_var
func assetManagerVault(assetManager: felt, vaultId: felt) -> (res: felt):
end

@storage_var
func vaultAmount() -> (res: felt):
end

@storage_var
func idToVault(id: felt) -> (res: felt):
end

@storage_var
func saver() -> (res: felt):
end


#
# Modifiers
#

func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
end

func onlyAssetManager{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(_vault: felt):
    let (assetManager_:felt) = IVault.getAssetManager(_vault)
    let (caller_) = get_caller_address()
    with_attr error_message("onlyAssetManager: only callable by the vault Manager"):
        assert (assetManager_ - caller_) = 0
    end
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
        _vaultFactory: felt,
        _saver: felt,
    ):
    vaultFactory.write(_vaultFactory)
    saver.write(_saver)
    return ()
end





# Activate and register a Vault

@external
func activateVault{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vault: felt,
        _asset: felt, 
        _amount: Uint256
    ):
    alloc_locals
    onlyAssetManager(_vault)
    let (caller_ : felt) = get_caller_address()
    let (isActivated_:felt) = IVault.checkIsActivated(_vault)
    with_attr error_message("activateVault: vault already activated"):
        assert isActivated_ = 0
    end
    let (currentAssetManagetVaultAmount: felt) = assetManagerVaultAmount.read(caller_)
    assetManagerVault.write(caller_, currentAssetManagetVaultAmount, _vault)
    assetManagerVaultAmount.write(caller_, currentAssetManagetVaultAmount + 1)
    let (currentVaultAmount:felt) = vaultAmount.read()
    vaultAmount.write(currentVaultAmount + 1)
    idToVault.write(currentVaultAmount, _vault)
    let (denominationAsset_:felt) = IVault.getDenominationAsset(_vault)
    with_attr error_message("activateVault: you can only feed the vault with the denomination asset"):
        assert (denominationAsset_ - _asset) = 0
    end
    IERC20.transferFrom(_asset, caller_, _vault, _amount)
    let (hundred_:Uint256) = felt_to_uint256(10000)
    let (sharePricePurchased_:Uint256) = uint256_div(_amount ,hundred_)
    
    #save 
    let (saver_:felt) = saver.read()
    let (tokenId_:Uint256) = IVault.getTotalSupply(_vault)
    let (contractAddress_:felt) = get_contract_address()
    ISaver.setNewMint(saver_, _vault, caller_, contractAddress_,tokenId_)
    __mintShare(_vault, caller_, hundred_, sharePricePurchased_)
    return ()
end

#
# Externals
#

#asset Manager stuff
@external
func addTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault:felt ,_asset : felt):
    alloc_locals
    onlyAssetManager(_vault)
    let (policyManager_:felt) = __getPolicyManager()
    IPolicyManager.checkIsAllowedTrackedAsset(policyManager_, _vault, _asset)
    __addTrackedAsset(_asset, _vault)
    return ()
end

@external
func removeTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault:felt ,asset : felt):
    onlyAssetManager(_vault)
    
    __removeTrackedAsset(_vault, asset)
    return ()
end

@external
func emergency_pause {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    Ownable.assert_only_owner()
    Pausable._pause()
    return ()
end


@external
func emergency_unpause {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    Ownable.assert_only_owner()
    Pausable._unpause()
    return ()
end

@external
func executeCall{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault:felt, _contract: felt, _selector: felt, _callData_len: felt, _callData: felt*):

    ReentrancyGuard._start()
    Pausable.assert_not_paused()
    alloc_locals
    onlyAssetManager(_vault)

    #check if allowed call
    let (policyManager_) = __getPolicyManager()
    let (isAllowedCall_) = IPolicyManager.checkIsAllowedIntegration(policyManager_, _vault, _contract, _selector)
    with_attr error_message("the operation is now allowed to the vault"):
        assert isAllowedCall_ = 1
    end

    #perform pre-call logic if necessary
    let (integrationManager_) = __getIntegrationManager()
    let (preLogicContract:felt) = IIntegrationManager.getIntegration(integrationManager_, _contract, _selector)
    let (isPreLogicNonRequired:felt) = __is_zero(preLogicContract)
    if isPreLogicNonRequired ==  0:
        IPreLogic.runPreLogic(preLogicContract, _vault, _callData_len, _callData)
        let (callData_ : felt*) = alloc()
        assert [callData_] = _contract
        assert [callData_ + 1] = _selector
        assert [callData_ + 2] = _callData_len
        memcpy(callData_, _callData + 3, _callData_len)
        IVault.receiveValidatedVaultAction(_vault, VaultAction.ExecuteCall, _callData_len +3, callData_)
        return()
    else:
    let (callData_ : felt*) = alloc()
    assert [callData_] = _contract
    assert [callData_ + 1] = _selector
    assert [callData_ + 2] = _callData_len
    memcpy(callData_ +3, _callData, _callData_len)
    IVault.receiveValidatedVaultAction(_vault, VaultAction.ExecuteCall, _callData_len +3, callData_)
    return ()


    ReentrancyGuard._end()
    end
end

@external
func claimManagementFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, _assets_len : felt, _assets : felt*, _percents_len:felt, _percents: felt*,
):
    alloc_locals
    onlyAssetManager(_vault)
    let (feeManager_:felt) = __getFeeManager()

    with_attr error_message("claimManagementFee: tab size not equal"):
        assert _percents_len = _assets_len
    end
    let (totalpercent:felt) = __calculTab100(_percents_len, _percents)
    with_attr error_message("claimManagementFee: sum of percents tab not equal at 100%"):
        assert totalpercent = 100
    end
    let (current_timestamp) = get_block_timestamp()
    let (claimed_timestamp) = IFeeManager.getClaimedTimestamp(feeManager_, _vault)

    let (gav:Uint256) = calc_gav(_vault)
    let interval_stamps = current_timestamp - claimed_timestamp
    let STAMPS_PER_DAY = 86400
    let interval_days = interval_stamps / STAMPS_PER_DAY

    let (APY, _, _, _) = __get_fee(_vault,FeeConfig.MANAGEMENT_FEE, gav)
    let (interval_days_uint256) = felt_to_uint256(interval_days)
    let (year_uint256) = felt_to_uint256(360)
    let (temp_total, temp_total_high) = uint256_mul(APY, interval_days_uint256)
    # TODO - High value should be considered
    assert temp_total_high.high = 0
    let (claimAmount_) = uint256_div(temp_total, year_uint256)
    let (amounts_ : felt*) = alloc()
    calc_amount_of_each_asset(_vault, claimAmount_, _assets_len, _assets, _percents, amounts_)
    let (caller_) = get_caller_address()
    __transferEachAssetMF(_vault,caller_, _assets_len, _assets, amounts_)
    return ()
end


#everyone
@external
func buyShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault: felt, _asset: felt, _amount: Uint256
):
    ReentrancyGuard._start()

    alloc_locals


    Pausable.assert_not_paused()
    let (denominationAsset_:felt) = IVault.getDenominationAsset(_vault)
    with_attr error_message("buy_share: you can only buy shares with the denomination asset of the vault"):
        assert (denominationAsset_ - _asset) = 0
    end
    __assertMaxminRange(_vault, _amount)
    let (caller : felt) = get_caller_address()
    __assertAllowedDepositor(_vault, caller)
    let (fee, fee_assset_manager, fee_treasury, fee_stacking_vault) = __get_fee(_vault, FeeConfig.ENTRANCE_FEE, _amount)

    # transfer fee to fee_treasury, stacking_vault
    let (assetManager:felt) = IVault.getAssetManager(_vault)
    let (treasury:felt) = __getTreasury()
    let (stacking_vault:felt) = __getStackingVault()

    IERC20.transferFrom(_asset, caller, assetManager, fee_assset_manager)
    IERC20.transferFrom(_asset, caller, treasury, fee_treasury)
    IERC20.transferFrom(_asset, caller, stacking_vault, fee_stacking_vault)

    let (amount_without_fee) = uint256_sub(_amount, fee)

    # calculate GAV as usdt
    let (gav) = calc_gav(_vault) #useless
    let (share_price) = getSharePrice(_vault)


    let (share_amount) = uint256_div(amount_without_fee, share_price)
    #!!!!!! can have some issues if share_price > asset_value, then div = 0 and share not taken into account

    # send token to the vault
    IERC20.transferFrom(_asset, caller, _vault, amount_without_fee)

    #save 
    let (saver_:felt) = saver.read()
    let (tokenId_:Uint256) = IVault.getTotalSupply(_vault)
    let (contractAddress_:felt) = get_contract_address()
    ISaver.setNewMint(saver_, _vault, caller, contractAddress_,tokenId_)

    # mint share
    __mintShare(_vault, caller, share_amount, share_price)


    ReentrancyGuard._end()

    return ()
end




    # TODO - should check if the caller is vault manager
func __addTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_asset: felt, _vault:felt):
    #TODO check if we can we got priceFeed for this asset
    let (call_data : felt*) = alloc()
    assert [call_data] = _asset
    IVault.receiveValidatedVaultAction(_vault, VaultAction.AddTrackedAsset, 1, call_data)
    return ()
end

func __removeTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_asset: felt, _vault:felt):
    alloc_locals
    #TODO check with policy manager if it is allowed to removetrack asset (negligeable value)
    let (call_data : felt*) = alloc()
    assert [call_data] = _asset
    
    IVault.receiveValidatedVaultAction(_vault, VaultAction.RemoveTrackedAsset, 1, call_data)
    return ()
end

@external
func sell_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault: felt,
    token_id : Uint256,
    share_amount : Uint256,
    assets_len : felt,
    assets : felt*,
    percents_len : felt,
    percents : felt*,
):
    ReentrancyGuard._start()
    alloc_locals

    Pausable.assert_not_paused()
    let (caller) = get_caller_address()
    let (owner_) = IVault.getOwnerOf(_vault, token_id)
    with_attr error_message("sell_share: not owner of shares"):
        assert caller = owner_
    end

    let (totalpercent:felt) = __calculTab100(percents_len, percents)
    with_attr error_message("sell_share: sum of percents tab not equal at 100%"):
        assert totalpercent = 100
    end

    #check timelock
    let (policyManager_:felt) = __getPolicyManager()
    let (mintedBlockTimesTamp_:felt) = IVault.getMintedBlockTimesTamp(_vault, token_id)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    let (timelock_:felt) = IPolicyManager.getTimelock(policyManager_, _vault)
    let diffTimesTamp_:felt = currentTimesTamp_ - mintedBlockTimesTamp_
    with_attr error_message("sell_share: timelock not reached"):
        assert_le(timelock_, diffTimesTamp_)
    end
    # calc value of share
    let (share_value) = __share_value_of_amount(_vault, share_amount)

    # calc value of each asset
    assert assets_len = percents_len
    let len = assets_len

    #get amount tab according to share_value and the percents tab 
    let (amounts : felt*) = alloc()
    calc_amount_of_each_asset(_vault, share_value, len, assets, percents, amounts)

    #calculate the performance 
    let(previous_share_price_:Uint256) = IVault.getSharePricePurchased(_vault,token_id)
    let(current_share_price_:Uint256) = getSharePrice(_vault)
    let(has_performed_) = uint256_le(previous_share_price_, current_share_price_)
    if has_performed_ == 1 :
        let(diff_:Uint256) = uint256_checked_sub_le(current_share_price_, previous_share_price_)
        let(diffperc_:Uint256,diffperc_h_) = uint256_mul(diff_, Uint256(100,0))
        let(perfF_:Uint256)=uint256_div(diffperc_, current_share_price_)
        tempvar perf_ = perfF_
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar perf_ = Uint256(0,0)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    let vaultPerformance = perf_
    # transfer token of each amount to the caller
    __transfer_each_asset(_vault, caller, len, assets, amounts, vaultPerformance)

    let (currentOwnerBalance:Uint256) = IVault.getBalanceOf(_vault,caller)

    # burn share
    __burn_share(_vault, token_id, share_amount)

     #save 
    let(newOwnerBalance:Uint256) = IVault.getBalanceOf(_vault, caller)
    let (isEqual_:felt) = uint256_eq(currentOwnerBalance, newOwnerBalance)
    let (saver_:felt) = saver.read()
    let (contractAddress_:felt) = get_contract_address()
    if isEqual_ == 0 :
        ISaver.setNewBurn(saver_, _vault, caller, contractAddress_, token_id)
        return ()
    end
    
    ReentrancyGuard._end()
    return ()
end

func calc_amount_of_each_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, total_value : Uint256, len : felt, assets : felt*, percents : felt*, amounts : felt*
):
    alloc_locals

    if len == 0:
        return ()
    end
    # asset_value = total_value * 100 / percents[0]
    let (denominationAsset_)= IVault.getDenominationAsset(_vault)
    let (percent) = felt_to_uint256(percents[0])

    let (assetValueInDenominationAsset_:Uint256) = uint256_percent(total_value, percent)
    let (assetPrice_:Uint256) = getAssetValue(assets[0], Uint256(1000000000000000000,0), denominationAsset_)
    let (intermediary_:Uint256,_) = uint256_mul(assetValueInDenominationAsset_, Uint256(1000000000000000000,0))
    let (assetAmount_) = uint256_div(intermediary_, assetPrice_)

    # Todo - should be change if amounts is Uint256
    assert [amounts] = assetAmount_.low
    # assert [amounts] = 1

    calc_amount_of_each_asset(
        _vault = _vault,
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
func getVaultAddressFromCallerAndId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vaultId: felt) -> (res: felt):
    let (caller_:felt) = get_caller_address()
    let(res:felt) = assetManagerVault.read(caller_, _vaultId)
    with_attr error_message("getVaultAddressFromCallerAndId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end



@view
func getVaultAmountFromCaller{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let (caller_:felt) = get_caller_address()
    let(res:felt) = assetManagerVaultAmount.read(caller_)
    return (res=res)
end

@view
func getVaultAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = vaultAmount.read()
    return (res=res)
end


@view
func getVaultAddressFromId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vaultId: felt) -> (res: felt):
    let(res:felt) = idToVault.read(_vaultId)
    with_attr error_message("getVaultAddressFromId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end


@view
func getSharePrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault:felt,) -> (
     price : Uint256
):
    alloc_locals

    let (gav) = calc_gav(_vault)
    let (total_supply) = IVault.getSharesTotalSupply(_vault)

    let (price : Uint256) = uint256_div(gav, total_supply)
    return (price=price)
end



@view
func getAssetValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _asset: felt, _amount: Uint256, _denominationAsset: felt
) -> (value: Uint256):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (valueInterpretor_:felt) = IVaultFactory.getValueInterpretor(vaultFactory_)
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(valueInterpretor_, _asset, _amount, _denominationAsset)
    return (value=value_)
end



# TODO - Should let the deno token be configurable since current one is usdt.
# calculate the entire value of assets that the vault has
@view
func calc_gav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt) -> (
    gav : Uint256
):
    alloc_locals
    let (asset_len : felt, assets : felt*) = IVault.getTrackedAssets(_vault)
    let (gav) = __calculGav(_vault, asset_len, assets)

    return (gav=gav)
end

@view
func __get_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault:felt, key: felt, amount: Uint256) -> (fee: Uint256, fee_asset_manager:Uint256, fee_treasury: Uint256, fee_stacking_vault: Uint256):
    alloc_locals
    let (key_enable : felt*) = alloc()
    let (isEntrance) = __is_zero(key - FeeConfig.ENTRANCE_FEE)
    let (isExit) = __is_zero(key - FeeConfig.EXIT_FEE)
    let (isPerformance) = __is_zero(key - FeeConfig.PERFORMANCE_FEE)
    let (isManagement) = __is_zero(key - FeeConfig.PERFORMANCE_FEE)

    let entranceFee = isEntrance * FeeConfig.ENTRANCE_FEE
    let exitFee = isExit * FeeConfig.EXIT_FEE
    let performanceFee = isPerformance * FeeConfig.PERFORMANCE_FEE
    let managementFee = isManagement * FeeConfig.PERFORMANCE_FEE

    let config = entranceFee + exitFee + performanceFee + managementFee

    let (feeManager_) = __getFeeManager()
    let (percent) = IFeeManager.getFeeConfig(feeManager_, _vault, config)
    let (percent_uint256) = felt_to_uint256(percent)

    let (fee) = uint256_percent(amount, percent_uint256)
    # 80% to the assetmanager, 16% to stacking vault, 4% to the DAOtreasury

    let (fee_asset_manager) = uint256_percent(fee, Uint256(80,0))
    let (fee_stacking_vault) = uint256_percent(fee, Uint256(16,0))
    let (fee_treasury) = uint256_percent(fee, Uint256(4,0))

    return (fee=fee, fee_asset_manager= fee_asset_manager,fee_treasury=fee_treasury, fee_stacking_vault=fee_stacking_vault)
end

func __transferEachAssetMF{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, caller : felt, len : felt, assets : felt*, amounts : felt*,
):
    alloc_locals
    if len == 0:
        return ()
    end

    let asset = assets[0]
    let(amount_:Uint256) = felt_to_uint256(amounts[0])
    
    let (assetManagerAmount) = uint256_percent(amount_, Uint256(80,0))
    let (feeStackingVault) = uint256_percent(amount_, Uint256(16,0))
    let (feeTreasury) = uint256_percent(amount_, Uint256(4,0))

    let (treasury_) = __getTreasury()
    let (stackingVault_) = __getStackingVault()

    __transferAssetTo(_vault, asset, feeTreasury, treasury_)
    __transferAssetTo(_vault, asset, feeStackingVault, stackingVault_)
    __transferAssetTo(_vault, asset, assetManagerAmount, caller)

    __transferEachAssetMF(_vault, caller, len - 1, assets + 1, amounts + 1)
    return ()
end

func __transfer_each_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, caller : felt, len : felt, assets : felt*, amounts : felt*, perf : Uint256,
):
    alloc_locals
    if len == 0:
        return ()
    end

    let (amount) = felt_to_uint256(amounts[0])
    let asset = assets[0]

    #PERFORMANCE FEES
    let(amount_:Uint256) = uint256_percent(amount, perf)
    let (fee_perf, fee_assset_manager, fee_treasury, fee_stacking_vault) = __get_fee(_vault, FeeConfig.PERFORMANCE_FEE, amount_)

    # transfer fee to asset maanger, fee_treasury, stacking_vault 
    let (assetManager_:felt) = IVault.getAssetManager(_vault)
    let (treasury_:felt) = __getTreasury()
    let (stackingVault_) = __getStackingVault()
    __transferAssetTo(_vault, asset, fee_assset_manager, assetManager_)
    __transferAssetTo(_vault, asset, fee_treasury, treasury_)
    __transferAssetTo(_vault, asset, fee_stacking_vault, stackingVault_)



    let (amount_without_performance_fee) = uint256_sub(amount, fee_perf)
    #EXIT FEES
    let (fee_exit, fee_assset_manager, fee_treasury, fee_stacking_vault) = __get_fee(_vault, FeeConfig.EXIT_FEE, amount_without_performance_fee)

    # transfer fee to asset maanger, fee_treasury, stacking_vault 
    __transferAssetTo(_vault, asset, fee_assset_manager, assetManager_)
    __transferAssetTo(_vault, asset, fee_treasury, treasury_)
    __transferAssetTo(_vault, asset, fee_stacking_vault, stackingVault_)


    let (amount_without_fee) = uint256_sub(amount_without_performance_fee, fee_exit)

    __transferAssetTo(_vault, assets[0], amount_without_fee, caller)
    __transfer_each_asset(_vault, caller, len - 1, assets + 1, amounts + 1, perf)

    return ()
end

func __transferAssetTo{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, asset : felt, amount : Uint256, to : felt
):
    alloc_locals

    # transfer asset to the user
    let (call_data : felt*) = alloc()
    assert [call_data] = asset
    # TODO - vault_lib should change share_amount type into Uint256, which is felt atm
    assert [call_data + 1] = to
    # Todo - should consider chaning amount to Uint256
    assert [call_data + 2] = amount.low

    assert amount.high = 0

    IVault.receiveValidatedVaultAction(_vault, VaultAction.WithdrawAssetTo, 3, call_data)

    return ()
end

func __share_value_of_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, amount : Uint256
) -> (value : Uint256):
    alloc_locals
    let (share_price) = getSharePrice(_vault)
    let (value_low, value_high) = uint256_mul(share_price, amount)

    assert value_high.low = 0
    assert value_high.high = 0

    # TODO - maybe we should consider value_high
    return (value=value_low)
end

func __burn_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, token_id : Uint256, amount : Uint256
):
    alloc_locals

    let (call_data : felt*) = alloc()
    assert [call_data] = token_id.low
    assert token_id.high = 0
    # TODO - vault_lib should change share_amount type into Uint256, which is felt atm
    assert [call_data + 1] = amount.low

 
    IVault.receiveValidatedVaultAction(_vault, VaultAction.BurnShares, 2, call_data)

    return ()
end


func __calculGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, assets_len : felt, assets : felt*
) -> (gav : Uint256):
    alloc_locals
    if assets_len == 0:
        return (gav=Uint256(0, 0))
    end

    let (gavOfRest) = __calculGav(_vault=_vault, assets_len=assets_len - 1, assets=assets + 1)
    let(amount_:Uint256) = IVault.getAssetBalance(_vault, assets[0])
    let(denominationAsset_:felt) = IVault.getDenominationAsset(_vault)
    let (asset_value:Uint256) = getAssetValue(assets[0], amount_, denominationAsset_)
    let (gav, _) = uint256_add(asset_value, gavOfRest)
    return (gav=gav)
end




func __mintShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault:felt, caller : felt, share_amount : Uint256, share_price : Uint256
):
    alloc_locals

    # TODO - share_amount.low, share_price.low should be updated like uint256_to_felt(share_amount)
    let (call_data : felt*) = alloc()
    assert [call_data] = caller
    # TODO - vault_lib should change share_amount type into Uint256, which is felt atm
    assert [call_data + 1] = share_amount.low
    assert [call_data + 2] = share_price.low

    IVault.receiveValidatedVaultAction(_vault, VaultAction.MintShares, 3, call_data)

    return ()
end


func __getTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (treasury_:felt) = IVaultFactory.getDaoTreasury(vaultFactory_)
    return (res=treasury_)
end

func __getStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (stackingVault_:felt) = IVaultFactory.getStackingVault(vaultFactory_)
    return (res=stackingVault_)
end

func __getFeeManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (feeManager_:felt) = IVaultFactory.getFeeManager(vaultFactory_)
    return (res=feeManager_)
end

func __getPolicyManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (policyManager_:felt) = IVaultFactory.getPolicyManager(vaultFactory_)
    return (res=policyManager_)
end

func __getIntegrationManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (integrationManager_:felt) = IVaultFactory.getIntegrationManager(vaultFactory_)
    return (res=integrationManager_)
end




func __assertMaxminRange{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault : felt, amount : Uint256):
    alloc_locals
    let (policyManager_) = __getPolicyManager()
    let (max:Uint256, min:Uint256) = IPolicyManager.getMaxminAmount(policyManager_, _vault)
    let (le_max) = uint256_le(amount, max)
    let (be_min) = uint256_le(min, amount)
    with_attr error_message("__assertMaxminRange: amount is too high"):
        assert le_max = 1
    end
    with_attr error_message("__assertMaxminRange: amount is too low"):
        assert be_min = 1
    end
    return ()
end

func __assertAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault : felt, _caller : felt):
    alloc_locals
    let (policyManager_) = __getPolicyManager()
    let (isPublic_:felt) = IPolicyManager.checkIsPublic(policyManager_, _vault)
    if isPublic_ == 1:
        return()
    else:
        let (isAllowedDepositor_:felt) = IPolicyManager.checkIsAllowedDepositor(policyManager_, _vault, _caller)
        with_attr error_message("__assertAllowedDepositor: not allowed depositor"):
        assert isAllowedDepositor_ = 1
        end
    end
    return ()
end

func __calculTab100{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _percents_len : felt, _percents : felt*) -> (res:felt):
    alloc_locals
    if _percents_len == 0:
        return (0)
    end
    let newPercents_len:felt = _percents_len - 1
    let newPercents:felt* = _percents + 1
    let (_previousElem:felt) = __calculTab100(newPercents_len, newPercents)
    let res:felt = [_percents] + _previousElem
    return (res=res)
end


