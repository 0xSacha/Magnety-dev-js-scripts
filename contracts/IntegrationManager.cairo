# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import (
    alloc,
)
from openzeppelin.utils.constants import (
    TRUE, FALSE,
)

struct integration:
    member contract : felt
    member selector : felt
end

@storage_var
func vaultFactory() -> (res: felt):
end

@storage_var
func assetAvailableLength() -> (res: felt):
end

@storage_var
func integrationAvailableLength() -> (res: felt):
end

@storage_var
func idToAssetAvailable(id: felt) -> (res: felt):
end

@storage_var
func idToIntegrationAvailable(id: felt) -> (res: integration):
end


@storage_var
func isAssetAvailable(assetAddress: felt) -> (res: felt):
end

@storage_var
func isIntegrationAvailable(_integration: integration) -> (res: felt):
end

@storage_var
func integrationContract(_integration: integration) -> (res: felt):
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

#
# Getters
#



@view
func checkIsAssetAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_asset: felt) -> (res: felt): 
    let (res) = isAssetAvailable.read(_asset)
    return (res=res)
end

@view
func checkIsIntegrationAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector:felt) -> (res: felt): 
    let (res) = isIntegrationAvailable.read(integration(_contract, _selector))
    return (res=res)
end

@view
func getIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector:felt) -> (res: felt): 
    let (res) = integrationContract.read(integration(_contract, _selector))
    return (res=res)
end

@view
func getAvailableAssets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableAssets_len: felt, availableAssets:felt*): 
    alloc_locals
    let (availableAssets_len:felt) = assetAvailableLength.read()
    let (local availableAssets : felt*) = alloc()
    __completeAssetTab(availableAssets_len, availableAssets, 0)
    return(availableAssets_len, availableAssets)
end

func __completeAssetTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_availableAssets_len:felt, _availableAssets:felt*, index:felt) -> ():
    if _availableAssets_len == 0:
        return ()
    end
    let (asset_:felt) = idToAssetAvailable.read(index)
    assert [_availableAssets + index] = asset_

    let new_index_:felt = index + 1
    let newAvailableAssets_len:felt = _availableAssets_len -1

    return __completeAssetTab(
        _availableAssets_len=newAvailableAssets_len,
        _availableAssets= _availableAssets,
        index=new_index_,
    )
end

@view
func getAvailableIntegrations{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableIntegrations_len:felt, availableIntegrations: integration*): 
    alloc_locals
    let (availableIntegrations_len:felt) = integrationAvailableLength.read()
    let (local availableIntegrations : integration*) = alloc()
    __completeIntegrationTab(availableIntegrations_len, availableIntegrations, 0)
    return(availableIntegrations_len, availableIntegrations)
end

func __completeIntegrationTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_availableIntegrations_len:felt, _availableIntegrations:integration*, index:felt) -> ():
    if _availableIntegrations_len == 0:
        return ()
    end

    let (integration_:integration) = idToIntegrationAvailable.read(index)
    assert [_availableIntegrations + index*2] = integration_

    let new_index_:felt = index + 1
    let newAvailableIntegrations_len:felt = _availableIntegrations_len -1

    return __completeIntegrationTab(
        _availableIntegrations_len=newAvailableIntegrations_len,
        _availableIntegrations= _availableIntegrations,
        index=new_index_,
    )
end


#
# Setters
#

@external
func setAvailableAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _asset: felt):
    onlyVaultFactory()
    isAssetAvailable.write(_asset, 1)
    let (currentAssetAvailableLength_:felt) = assetAvailableLength.read()
    idToAssetAvailable.write(currentAssetAvailableLength_, _asset)
    assetAvailableLength.write(currentAssetAvailableLength_ + 1)
    return ()
end

@external
func setAvailableIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _contract: felt, _selector: felt, _integration: felt):
    onlyVaultFactory()
    isIntegrationAvailable.write(integration(_contract, _selector), 1)
    integrationContract.write(integration(_contract, _selector), _integration)
    let (currentIntegrationAvailableLength_:felt) = integrationAvailableLength.read()
    idToIntegrationAvailable.write(currentIntegrationAvailableLength_, integration(_contract, _selector))
    integrationAvailableLength.write(currentIntegrationAvailableLength_ + 1)
    return ()
end
