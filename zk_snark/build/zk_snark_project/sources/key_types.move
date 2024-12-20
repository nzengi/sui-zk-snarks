module zk_snark::key_types {
    use std::vector;

    struct VerificationKeyFields has store, copy {
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    }

    public fun create_fields(): VerificationKeyFields {
        VerificationKeyFields {
            alpha: vector::empty(),
            beta: vector::empty(),
            gamma: vector::empty(),
            delta: vector::empty(),
            ic: vector::empty()
        }
    }

    public fun update_fields(
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

    public fun disable_fields(fields: &mut VerificationKeyFields) {
        fields.alpha = vector::empty();
        fields.beta = vector::empty();
        fields.gamma = vector::empty();
        fields.delta = vector::empty();
        fields.ic = vector::empty();
    }

    public fun get_alpha(fields: &VerificationKeyFields): vector<u8> { fields.alpha }
    public fun get_beta(fields: &VerificationKeyFields): vector<u8> { fields.beta }
    public fun get_gamma(fields: &VerificationKeyFields): vector<u8> { fields.gamma }
    public fun get_delta(fields: &VerificationKeyFields): vector<u8> { fields.delta }
    public fun get_ic(fields: &VerificationKeyFields): vector<vector<u8>> { fields.ic }
} 