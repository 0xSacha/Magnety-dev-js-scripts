%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address, get_contract_address, get_block_timestamp
)

from contracts.interfaces.IFeeManager import FeeConfig, IFeeManager

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
)

from contracts.utils.utils import (
    felt_to_uint256,
)

from starkware.cairo.common.alloc import (
    alloc,
)

from starkware.cairo.common.find_element import (
    find_element,
)


from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_check,
    uint256_le,
    uint256_eq,
)

from openzeppelin.security.safemath import (
    uint256_checked_add,
    uint256_checked_sub_le,
)

from contracts.interfaces.IVault import IVault

from contracts.interfaces.IComptroller import IComptroller

from contracts.interfaces.IPolicyManager import IPolicyManager

from contracts.interfaces.IIntegrationManager import IIntegrationManager

from contracts.interfaces.IPontisPriceFeedMixin import IPontisPriceFeedMixin


#
# Events
#

@event
func ComptrollerSet(comptrollerLibAddress: felt):
end

@event
func FeeManagerSet(feeManagerAddress: felt):
end

@event
func OracleSet(feeManagerAddress: felt):
end

@event
func VaultInitalized(vaultLibAddress: felt):
end

const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820
#
# Storage
#

@storage_var
func comptroller() -> (res: felt):
end

@storage_var
func oracle() -> (res: felt):
end

@storage_var
func feeManager() -> (res: felt):
end

@storage_var
func policyManager() -> (res: felt):
end

@storage_var
func integrationManager() -> (res: felt):
end

@storage_var
func valueInterpretor() -> (res: felt):
end

@storage_var
func primitivePriceFeed() -> (res: felt):
end

@storage_var
func derivativePriceFeed() -> (res: felt):
end


@storage_var
func stackingVault() -> (res : felt):
end

@storage_var
func daoTreasury() -> (res : felt):
end



struct integration:
    member contract : felt
    member selector : felt
    member integration: felt
end

#
# Getters 
#

@view
func getComptroller{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = comptroller.read()
    return(res)
end

@view
func getOracle{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = oracle.read()
    return(res)
end


@view
func getFeeManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = feeManager.read()
    return(res)
end

@view
func getPolicyManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = policyManager.read()
    return(res)
end

@view
func getIntegrationManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = integrationManager.read()
    return(res)
end

@view
func getValueInterpretor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = valueInterpretor.read()
    return(res)
end

@view
func getPrimitivePriceFeed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = primitivePriceFeed.read()
    return(res)
end

@view
func getDerivativePriceFeed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = derivativePriceFeed.read()
    return(res)
end

@view
func getStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        res : felt):
    let (res) = stackingVault.read()
    return (res)
end

@view
func getDaoTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        res : felt):
    let (res) = daoTreasury.read()
    return (res)
end

#
# Setters
#

#owner
@external
func setComptroller{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _comptrolleur: felt,
    ):
    let (comptroller_:felt) = comptroller.read()
    with_attr error_message("setComptroller: can only be set once"):
        assert comptroller_ = 0
    end
    comptroller.write(_comptrolleur)
    return ()
end

@external
func setOracle{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _oracle: felt,
    ):
    let (oracle_:felt) = oracle.read()
    with_attr error_message("setOracle: can only be set once"):
        assert oracle_ = 0
    end
    oracle.write(_oracle)
    return ()
end

@external
func setFeeManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _feeManager: felt,
    ):
    let (feeManager_:felt) = feeManager.read()
    with_attr error_message("setFeeManager: can only be set once"):
        assert feeManager_ = 0
    end
    feeManager.write(_feeManager)
    return ()
end


@external
func setPolicyManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _policyManager: felt,
    ):
    let (policyManager_:felt) = policyManager.read()
    with_attr error_message("setPolicyManager: can only be set once"):
        assert policyManager_ = 0
    end
    policyManager.write(_policyManager)
    return ()
end

@external
func setIntegrationManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _integrationManager: felt,
    ):
    let (integrationManager_:felt) = integrationManager.read()
    with_attr error_message("setIntegrationManager: can only be set once"):
        assert integrationManager_ = 0
    end
    integrationManager.write(_integrationManager)
    return ()
end

@external
func setValueInterpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _valueInterpretor : felt):
    valueInterpretor.write(_valueInterpretor)
    return ()
end

@external
func setPrimitivePriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _primitivePriceFeed : felt):
    primitivePriceFeed.write(_primitivePriceFeed)
    return ()
end


@external
func setStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _stackingVault : felt):
    stackingVault.write(_stackingVault)
    return ()
end

@external
func setDaoTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _daoTreasury : felt):
    daoTreasury.write(_daoTreasury)
    return ()
end

@external
func addGlobalAllowedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*) -> ():
    alloc_locals
    if _assetList_len == 0:
        return ()
    end
    let (integrationManager_:felt) = integrationManager.read()
    with_attr error_message("addGlobalAllowedAsset: integrationManager dependency not set"):
        assert_not_zero(integrationManager_)
    end

    let asset_:felt = [_assetList]
    IIntegrationManager.setAvailableAsset(integrationManager_, asset_)
    IIntegrationManager.setAvailableIntegration(integrationManager_, asset_, APPROVE_SELECTOR, 0)

    let newAssetList_len:felt = _assetList_len -1
    let newAssetList:felt* = _assetList + 1

    return addGlobalAllowedAsset(
        _assetList_len= newAssetList_len,
        _assetList= newAssetList,
        )
end

@external
func addGlobalAllowedIntegration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integrationList_len:felt, _integrationList:integration*) -> ():
    alloc_locals
    if _integrationList_len == 0:
        return ()
    end
    let (integrationManager_:felt) = integrationManager.read()
    with_attr error_message("addGlobalAllowedIntegration: integrationManager dependency not set"):
        assert_not_zero(integrationManager_)
    end

    let integration_:integration = [_integrationList]
    IIntegrationManager.setAvailableIntegration(integrationManager_, integration_.contract, integration_.selector, integration_.integration)

    let newIntegrationList_len:felt = _integrationList_len -1
    let newIntegrationList:integration* = _integrationList + 1

    return addGlobalAllowedIntegration(
        _integrationList_len= newIntegrationList_len,
        _integrationList= newIntegrationList,
        )
end

#asset manager

@external
func addAllowedDepositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _depositors_len:felt, _depositors:felt*) -> ():
    alloc_locals
    let (caller_:felt) = get_caller_address()
    let (assetManager_:felt) = IVault.getAssetManager(_vault)
    with_attr error_message("addAllowedDepositors: caller is not asset manager"):
        assert caller_ = assetManager_
    end

    let (policyManager_:felt) = policyManager.read()
    let (isPublic_:felt) = IPolicyManager.checkIsPublic(policyManager_, _vault)
    with_attr error_message("addAllowedDepositors: the fund is already public"):
        assert isPublic_ = 0
    end

   __addAllowedDepositors(_vault, _depositors_len, _depositors)
    return ()
end



# Initialize a vault freshly deployed
@external
func initializeFund{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
    #vault initializer
    _vault: felt,
    _fundName:felt,
    _fundSymbol:felt,
    _denominationAsset:felt,
    _positionLimitAmount:Uint256,

    #fee config Initializer
    _feeConfig_len: felt,
    _feeConfig: felt*,

    #allowed asset to be tracked
    _assetList_len: felt,
    _assetList: felt*,

    #allowed protocol to interact with 
    _integration_len: felt,
    _integration: integration*,

    #min/max amount for depositors (with the denomination asset)
    _minAmount:Uint256,
    _maxAmount:Uint256,

    #Timelock before selling shares
    _timelock:felt,

    #allowed depositors 
    _isPublic:felt,

    ):
    alloc_locals

    let (comptroller_:felt) = comptroller.read()
    let (oracle_:felt) = oracle.read()
    let (feeManager_:felt) = feeManager.read()
    let (policyManager_:felt) = policyManager.read()
    let (integrationManager_:felt) = integrationManager.read()
    let (valueInterpretor_:felt) = valueInterpretor.read()
    let (primitivePriceFeed_:felt) = primitivePriceFeed.read()
    with_attr error_message("initializeFund: dependencies not set"):
        assert_not_zero(feeManager_  * comptroller_ * oracle_ * policyManager_ * integrationManager_)
    end

    let (name_:felt) = IVault.getName(_vault)
    with_attr error_message("initializeFund: vault already initialized"):
        assert name_ = 0
    end

    with_attr error_message("initializeFund: can not set value to 0"):
        assert_not_zero(_vault * _fundName * _fundSymbol * _denominationAsset)
    end

    let (assetManager_: felt) = get_caller_address()
    let (isupportedPriceFeed_:felt) = IPontisPriceFeedMixin.checkIsSupportedPrimitiveAsset(primitivePriceFeed_, _denominationAsset)
    with_attr error_message("initializeFund: denomination asset hags to be a supported primitive"):
        assert isupportedPriceFeed_ = 1
    end
    #VaultProxy init
    IVault.initializer(_vault, _fundName, _fundSymbol, assetManager_, _denominationAsset, _positionLimitAmount)
    #Set feeconfig for vault
    let entrance_fee = _feeConfig[0]
    let (is_entrance_fee_not_enabled) = __is_zero(entrance_fee)
    if is_entrance_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.ENTRANCE_FEE_ENABLED, 0)
    else:
        with_attr error_message("initializeFund: entrance fee must be between 0 and 10"):
            assert_le(entrance_fee, 10)
        end
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.ENTRANCE_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.ENTRANCE_FEE, entrance_fee)
    end

    let exit_fee = _feeConfig[1]
    let (is_exit_fee_not_enabled) = __is_zero(exit_fee)
    if is_exit_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.EXIT_FEE_ENABLED, 0)
    else:
        with_attr error_message("initializeFund: exit fee must be between 0 and 10"):
            assert_le(exit_fee, 10)
        end
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.EXIT_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.EXIT_FEE, exit_fee)
    end

    let performance_fee = _feeConfig[2]
    let (is_performance_fee_not_enabled) = __is_zero(performance_fee)
    if is_performance_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.PERFORMANCE_FEE_ENABLED, 0)
    else:
        with_attr error_message("initializeFund: performance fee must be between 0 and 20"):
            assert_le(performance_fee, 20)
        end
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.PERFORMANCE_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.PERFORMANCE_FEE, performance_fee)
    end

    let management_fee = _feeConfig[3]
    let (is_management_fee_not_enabled) = __is_zero(management_fee)
    if is_management_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.MANAGEMENT_FEE, 0)
    else:
        with_attr error_message("initializeFund: management fee must be between 0 and 20"):
            assert_le(management_fee, 20)
        end
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.MANAGEMENT_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _vault, FeeConfig.MANAGEMENT_FEE, management_fee)
        let (timestamp_:felt) = get_block_timestamp()
        IFeeManager.setClaimedTimestamp(feeManager_, _vault, timestamp_)
    end

    IPolicyManager.setMaxminAmount(policyManager_, _vault, _maxAmount, _minAmount)

    # Policy config for fund
    __addAllowedAsset(_assetList_len, _assetList, _vault, integrationManager_, policyManager_)
    __addAllowedIntegration(_integration_len, _integration, _vault, integrationManager_, policyManager_)
    IPolicyManager.setMaxminAmount(policyManager_, _vault, _maxAmount, _minAmount)
    IPolicyManager.setTimelock(policyManager_, _vault, _timelock)
    IPolicyManager.setIsPublic(policyManager_, _vault, _isPublic)
    return ()
end

func __is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x: felt)-> (res:felt):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end

func __addAllowedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*, _vault:felt, _integrationManager:felt, _policyManager:felt) -> ():
    alloc_locals
    if _assetList_len == 0:
        return ()
    end
    let asset_:felt = [_assetList]
    let (isAllowed_) = IIntegrationManager.checkIsAssetAvailable(_integrationManager, asset_)
    with_attr error_message("__addAllowedAsset: asset not supported by Magnety"):
        assert_not_zero(isAllowed_)
    end
    #allow track asset and already allow approve for any asset usecase (&&&&&& selector approve keccack)
    IPolicyManager.setAllowedIntegration(_policyManager, _vault, asset_, APPROVE_SELECTOR)
    IPolicyManager.setAllowedTrackedAsset(_policyManager, _vault, asset_)

    let newAssetList_len:felt = _assetList_len -1
    let newAssetList:felt* = _assetList + 1

    return __addAllowedAsset(
        _assetList_len= newAssetList_len,
        _assetList= newAssetList,
        _vault=_vault,
        _integrationManager=_integrationManager,
        _policyManager=_policyManager
    )
end

func __addAllowedIntegration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integration_len: felt, _integration: integration*, _vault:felt, _integrationManager:felt, _policyManager:felt) -> ():
    alloc_locals
    if _integration_len == 0:
        return ()
    end

    let integration_:integration = [_integration]
    let (isAllowed_) = IIntegrationManager.checkIsIntegrationAvailable(_integrationManager, integration_.contract, integration_.selector)
    with_attr error_message("__addAllowedAsset: integration not supported by Magnety"):
        assert_not_zero(isAllowed_)
    end

    #allow integration to be used 
    IPolicyManager.setAllowedIntegration(_policyManager, _vault, integration_.contract, integration_.selector)

    let newIntegration_len:felt = _integration_len -1
    let newIntegration:integration* = _integration + 1

    return __addAllowedIntegration(
        _integration_len= newIntegration_len,
        _integration= newIntegration,
        _vault=_vault,
        _integrationManager=_integrationManager,
        _policyManager=_policyManager
    )
end


func __addAllowedDepositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _depositors_len:felt, _depositors:felt*) -> ():
    alloc_locals
    if _depositors_len == 0:
        return ()
    end
    let (policyManager_:felt) = policyManager.read()
    let depositor_:felt = [_depositors]
    IPolicyManager.setAllowedDepositor(policyManager_, _vault, depositor_)

    let newDepositors_len:felt = _depositors_len -1
    let newDepositors:felt* = _depositors + 1

    return __addAllowedDepositors(
        _vault = _vault,
        _depositors_len= newDepositors_len,
        _depositors= newDepositors,
        )
end