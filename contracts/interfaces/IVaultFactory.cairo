%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IVaultFactory:

    # Vault factory getters

    func getOracle() -> (res : felt):
    end

    func getFeeManager() -> (res : felt):
    end

    func getPolicyManager() -> (res : felt):
    end

    func getIntegrationManager() -> (res : felt):
    end

    func getDerivativePriceFeed() -> (res : felt):
    end

    func getPrimitivePriceFeed() -> (res : felt):
    end

    func getValueInterpretor() -> (res : felt):
    end

    func getDaoTreasury() -> (res : felt):
    end

    func getStackingVault() -> (res : felt):
    end

end
