module zk_snark::admin_impl {
    use zk_snark::verifier::{Self, VerificationKey};
    
    public(friend) fun update_key_params(
        vk: &mut VerificationKey,
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    ) {
        verifier::update_key_params(vk, alpha, beta, gamma, delta, ic)
    }

    public(friend) fun disable_key(vk: &mut VerificationKey) {
        verifier::disable_key(vk)
    }
} 