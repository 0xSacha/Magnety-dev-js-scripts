%lang starknet

from contracts.libraries.structs.PoolPair import PoolPair


token_0_address
@contract_interface
namespace IARFPoolFactory:
    func getPool(pair: PoolPair) -> (pool_address: felt):
    end

    func getPair(pool_address : felt) -> (pair: PoolPair):
    end
    
    func getPools() -> (pools_len: felt, pools: felt*):
    end

    func addManualPool(new_pool_address: felt, token_0_address: felt, token_1_address: felt) -> (success: felt):
    end
end