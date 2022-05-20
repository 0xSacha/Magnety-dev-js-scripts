%lang starknet

@contract_interface
namespace IOracleProxy:
    func get_value(key : felt) -> (value : felt, last_updated_timestamp : felt):
    end
end