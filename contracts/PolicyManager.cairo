%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

struct MaxMin:
    member max: Uint256
    member min: Uint256
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
func isAllowedIntegration(vault: felt, contract_addr: felt, selector: felt) -> (res : felt):
end

@storage_var
func isAllowedTrackedAsset(vault: felt, asset: felt) -> (res : felt):
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
    let (res) = isAllowedIntegration.read(_vault, _contract, _selector)
    return (res=res)
end

@view
func checkIsAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt, _depositor: felt,
        ) -> (res: felt): 
    let (res) = isAllowedDepositor.read(_vault, _depositor)
    return (res=res)
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
    isAllowedIntegration.write(_vault, _contract, _selector, 1)
    return ()
end

@external
func setAllowedTrackedAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _asset: felt):
    onlyVaultFactory()
    isAllowedTrackedAsset.write(_vault, _asset, 1)
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
