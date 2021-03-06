# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@contract_interface
namespace IIntegrationManager:


    func setAvailableAsset(_asset: felt):
    end
    func setAvailableIntegration(_contract: felt, _selector: felt, _integration:felt):
    end


    func checkIsAssetAvailable(_asset: felt) -> (res: felt):
    end
    func checkIsIntegrationAvailable(_contract: felt, _selector: felt) -> (res: felt):
    end
    func getIntegration(_contract: felt, _selector: felt) -> (res: felt):
    end
end