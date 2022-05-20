%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interface.IVault import IVault
from contracts.interface.IARFPoolFactory import IARFPoolFactory

@storage_var
func IARFPoolFactory() -> (res : felt):
end

struct PoolPair:
    member token_0_address: felt
    member token_1_address: felt
end

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _IARFPoolFactory: felt,
    ):
    IARFPoolFactory.write(_IARFPoolFactory)
    return ()
end

@external
func runPreLogic{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr 
    }(_vault:felt, _callData_len:felt, _callData*:felt):
    let (token0_:felt) = [callData]
    let (token1_:felt) = [callData + 1]
    let (poolPair_:PoolPair) = PoolPair(token0_,token1_)
    let (incomingAsset_:felt) = IARFPoolFactory.getPool(poolPair_)
    let (isTrackedAsset_:felt) = IVault.isTrackedAsset(_vault, incomingAsset_)
    with_attr error_message("addLiquidityFromAlpha: incoming LP Asset not tracked"):
        assert_not_zero(isTrackedAsset_)
    end
    return()
end
