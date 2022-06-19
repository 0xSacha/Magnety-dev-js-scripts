%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address, get_contract_address, get_block_timestamp
)
from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow


from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
)


from starkware.cairo.common.alloc import (
    alloc,
)

from starkware.cairo.common.find_element import (
    find_element,
)


from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)



from openzeppelin.security.safemath import (
    uint256_checked_add,
    uint256_checked_sub_le,
)

from contracts.interfaces.IVault import IVault

from contracts.interfaces.IComptroller import IComptroller

from contracts.interfaces.IFeeManager import IFeeManager, FeeConfig

from contracts.interfaces.IPolicyManager import IPolicyManager

from contracts.interfaces.IIntegrationManager import IIntegrationManager

from contracts.interfaces.IPontisPriceFeedMixin import IPontisPriceFeedMixin

from contracts.interfaces.IERC20 import IERC20


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

const POW18 = 1000000000000000000

const POW20 = 100000000000000000000

struct ShareInfo:
    member contract: felt
    member tokenId: Uint256
end

struct integration:
    member contract : felt
    member selector : felt
    member integration: felt
end
#
# Storage
#
@storage_var
func owner() -> (res: felt):
end

@storage_var
func nominatedOwner() -> (res: felt):
end

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
func assetManagerVaultAmount(assetManager: felt) -> (res: felt):
end

@storage_var
func assetManagerVault(assetManager: felt, vaultId: felt) -> (res: felt):
end

@storage_var
func vaultAmount() -> (res: felt):
end

@storage_var
func idToVault(id: felt) -> (res: felt):
end

@storage_var
func stackingVault() -> (res : felt):
end

@storage_var
func daoTreasury() -> (res : felt):
end


@storage_var
func userShareAmount(user:felt) -> (res: felt):
end

@storage_var
func idToShareInfo(user:felt ,id: felt) -> (res: ShareInfo):
end

@storage_var
func shareInfoToId(share:ShareInfo) -> (id: felt):
end



#
# Modifier 
#

func onlyOwner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (owner_) = owner.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyOwner: only callable by the owner"):
        assert caller_ = owner_
    end
    return ()
end

func onlyDependenciesSet{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (areDependenciesSet_:felt) = areDependenciesSet()
    with_attr error_message("onlyDependenciesSet:Dependencies not set"):
        assert areDependenciesSet_ = 1
    end
    return ()
end

func onlyAssetManager{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(_vault:felt):
    let (caller_:felt) = get_caller_address()
    let (assetManager_:felt) = IVault.getAssetManager(_vault)
    with_attr error_message("addAllowedDepositors: caller is not asset manager"):
        assert caller_ = assetManager_
    end
    return ()
end


    


#
# Getters 
#

@view
func areDependenciesSet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    alloc_locals
    let (comptroller_:felt) = getComptroller()
    let (oracle_:felt) = getOracle()
    let (feeManager_:felt) = getFeeManager()
    let (policyManager_:felt) = getPolicyManager()
    let (integrationManager_:felt) = getIntegrationManager()
    let (valueInterpretor_:felt) = getValueInterpretor()
    let (primitivePriceFeed_:felt) = getPrimitivePriceFeed()
    let  mul_:felt = comptroller_ * oracle_ * feeManager_ * policyManager_ * integrationManager_ * valueInterpretor_ * primitivePriceFeed_
    let (isZero_:felt) = __is_zero(mul_)
    if isZero_ == 1:
        return (res = 0)
    else:
        return (res = 1)
    end
end

@view
func getOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = owner.read()
    return(res)
end

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
func getDaoTreasury{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = daoTreasury.read()
    return(res)
end

@view
func getStackingVault{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = stackingVault.read()
    return(res)
end



#get Share info, helper to fetch info for the frontend, to be removed once tracker is implemented

@view
func getUserShareAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user: felt) -> (
        amount:felt):
    let (amount) = userShareAmount.read(_user)
    return (amount)
end


@view
func getUserShareInfo{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user: felt, id: felt) -> (
        info:ShareInfo):
    let (info_:ShareInfo) = idToShareInfo.read(_user, id)
    return (info=info_)
end


#get Vault info helper to fetch info for the frontend, to be removed once tracker is implemented

@view
func getUserVaultAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user:felt) -> (res: felt):
    let(res:felt) = assetManagerVaultAmount.read(_user)
    return (res=res)
end


@view
func getUserVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user:felt, _vaultId: felt) -> (res: felt):
    let(res:felt) = assetManagerVault.read(_user, _vaultId)
    with_attr error_message("getVaultAddressFromCallerAndId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end

@view
func getVaultAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = vaultAmount.read()
    return (res=res)
end


@view
func getVaultFromId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vaultId: felt) -> (res: felt):
    let(res:felt) = idToVault.read(_vaultId)
    with_attr error_message("getVaultAddressFromId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end


#
# Setters
#

@external
func claimOwnership{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }():
    let (caller_:felt) = get_caller_address()
    let (nominatedOwner_:felt) = nominatedOwner.read()
    let (currentOwner_:felt) = owner.read()
    if currentOwner_ == 0:
        owner.write(caller_)
        return ()
    else:
        with_attr error_message("claimOwnership: you are not the nominated owner"):
        assert caller_ = nominatedOwner_
        end
        owner.write(caller_)
        return ()
    end
end

@external
func setNewOwner{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(_nominatedOwner:felt):
    onlyOwner()
    nominatedOwner.write(_nominatedOwner)
    return ()
end


#owner
@external
func setComptroller{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _comptrolleur: felt,
    ):
    onlyOwner()
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
    onlyOwner()
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
    onlyOwner()
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
    onlyOwner()
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
    onlyOwner()
    integrationManager.write(_integrationManager)
    return ()
end

@external
func setValueInterpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _valueInterpretor : felt):
    onlyOwner()
    valueInterpretor.write(_valueInterpretor)
    return ()
end

@external
func setPrimitivePriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _primitivePriceFeed : felt):
    onlyOwner()
    primitivePriceFeed.write(_primitivePriceFeed)
    return ()
end


@external
func setStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _stackingVault : felt):
    onlyOwner()
    stackingVault.write(_stackingVault)
    return ()
end

@external
func setDaoTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _daoTreasury : felt):
    onlyOwner()
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
    onlyOwner()
    onlyDependenciesSet()
    let (integrationManager_:felt) = integrationManager.read()
    __addGlobalAllowedAsset(_assetList_len, _assetList, integrationManager_)
    return ()
end

@external
func addGlobalAllowedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*) -> ():
    alloc_locals
    onlyOwner()
    onlyDependenciesSet()
    let (integrationManager_:felt) = integrationManager.read()
    __addGlobalAllowedExternalPosition(_externalPositionList_len, _externalPositionList, integrationManager_)
    return ()
end

@external
func addGlobalAllowedIntegration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integrationList_len:felt, _integrationList:integration*) -> ():
    alloc_locals
    onlyOwner()
    onlyDependenciesSet()
    let (integrationManager_:felt) = integrationManager.read()
    __addGlobalAllowedIntegration(_integrationList_len, _integrationList, integrationManager_)
    return()
end



#asset manager

@external
func addAllowedDepositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _depositors_len:felt, _depositors:felt*) -> ():
    alloc_locals
    onlyAssetManager(_vault)
    let (policyManager_:felt) = policyManager.read()
    let (isPublic_:felt) = IPolicyManager.checkIsPublic(policyManager_, _vault)
    with_attr error_message("addAllowedDepositors: the fund is already public"):
        assert isPublic_ = 0
    end
   __addAllowedDepositors(_vault, _depositors_len, _depositors)
    return ()
end


#both next functions will be changed later, all policies/integrations change will have to be requested before the execution. Just usefull for testnet usage, for funds to add new available assets/integrations
@external
func addAllowedTrackedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _trackedAsset_len: felt, _trackedAsset: felt*) -> ():
    alloc_locals
    onlyAssetManager(_vault)
    let (policyManager_:felt) = policyManager.read()
    let (integrationManager_:felt) = integrationManager.read()
    __addAllowedAsset(_trackedAsset_len, _trackedAsset, _vault, integrationManager_, policyManager_)
    return()
end

@external
func addAllowedIntegration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _integration_len: felt, _integration: integration*) -> ():
    alloc_locals
    onlyAssetManager(_vault)
    let (policyManager_:felt) = policyManager.read()
    let (integrationManager_:felt) = integrationManager.read()
    __addAllowedIntegration(_integration_len, _integration, _vault, integrationManager_, policyManager_)
    return()
end


#comptroller, to be removed once tracker up
@external
func setNewMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _caller:felt, _tokenId:Uint256):
    let (caller_:felt) = get_caller_address()
    let (comptroller_:felt) = comptroller.read()
    with_attr error_message("setNewMint: not allowed caller"):
        assert caller_  = comptroller_
    end
    let (currentCallerShareAmount_:felt) = userShareAmount.read(_caller)
    idToShareInfo.write(_caller, currentCallerShareAmount_, ShareInfo(_vault, _tokenId))
    shareInfoToId.write(ShareInfo(_vault, _tokenId), currentCallerShareAmount_)
    userShareAmount.write(_caller, currentCallerShareAmount_ + 1)
    return ()
end

@external
func setNewBurn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _caller:felt, _tokenId:Uint256):
    let (caller_:felt) = get_caller_address()
    let (comptroller_:felt) = comptroller.read()
    with_attr error_message("setNewMint: not allowed caller"):
        assert caller_ = comptroller_
    end

    let (currentCallerShareAmount_:felt) = userShareAmount.read(_caller)
    let (ShareInfoLast:ShareInfo) = idToShareInfo.read(_caller, currentCallerShareAmount_ - 1)
    idToShareInfo.write(_caller, currentCallerShareAmount_ - 1, ShareInfo(0,Uint256(0,0)))
    
    let (shareId_:felt) = shareInfoToId.read(ShareInfo(_vault, _tokenId)) 
    idToShareInfo.write(_caller, shareId_, ShareInfoLast)
    shareInfoToId.write(ShareInfoLast, shareId_)
    shareInfoToId.write(ShareInfo(_vault, _tokenId), 0)
    userShareAmount.write(_caller, currentCallerShareAmount_ - 1)
    return ()
end




# Initialize a vault freshly deployed. We are not using factory contract because for beta version the user will first deploy an account/Fund  and then initialize it
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
    _amount: Uint256,
    _shareAmount: Uint256,
    
    #fee config Initializer
    _feeConfig_len: felt,
    _feeConfig: felt*,

    #allowed asset to be tracked
    _assetList_len: felt,
    _assetList: felt*,

    #allowed external position to be tracked
    _externalPositionList_len: felt,
    _externalPositionList: felt*,

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

    onlyDependenciesSet()
    let (comptroller_:felt) = comptroller.read()
    let (feeManager_:felt) = feeManager.read()
    let (policyManager_:felt) = policyManager.read()
    let (integrationManager_:felt) = integrationManager.read()
    let (primitivePriceFeed_:felt) = primitivePriceFeed.read()

    let (name_:felt) = IVault.getName(_vault)
    with_attr error_message("initializeFund: vault already initialized"):
        assert name_ = 0
    end

    with_attr error_message("initializeFund: can not set value to 0"):
        assert_not_zero(_vault * _fundName * _fundSymbol * _denominationAsset)
    end

    let (assetManager_: felt) = get_caller_address()
    let (allowDeno_: felt*) = alloc()
    assert [allowDeno_] = _denominationAsset
    __addAllowedAsset(1, allowDeno_, _vault, integrationManager_, policyManager_)
    #VaultProxy init
    IVault.initializer(_vault, _fundName, _fundSymbol, assetManager_, _denominationAsset, _positionLimitAmount)

    #check allowed amount, min amount > decimal/1000 & share amount in [1, 100]
    let (decimals_:felt) = IERC20.decimals(_denominationAsset)
    let (minInitialAmount_:Uint256) = uint256_pow(Uint256(10,0), decimals_ - 3)
    let (allowedAmount_:felt) = uint256_le(minInitialAmount_, _amount) 
    let (allowedShareAmount1_:felt) = uint256_le(_shareAmount, Uint256(POW20,0))
    let (allowedShareAmount2_:felt) = uint256_le(Uint256(POW18,0), _shareAmount)
    with_attr error_message("initializeFund: not allowed Amount"):
        assert allowedAmount_ *  allowedShareAmount1_ * allowedShareAmount2_= 1
    end

    #save vault to be removed once tracker live
    let (currentAssetManagerVaultAmount_: felt) = assetManagerVaultAmount.read(assetManager_)
    assetManagerVault.write(assetManager_, currentAssetManagerVaultAmount_, _vault)
    assetManagerVaultAmount.write(assetManager_, currentAssetManagerVaultAmount_ + 1)
    let (currentVaultAmount:felt) = vaultAmount.read()
    vaultAmount.write(currentVaultAmount + 1)
    idToVault.write(currentVaultAmount, _vault)

    #save shares to be removed once tracker live
    let (tokenId_:Uint256) = IVault.getTotalSupply(_vault)
    __setNewMintFromSelf(_vault, assetManager_ ,tokenId_)

    # shares have 18 decimals
    let (amountPow18_:Uint256, _) = uint256_mul(_amount, Uint256(POW18,0))
    let (sharePricePurchased_:Uint256) = uint256_div(amountPow18_ , _shareAmount)
    IComptroller.mintFromVF(comptroller_,_vault, assetManager_, _shareAmount, sharePricePurchased_)
    IERC20.transferFrom(_denominationAsset, assetManager_, _vault, _amount)
    
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
    __addAllowedExternalPosition(_externalPositionList_len, _externalPositionList, _vault, integrationManager_, policyManager_)
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





func __addGlobalAllowedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*, _integrationManager:felt) -> ():
    alloc_locals
    onlyOwner()
    if _assetList_len == 0:
        return ()
    end
    let asset_:felt = [_assetList]
    IIntegrationManager.setAvailableAsset(_integrationManager, asset_)
    IIntegrationManager.setAvailableIntegration(_integrationManager, asset_, APPROVE_SELECTOR, 0)

    let newAssetList_len:felt = _assetList_len -1
    let newAssetList:felt* = _assetList + 1

    return __addGlobalAllowedAsset(
        _assetList_len= newAssetList_len,
        _assetList= newAssetList,
        _integrationManager= _integrationManager
        )
end

func __addGlobalAllowedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*, _integrationManager:felt) -> ():
    alloc_locals
    onlyOwner()
    if _externalPositionList_len == 0:
        return ()
    end
    let externalPosition_:felt = [_externalPositionList]
    IIntegrationManager.setAvailableExternalPosition(_integrationManager, externalPosition_)

    let newExternalPositionList_len:felt = _externalPositionList_len -1
    let newExternalPositionList:felt* = _externalPositionList + 1

    return __addGlobalAllowedExternalPosition(
        _externalPositionList_len= newExternalPositionList_len,
        _externalPositionList= newExternalPositionList,
        _integrationManager= _integrationManager
        )
end

func __addGlobalAllowedIntegration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integrationList_len:felt, _integrationList:integration*, _integrationManager:felt) -> ():
    alloc_locals
    if _integrationList_len == 0:
        return ()
    end

    let integration_:integration = [_integrationList]
    IIntegrationManager.setAvailableIntegration(_integrationManager, integration_.contract, integration_.selector, integration_.integration)

    let newIntegrationList_len:felt = _integrationList_len -1
    let newIntegrationList:integration* = _integrationList + 3

    return __addGlobalAllowedIntegration(
        _integrationList_len= newIntegrationList_len,
        _integrationList= newIntegrationList,
        _integrationManager=_integrationManager
        )
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

func __addAllowedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*, _vault:felt, _integrationManager:felt, _policyManager:felt) -> ():
    alloc_locals
    if _externalPositionList_len == 0:
        return ()
    end
    let externalPosition_:felt = [_externalPositionList]
    let (isAllowed_) = IIntegrationManager.checkIsExternalPositionAvailable(_integrationManager, externalPosition_)
    with_attr error_message("__addAllowedexternalPosition: externalPosition not supported by Magnety"):
        assert_not_zero(isAllowed_)
    end
    #allow track externalPosition and already allow approve for any externalPosition usecase (&&&&&& selector approve keccack)
    IPolicyManager.setAllowedTrackedExternalPosition(_policyManager, _vault, externalPosition_)

    let newExternalPositionList_len:felt = _externalPositionList_len -1
    let newExternalPositionList:felt* = _externalPositionList + 1

    return __addAllowedExternalPosition(
        _externalPositionList_len= newExternalPositionList_len,
        _externalPositionList= newExternalPositionList,
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
    let newIntegration:integration* = _integration + 3

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

#to be removed once tracker up

func __setNewMintFromSelf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _caller:felt, _tokenId:Uint256):
    let (currentCallerShareAmount_:felt) = userShareAmount.read(_caller)
    idToShareInfo.write(_caller, currentCallerShareAmount_, ShareInfo(_vault, _tokenId))
    shareInfoToId.write(ShareInfo(_vault, _tokenId), currentCallerShareAmount_)
    userShareAmount.write(_caller, currentCallerShareAmount_ + 1)
    return ()
end