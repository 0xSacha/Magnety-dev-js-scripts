%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IARFPool import IARFPool
from contracts.interfaces.IARFSwapController import IARFSwapController
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

@storage_var
func IARFSwapControllerContract() -> (res: felt):
end

#
#Getter
#

@view
func calcUnderlyingValues{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_derivative: felt, _amount: Uint256) -> ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ):
    alloc_locals
    let(IARFSwapController_:felt) = IARFSwapControllerContract.read()
    with_attr error_message("calcUnderlyingValues: IARFSwapController address not found"):
        assert_not_zero(IARFSwapController_)
    end
    let(isPoolExist_:felt) = IARFPool.name(_derivative)
    with_attr error_message("calcUnderlyingValues: can't find pool from LPtoken"):
        assert_not_zero(isPoolExist_)
    end
    let (underlyingsAssets_ : felt*) = alloc()
    let (underlyingsAmount_ : Uint256*) = alloc()
    let (totalSupply_:Uint256) = IARFPool.totalSupply(_derivative)
    let (underlyingsAssets0_:felt) = IARFPool.getToken0(_derivative)
    assert [underlyingsAssets_] = underlyingsAssets0_
    let (underlyingsAssets1_:felt) = IARFPool.getToken1(_derivative)
    assert [underlyingsAssets_ + 1] = underlyingsAssets1_
    let (reserveToken0_:Uint256, reserveToken1_:Uint256) = IARFPool.getReserves(_derivative)
    let (amountToken0_:Uint256, amountToken1_:Uint256) = IARFSwapController.removeLiquidityQuote(IARFSwapController_, _amount, reserveToken0_, reserveToken1_, totalSupply_)
    assert [underlyingsAmount_] = amountToken0_
    assert [underlyingsAmount_+2] = amountToken1_
    return (underlyingsAssets_len=2, underlyingsAssets=underlyingsAssets_, underlyingsAmount_len=2, underlyingsAmount=underlyingsAmount_)
end


@view
func getIARFSwapController{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res:felt):
    let(res_:felt) = IARFSwapControllerContract.read()
    return(res=res_)
end


#
#External
#
@external
func setIARFSwapController{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _IARFSwapController: felt,
    ):
    IARFSwapControllerContract.write(_IARFSwapController)
    return()
end
 
