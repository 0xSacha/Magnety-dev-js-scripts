%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address, 
)

from contracts.interface.IFeeManager import FeeConfig, IFeeManager

from starkware.cairo.common.math import (
    assert_not_zero,
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

from contracts.interface.IVault import IVault

from contracts.interface.IComptroller import IComptroller


struct ComptrollerList:
    member comptroller_cnt: felt
    member comptroller_list: felt*
end
#
# Events
#


struct VaultFactoryEvents:
   member FUND_CREATED: felt 
end

@event
func VaultLibSet(vaultLibAddress: felt):
end

@event
func ComptrollerLibSet(comptrollerLibAddress: felt):
end

@event
func FeeManagerSet(feeManagerAddress: felt):
end

@event
func DeployComptrollerProxy(comptrollerLibAddress: felt):
end

@event
func DeployVaultProxy(event_type: felt, asset_manager: felt):
end

#maybe allowed tracked asset as bool mapping since we need pricefeed for each asset we track

#
# Storage
#


@storage_var
func latest_comptroller_version() -> (res : felt):
end


@storage_var
func comptroller_address(version: felt) -> (res : felt):
end


@storage_var
func comptrollerLib() -> (comptrollerLibAddress: felt):
end

@storage_var
func vaultLib() -> (vaultLibAddress: felt):
end

@storage_var
func FeeManager() -> (FeeManagerAddress: felt):
end


# Define a storage variable.
@storage_var
func vault_comptroller(vault:felt) -> (res : felt):
end


@view
func get_latest_comptroller_version{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (version: felt, address: felt): 
    let (version) = latest_comptroller_version.read()
    let (comptroller) = comptroller_address.read(version)
    return (version=version, address=comptroller)
end


@external
func add_comptroller_version{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        comptroller: felt):
    
    let (cnt) = latest_comptroller_version.read()
    let new_cnt = cnt + 1
    latest_comptroller_version.write(new_cnt)
    comptroller_address.write(new_cnt, comptroller)

    return ()
end




# set the balance by the given amount.
@external
func set_vault_comptroller{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        vault : felt, comptroller_address: felt):
    vault_comptroller.write(vault, comptroller_address)
    return ()
end

# Returns the current comptrollerAddress
@view
func get_vault_comptroller{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(     vault : felt) -> (comptroller: felt):
    let (comptroller) = vault_comptroller.read(vault)
    return (comptroller=comptroller)
end

#
# Getters 
#

@view
func getComptrollerLib{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = comptrollerLib.read()
    return(res)
end

@view
func getVaultLib{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = vaultLib.read()
    return(res)
end

@view
func getFeeManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = FeeManager.read()
    return(res)
end



#
# Setters
#

@external
func setComptrollerLib{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _comptrolleurLib: felt,
    ):
    let (comptrollerLib_:felt) = comptrollerLib.read()
    with_attr error_message("setComptrollerLib: can only be set once"):
        assert comptrollerLib_ = 0
    end
    comptrollerLib.write(_comptrolleurLib)
    return ()
end

@external
func setVaultLib{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _vaultLib: felt,
    ):
    let (vaultLib_:felt) = vaultLib.read()
    with_attr error_message("setVaultLib: can only be set once"):
        assert vaultLib_ = 0
    end
    comptrollerLib.write(_vaultLib)
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
    let (feeManager_:felt) = FeeManager.read()
    with_attr error_message("setFeeManager: can only be set once"):
        assert feeManager_ = 0
    end
    FeeManager.write(_feeManager)
    return ()
end


#
# Create new Fund
#

@external
func createNewFund{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
    _fundName: felt,
    _fundSymbol:felt,
    _denominationAsset: felt,
    ):
    let (feeManager_:felt) = FeeManager.read()
    let (vaultLib_:felt) = vaultLib.read()
    let (comptrollerLib_:felt) = comptrollerLib.read()
   
    # with_attr error_message("createNewFund: dependencies not set"):
    #     assert_not_zero(feeManager_ * vaultLib_ * comptrollerLib_)
    # end

    let (assetManager_: felt) = get_caller_address()
    #TODO check allowed denomination asset (do we have a pricefeed for it)
    
    #first deploy comptroller proxy, put the address to delegate call (comptrolleurLib).
    # DeployComptrollerProxy.emit(comptrollerLib_)
    
    #second deploy vault proxy, put the address to delegate call (vaultLib).
    # TODO - consider choosing comptroller version
    DeployVaultProxy.emit(event_type=VaultFactoryEvents.FUND_CREATED, asset_manager=assetManager_)

    #Then invoke proxy initialize function and setup fund config for fee manager 
    #Since we are deploying comptrolleur & vault offchain, we can't access the address contract directly, so the function bellow will be called 
    return ()
end

@external
func initializeFund{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
    #initializer Arg for comptroller(look Icomptroller)
    _vaultProxy: felt,
    _denominationAsset:felt,
    _assetManager:felt,

    #initializer Arg for comptroller(look Icomptroller)
    _comptrollerProxy:felt,
    _fundName:felt,
    _fundSymbol:felt,
    _positionLimitAmount:Uint256,

    #tab with entrance fee, exit fees performance fees and management fees value
    # _feeConfig: felt*,
    ):
    let (feeManager_:felt) = FeeManager.read()
    let (vaultLib_:felt) = vaultLib.read()
    let (comptrollerLib_:felt) = comptrollerLib.read()
    with_attr error_message("createNewFund: dependencies not set"):
        assert_not_zero(feeManager_ * vaultLib_ * comptrollerLib_)
    end

    #TODO check allowed denomination asset (do we have a pricefeed for it)

    # IVault.proxyInitializer(_fundName, _fundSymbol, _comptrollerProxy, _positionLimitAmount)

    # IComptroller.proxyInitializer(_denominationAsset, _assetManager, _vaultProxy)

    #TODO initalize feeManager config for this fund
    return ()
end

