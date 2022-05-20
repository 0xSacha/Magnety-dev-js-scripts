# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct FeeConfig:
    member NONE : felt
    member ENTRANCE_FEE : felt
    member ENTRANCE_FEE_ENABLED : felt
    member EXIT_FEE : felt
    member EXIT_FEE_ENABLED : felt
    member PERFORMANCE_FEE : felt
    member PERFORMANCE_FEE_ENABLED : felt
    member MANAGEMENT_FEE : felt
    member MANAGEMENT_FEE_ENABLED : felt
end

@contract_interface
namespace IFeeManager:
    func get_treasury() -> (res: felt):
    end
    
    func get_stacking_vault() -> (res: felt):
    end
    
    func set_fee_config(vault : felt, key : felt, value : felt):
    end
    func get_fee_config(vault : felt, key : felt) -> (value : felt):
    end

    func set_claimed_timestamp(vault: felt, timestamp : felt):
    end

    func get_claimed_timestamp(vault: felt) -> (timestamp : felt):
    end
end
