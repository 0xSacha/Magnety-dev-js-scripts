# Declare this file as a StarkNet contract.
%lang starknet
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from interfaces.IPontisPriceFeedMixin import IPontisPriceFeedMixin
from interfaces.IVaultFactory import IVaultFactory
from interfaces.IDerivativePriceFeed import IDerivativePriceFeed

from starkware.cairo.common.math import assert_not_zero


@storage_var
func vaultFactory() -> (vaultFactoryAddress : felt):
end

@storage_var
func derivativeToPriceFeed(derivative:felt) -> (res: felt):
end

@storage_var
func isSupportedDerivativeAsset(derivative:felt) -> (res: felt):
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

func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
end

#getters

@view
func calculAssetValue{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _baseAsset: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    if  _baseAsset == _denominationAsset:
        return (res=_amount)
    end
    let (vaultFactory_:felt) = vaultFactory.read()
    let (primitivePriceFeed_:felt) = IVaultFactory.getPrimitivePriceFeed(vaultFactory_)
    let (isSupportedPrimitiveAsset_) = IPontisPriceFeedMixin.checkIsSupportedPrimitiveAsset(primitivePriceFeed_, _baseAsset)

    if isSupportedPrimitiveAsset_ == 1:
        let (res:Uint256) = IPontisPriceFeedMixin.calcAssetValueBmToDeno(primitivePriceFeed_, _baseAsset, _amount, _denominationAsset)
        return(res=res)
    else:
        let (isSupportedPrimitiveAsset_) = isSupportedDerivativeAsset.read(_baseAsset)
        with_attr error_message("calculAssetValue: asset not supported"):
            assert_not_zero(isSupportedPrimitiveAsset_)
        end
        let (derivativePriceFeed_:felt) = IVaultFactory.getDerivativePriceFeed(vaultFactory_)
        let (res:Uint256) = __calcDerivativeValue(derivativePriceFeed_, _baseAsset, _amount, _denominationAsset)
        return(res=res)
    end
end

@view
func getDerivativePriceFeed{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
    ) -> (res:felt):
    let (res:felt) = derivativeToPriceFeed.read(_derivative)
    return(res=res)
end

@view
func checkIsSupportedDerivativeAsset{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
    ) -> (res:felt):
    let (res:felt) = isSupportedDerivativeAsset.read(_derivative)
    return(res=res)
end


#
#External
#

@external
func addDerivative{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
        _priceFeed: felt,
    ):
    onlyVaultFactory()
    isSupportedDerivativeAsset.write(_derivative, 1)
    derivativeToPriceFeed.write(_derivative, _priceFeed)
    return()
end




#
# Internal
#

func __calcDerivativeValue{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivativePriceFeed: felt,
        _derivative: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    let ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ) = IDerivativePriceFeed.calcUnderlyingValues(_derivativePriceFeed, _derivative, _amount)
    with_attr error_message("__calcDerivativeValue: No underlyings"):
        assert_not_zero(underlyingsAssets_len)
    end

    with_attr error_message("__calcDerivativeValue: Arrays unequal lengths"):
        assert underlyingsAssets_len = underlyingsAmount_len
    end

    let (res_:Uint256) = __calcUnderlyingDerivativeValue(underlyingsAssets_len, underlyingsAssets, underlyingsAmount_len, underlyingsAmount, _denominationAsset)
    return(res=res_)
    end



func __calcUnderlyingDerivativeValue{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_underlyingsAssets_len:felt, _underlyingsAssets:felt*, _underlyingsAmount_len:felt, _underlyingsAmount:Uint256*, _denominationAsset:felt) -> (res:Uint256):
    alloc_locals
    if _underlyingsAssets_len == 0:
        return (Uint256(0,0))
    end

    let baseAsset_:felt = [_underlyingsAssets]
    let amount_:Uint256 = [_underlyingsAmount]        

    let (underlyingValue_:Uint256) = calculAssetValue(baseAsset_, amount_, _denominationAsset)

    let newUnderlyingsAssets_len_:felt = _underlyingsAssets_len -1
    let newUnderlyingsAssets_:felt* = _underlyingsAssets + 1
    let newUnderlyingsAmount_len_:felt = _underlyingsAmount_len -1
    let newUnderlyingsAmount_:Uint256* = _underlyingsAmount + 1
    let (nextValue_:Uint256) = __calcUnderlyingDerivativeValue(newUnderlyingsAssets_len_, newUnderlyingsAssets_, newUnderlyingsAmount_len_, newUnderlyingsAmount_, _denominationAsset)
    
    let (res_:Uint256, _) = uint256_add(underlyingValue_, nextValue_)  

    return (res=res_)
end
