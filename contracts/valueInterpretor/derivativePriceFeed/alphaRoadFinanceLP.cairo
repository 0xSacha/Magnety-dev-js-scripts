%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interface.IARFPool import IARFPool
from contracts.interface.IARFSwapController import IARFSwapController
from starkware.cairo.common.math import assert_not_zero


@storage_var
func IARFSwapController() -> (res: felt):
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
    let(IARFSwapController_:felt) = IARFSwapController.read()
    with_attr error_message("calcUnderlyingValues: IARFSwapController address not found"):
        assert_not_zero(IARFSwapController_)
    end
    let (underlyingsAssets_ : felt*) = alloc()
    let (underlyingsAmount_ : felt*) = alloc()
    let (totalSupply_:Uint256) = IARFPool.totalSupply(_derivative)
    assert [underlyingsAssets_] = IARFPool.getToken0()
    assert [underlyingsAssets_ + 1] = IARFPool.getToken1()
    let (reserveToken0_:Uint256, reserveToken1_:Uint256) = IARFPool.getReserves()
    let (amountToken0_:Uint256, amountToken1_:Uint256) = IARFSwapController.removeLiquidityQuote(_amount, reserveToken0_, reserveToken1_, totalSupply_)
    assert [underlyingsAmount_] = amountToken0_
    assert [underlyingsAmount_] = amountToken1_
    return (underlyingsAssets_len=2, underlyingsAssets=underlyingsAssets_, underlyingsAmount_len=2, underlyingsAmount=underlyingsAmount_)
end


@view
func getIARFSwapController{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res:felt):
    let(res_:felt) = IARFSwapController.read()
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
    IARFSwapController.write(_IARFSwapController)
    return()
end
 
