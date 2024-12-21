module zk_snark::admin_impl {
    friend zk_snark::admin;
    
    use zk_snark::key_types::VerificationKey;
    use zk_snark::verifier_impl;

    public(friend) fun update_key_params(
        vk: &mut VerificationKey,
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    ) {
        verifier_impl::update_key_params(vk, alpha, beta, gamma, delta, ic)
    }

    public(friend) fun disable_key(vk: &mut VerificationKey) {
        verifier_impl::disable_key(vk)
    }
} 