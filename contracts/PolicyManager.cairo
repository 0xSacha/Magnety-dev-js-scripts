%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import (
    alloc,
)
struct MaxMin:
    member max: Uint256
    member min: Uint256
end

struct integration:
    member contract : felt
    member selector : felt
end

# Define a storage variable.
@storage_var
func vaultFactory() -> (vaultFactoryAddress : felt):
end

@storage_var
func maxminAmount(vault: felt) -> (res: MaxMin):
end

@storage_var
func timeLock(vault: felt) -> (res: felt):
end

@storage_var
func idToAllowedIntegration(vault: felt, id:felt) -> (res : integration):
end

@storage_var
func allowedIntegrationLength(vault: felt) -> (res : felt):
end

@storage_var
func isAllowedIntegration(vault: felt, integration_:integration) -> (res : felt):
end


@storage_var
func idToAllowedTrackedAsset(vault: felt, id:felt) -> (res : felt):
end

@storage_var
func allowedTrackedAssetLength(vault: felt) -> (res : felt):
end

@storage_var
func isAllowedTrackedAsset(_vault: felt,asset:felt) -> (res : felt):
end




@storage_var
func isPublic(vault: felt) -> (res : felt):
end

@storage_var
func isAllowedDepositor(vault: felt, depositor:felt) -> (res : felt):
end




#
# Modifiers
#

func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory: felt,
    ):
    vaultFactory.write(_vaultFactory)
    return ()
end




# Getters
@view
func getMaxminAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt) -> (
        max: Uint256, min: Uint256):
    let (res) = maxminAmount.read(_vault)
    return (max=res.max, min=res.min)
end

@view
func getTimelock{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt) -> (
        res:felt):
    let (res) = timeLock.read(_vault)
    return (res=res)
end

@view
func checkIsPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt) -> (
        res:felt):
    let (res) = isPublic.read(_vault)
    return (res=res)
end

@view
func checkIsAllowedTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt, _asset: felt) -> (res:felt):
    let (res) = isAllowedTrackedAsset.read(_vault, _asset)
    return (res=res)
end

@view
func checkIsAllowedIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt, _contract: felt, _selector: felt
        ) -> (res: felt): 
    let (res) = isAllowedIntegration.read(_vault, integration(_contract, _selector))
    return (res=res)
end

@view
func checkIsAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt, _depositor: felt,
        ) -> (res: felt): 
    let (res) = isAllowedDepositor.read(_vault, _depositor)
    return (res=res)
end

@view
func getAllowedTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault:felt) -> (allowedTrackedAsset_len: felt, allowedTrackedAsset:felt*): 
    alloc_locals
    let (allowedTrackedAsset_len:felt) = allowedTrackedAssetLength.read(_vault)
    let (local allowedTrackedAsset : felt*) = alloc()
    __completeAllowedTrackedAsset(_vault, allowedTrackedAsset_len, allowedTrackedAsset, 0)
    return(allowedTrackedAsset_len, allowedTrackedAsset)
end

func __completeAllowedTrackedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _allowedTrackedAsset_len:felt, _allowedTrackedAsset:felt*, index:felt) -> ():
    if _allowedTrackedAsset_len == 0:
        return ()
    end
    let (asset_:felt) = idToAllowedTrackedAsset.read(_vault, index)
    assert [_allowedTrackedAsset + index] = asset_

    let new_index_:felt = index + 1
    let newAllowedTrackedAsset_len:felt = _allowedTrackedAsset_len -1

    return __completeAllowedTrackedAsset(
        _vault = _vault,
        _allowedTrackedAsset_len=newAllowedTrackedAsset_len,
        _allowedTrackedAsset= _allowedTrackedAsset,
        index=new_index_,
    )
end

@view
func getAllowedIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault:felt) -> (allowedIntegration_len:felt, allowedIntegration: integration*): 
    alloc_locals
    let (allowedIntegration_len:felt) = allowedIntegrationLength.read(_vault)
    let (local allowedIntegration : integration*) = alloc()
    __completeAllowedIntegrationTab(_vault, allowedIntegration_len, allowedIntegration, 0)
    return(allowedIntegration_len, allowedIntegration)
end

func __completeAllowedIntegrationTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _allowedIntegration_len:felt, _allowedIntegration:integration*, index:felt) -> ():
    if _allowedIntegration_len == 0:
        return ()
    end
    let (integration_:integration) =  idToAllowedIntegration.read(_vault, index)
    assert [_allowedIntegration + index*2] = integration_

    let new_index_:felt = index + 1
    let newAllowedIntegration_len:felt = _allowedIntegration_len -1

    return __completeAllowedIntegrationTab(
        _vault = _vault,
        _allowedIntegration_len=newAllowedIntegration_len,
        _allowedIntegration= _allowedIntegration,
        index=new_index_,
    )
end




# Setters 
@external
func setMaxminAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _max: Uint256, _min:Uint256):
    onlyVaultFactory()
    maxminAmount.write(_vault, MaxMin(_max, _min))
    return ()
end

@external
func setAllowedIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _contract: felt, _selector: felt):
    onlyVaultFactory()
    isAllowedIntegration.write(_vault, integration(_contract, _selector), 1)
    let (currentAllowedIntegrationLength_:felt) = allowedIntegrationLength.read(_vault)
    idToAllowedIntegration.write(_vault, currentAllowedIntegrationLength_, integration(_contract, _selector))
    allowedIntegrationLength.write(_vault, currentAllowedIntegrationLength_ + 1)
    return ()
end

@external
func setAllowedTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _asset: felt):
    onlyVaultFactory()
    isAllowedTrackedAsset.write(_vault, _asset, 1)
    let (currentAllowedTrackedAssetLength_:felt) = allowedTrackedAssetLength.read(_vault)
    idToAllowedTrackedAsset.write(_vault, currentAllowedTrackedAssetLength_, _asset)
    allowedTrackedAssetLength.write(_vault, currentAllowedTrackedAssetLength_ + 1)
    return ()
end

@external
func setTimelock{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _block_timestamp: felt):
    onlyVaultFactory()
    timeLock.write(_vault, _block_timestamp)
    return ()
end

@external
func setIsPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _isPublic: felt):
    onlyVaultFactory()
    isPublic.write(_vault, _isPublic)
    return ()
end

@external
func setAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _depositor: felt):
    onlyVaultFactory()
    isAllowedDepositor.write(_vault, _depositor, 1)
    return ()
end
