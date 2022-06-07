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
from interfaces.IExternalPositionPriceFeed import IExternalPositionPriceFeed

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


@storage_var
func externalPositionToPriceFeed(externalPosition:felt) -> (res: felt):
end

@storage_var
func isSupportedExternalPosition(externalPosition:felt) -> (res: felt):
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

func onlyOwner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    let (owner_) = IVaultFactory.getOwner(vaultFactory_)
    with_attr error_message("onlyOwner: only callable by the owner"):
        assert owner_ = caller_
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
        let (isSupportedDerivativeAsset_) = isSupportedDerivativeAsset.read(_baseAsset)
        if isSupportedDerivativeAsset_ == 1:
        let (derivativePriceFeed_:felt) = getDerivativePriceFeed(_baseAsset)
        let (res:Uint256) = __calcDerivativeValue(derivativePriceFeed_, _baseAsset, _amount, _denominationAsset)
        return(res=res)
        else:
        let (externalPositionPriceFeed_:felt) = getExternalPositionPriceFeed(_baseAsset)
        let (res:Uint256) = __calcExternalPositionValue(externalPositionPriceFeed_, _baseAsset, _amount, _denominationAsset)
        return(res=res)
        end
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

@view
func getExternalPositionPriceFeed{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPosition: felt,
    ) -> (res:felt):
    let (res:felt) = externalPositionToPriceFeed.read(_externalPosition)
    return(res=res)
end

@view
func checkIsSupportedExternalPosition{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPosition: felt,
    ) -> (res:felt):
    let (res:felt) = isSupportedExternalPosition.read(_externalPosition)
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
    onlyOwner()
    isSupportedDerivativeAsset.write(_derivative, 1)
    derivativeToPriceFeed.write(_derivative, _priceFeed)
    return()
end

@external
func addExternalPosition{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPosition: felt,
        _priceFeed: felt,
    ):
    onlyOwner()
    isSupportedExternalPosition.write(_externalPosition, 1)
    externalPositionToPriceFeed.write(_externalPosition, _priceFeed)
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

    let (res_:Uint256) = __calcUnderlyingValue(underlyingsAssets_len, underlyingsAssets, underlyingsAmount_len, underlyingsAmount, _denominationAsset)
    return(res=res_)
end


func __calcExternalPositionValue{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPositionPriceFeed: felt,
        _externalPosition: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    let ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ) = IExternalPositionPriceFeed.calcUnderlyingValues(_externalPositionPriceFeed, _externalPosition, _amount)
    with_attr error_message("__calcExternalPositionValue: No underlyings"):
        assert_not_zero(underlyingsAssets_len)
    end

    with_attr error_message("__calcExternalPositionValue: Arrays unequal lengths"):
        assert underlyingsAssets_len = underlyingsAmount_len
    end

    let (res_:Uint256) = __calcUnderlyingValue(underlyingsAssets_len, underlyingsAssets, underlyingsAmount_len, underlyingsAmount, _denominationAsset)
    return(res=res_)
end



func __calcUnderlyingValue{
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
    let newUnderlyingsAmount_:Uint256* = _underlyingsAmount + 2
    let (nextValue_:Uint256) = __calcUnderlyingValue(newUnderlyingsAssets_len_, newUnderlyingsAssets_, newUnderlyingsAmount_len_, newUnderlyingsAmount_, _denominationAsset)
    let (res_:Uint256, _) = uint256_add(underlyingValue_, nextValue_)  
    return (res=res_)
end
