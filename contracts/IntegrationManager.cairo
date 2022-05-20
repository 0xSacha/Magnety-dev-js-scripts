# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.utils.constants import (
    TRUE, FALSE,
)

@storage_var
func vaultFactory(vaultFactoryAddress: felt) -> (res: felt):
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

@storage_var
func isPontisPricefeed(assetAddress: felt) -> (res: felt):
end

@storage_var
func primitive(assetAddress: felt) -> (res: felt):
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
func checkIsPontisPricefeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault: felt, contract_addr: felt, selector: felt
        ) -> (res: felt): 
    
    let (res) = allowed_integration.read(vault, contract_addr, selector)
    return (res=res)
end

@view
func checkIsAssetAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_asset: felt) -> (res: felt): 
    let (res) = isAssetAvailable.read(_asset)
    return (res=res)
end

@view
func checkIsIntegrationAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector: felt) -> (res: felt): 
    let (res) = isAssetAvailable.read(_asset)
    return (res=res)
end


#
# Setters
#

@external
func setIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contract_addr: felt, selector: felt, integration: felt):
    onlyVaultFactory()
    integrationContract.write(contract_addr, selector, integration)
    return ()
end

@external
func setPriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        assetAddress: felt, selector: felt, integration: felt):
    onlyVaultFactory()
    integrationContract.write(contract_addr, selector, integration)
    return ()
end

#
# Externals
#


@external
func set_integration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contract_addr: felt, selector: felt, integration: felt):
    # TODO - should insert authority validation
    allowed_integration.write(vault, contract_addr, selector, enable)
    return ()
end


