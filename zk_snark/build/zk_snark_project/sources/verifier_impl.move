module zk_snark::verifier_impl {
    use std::vector;
    friend zk_snark::verifier;
    friend zk_snark::admin_impl;

    struct VerificationKeyFields has store, copy {
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    }

    public(friend) fun create_fields(): VerificationKeyFields {
        VerificationKeyFields {
            alpha: vector::empty(),
            beta: vector::empty(),
            gamma: vector::empty(),
            delta: vector::empty(),
            ic: vector::empty()
        }
    }

    public(friend) fun update_fields(
        fields: &mut VerificationKeyFields,
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    ) {
        fields.alpha = alpha;
        fields.beta = beta;
        fields.gamma = gamma;
        fields.delta = delta;
        fields.ic = ic;
    }

    public(friend) fun disable_fields(fields: &mut VerificationKeyFields) {
        fields.alpha = vector::empty();
        fields.beta = vector::empty();
        fields.gamma = vector::empty();
        fields.delta = vector::empty();
        fields.ic = vector::empty();
    }

    public(friend) fun get_alpha(fields: &VerificationKeyFields): vector<u8> { fields.alpha }
    public(friend) fun get_beta(fields: &VerificationKeyFields): vector<u8> { fields.beta }
    public(friend) fun get_gamma(fields: &VerificationKeyFields): vector<u8> { fields.gamma }
    public(friend) fun get_delta(fields: &VerificationKeyFields): vector<u8> { fields.delta }
    public(friend) fun get_ic(fields: &VerificationKeyFields): vector<vector<u8>> { fields.ic }
} 