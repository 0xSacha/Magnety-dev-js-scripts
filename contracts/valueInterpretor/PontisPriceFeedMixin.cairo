# Declare this file as a StarkNet contract.
%lang starknet
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_mul_low

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interface.IFeeManager import FeeConfig
from interfaces.IOracleProxy import IOracleProxy
from interfaces.IVaultFactory import IVaultFactory


@storage_var
func vaultFactory() -> (vaultFactoryAddress : felt):
end

@storage_var
func isSupportedPrimitiveAsset(asset:felt) -> (res: felt):
end

@storage_var
func aggregatorInfoFromAsset(asset:felt) -> (res: AggregatorInfo):
end


struct AggregatorInfo:
    member key: felt
    member rateAsset: felt
end


func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
end


@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory: felt,
    ):
    vaultFactory.write(_vaultFactory)
    return ()
end

#
# Getters
#

@view
@external
func checkIsSupportedPrimitiveAsset{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _asset: felt,
    ) -> (res:felt):
    let(res:felt) = isSupportedPrimitiveAsset(_asset)
    return(res=res)
end

@view
func calcAssetValueBmToDeno{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _baseAsset: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    let (denominationAssetAggregatorInfo_:felt) = aggregatorInfoFromAsset(_denominationAsset)
    let (baseAssetAggregatorInfo_:felt) = aggregatorInfoFromAsset(_baseAsset)
    with_attr error_message("setComptroller: can only be set once"):
        assert denominationAssetAggregatorInfo_.rateAsset = baseAssetAggregatorInfo_.rateAsset
    end

    let (vaultFactory_:felt) = vaultFactory.read()
    let (pontisOracle_:felt) = IVaultFactory.getOracle(vaultFactory_)
    
    let (denominationAssetRateFelt_:felt, lastUpdatedTimestamp1_:felt) = IOracleProxy.get_value(pontisOracle_, denominationAssetAggregatorInfo_.key)
    let (denominationAssetRate_:Uint256) = felt_to_uint256(denominationAssetRateFelt_)
    let (baseAssetRateFelt_:Uint256, lastUpdatedTimestamp2_:felt) = IOracleProxy.get_value(pontisOracle_, baseAssetAggregatorInfo_.key)
    let (baseAssetRate_:Uint256) = felt_to_uint256(baseAssetRateFelt_)
    let (pow18:Uint256) = Uint256(1000000000000000000,0)
    let(step_1:Uint256) = uint256_mul_low(baseAssetRate_, _amount)
    let(step_2:Uint256) = uint256_mul_low(step_1, pow18)
    let(step_3:Uint256) = uint256_div(step_2, denominationAssetRate_)
    return (res=step_3)
end

#
#Setters
#

@external
func addPrimitive{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _asset: felt,
        _key: Uint256,
        _rateAsset:felt,
    ) -> (res:Uint256):
    onlyVaultFactory()
    isSupportedPrimitiveAsset.write(_asset, 1)
    aggregatorInfoFromAsset.write(_asset, _key, _rateAsset)
end

