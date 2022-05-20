# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.utils.constants import (
    TRUE, FALSE,
)

@storage_var
func vaultFactory() -> (res: felt):
end

@storage_var
func isAssetAvailable(assetAddress: felt) -> (res: felt):
end

@storage_var
func isIntegrationAvailable(contract: felt, selector: felt) -> (res: felt):
end

@storage_var
func integrationContract(contractAddress: felt, selector: felt) -> (res: felt):
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
func checkIsIntegrationAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector: felt) -> (res: felt): 
    let (res) = isIntegrationAvailable.read(_contract, _selector )
    return (res=res)
end

@view
func getIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector: felt) -> (res: felt): 
    let (res) = integrationContract.read(_contract, _selector)
    return (res=res)
end


#
# Setters
#

@external
func setAvailableAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _asset: felt):
    onlyVaultFactory()
    isAssetAvailable.write(_asset, 1)
    return ()
end

@external
func setAvailableIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _contract: felt, _selector: felt, _integration: felt):
    onlyVaultFactory()
    isIntegrationAvailable.write(_contract, _selector, 1)
    integrationContract.write(_contract, _selector, _integration)
    return ()
end
