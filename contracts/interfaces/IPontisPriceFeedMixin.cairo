# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@contract_interface
namespace IPontisPriceFeedMixin:
    func addPrimitive(_asset: felt, _amount:Uint256, _rateAsset:felt):
    end

    func calcAssetValueBmToDeno(_baseAsset: felt, _denominationAsset: felt):
    end
    
    func checkIsSupportedPrimitiveAsset(_asset: felt):
    end
end
