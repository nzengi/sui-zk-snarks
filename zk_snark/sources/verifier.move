module zk_snark::verifier {
    use zk_snark::key_types::{Self, VerificationKey, Proof};
    use zk_snark::verifier_impl;

    public fun verify(
        vk: &VerificationKey,
        proof: &Proof,
        public_inputs: vector<vector<u8>>
    ): bool {
        verifier_impl::verify(vk, proof, public_inputs)
    }

    public fun create_proof(
        a: vector<u8>,
        b: vector<u8>,
        c: vector<u8>
    ): Proof {
        key_types::create_proof(a, b, c)
    }

    public fun is_key_valid(vk: &VerificationKey): bool {
        verifier_impl::is_key_valid(vk)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut sui::tx_context::TxContext) {
        verifier_impl::init_for_testing(ctx)
    }
} 