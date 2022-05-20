%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IComptroller:
    # Vault actionn only call this with the right vaultAction to perform

    # initialize comptroller with denomination asset and asset manager, only callable by fundeployer
    func proxyInitializer(_denominationAsset : felt, _assetManager : felt, _vaultProxy : felt):
    end

end
