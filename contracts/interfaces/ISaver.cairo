# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ISaver:
    func setNewMint(user:felt, _contractAddress: felt, _tokenId: Uint256):
    end

    func setNewBurn(user:felt, _contractAddress: felt, _tokenId: Uint256):
    end
end
