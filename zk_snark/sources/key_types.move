module zk_snark::key_types {
    friend zk_snark::verifier_impl;
    
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use std::vector;

    // Structs are public by default
    struct VerificationKey has key {
        id: UID,
        fields: VerificationKeyFields
    }

    struct Proof has store, drop, copy {
        a: vector<u8>,
        b: vector<u8>,
        c: vector<u8>
    }

    // Internal structs
    struct VerificationKeyFields has store, copy {
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    }

    // Public functions
    public fun create_fields(): VerificationKeyFields {
        VerificationKeyFields {
            alpha: vector::empty(),
            beta: vector::empty(),
            gamma: vector::empty(),
            delta: vector::empty(),
            ic: vector::empty()
        }
    }

    public fun create_proof(
        a: vector<u8>,
        b: vector<u8>,
        c: vector<u8>
    ): Proof {
        Proof { a, b, c }
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

    // Getter functions
    public fun get_alpha(fields: &VerificationKeyFields): vector<u8> { fields.alpha }
    public fun get_beta(fields: &VerificationKeyFields): vector<u8> { fields.beta }
    public fun get_gamma(fields: &VerificationKeyFields): vector<u8> { fields.gamma }
    public fun get_delta(fields: &VerificationKeyFields): vector<u8> { fields.delta }
    public fun get_ic(fields: &VerificationKeyFields): vector<vector<u8>> { fields.ic }

    // Test helper function
    #[test_only]
    public fun create_verification_key(ctx: &mut TxContext): VerificationKey {
        VerificationKey {
            id: object::new(ctx),
            fields: create_fields()
        }
    }

    // Getter/setter functions
    public fun get_fields_mut(vk: &mut VerificationKey): &mut VerificationKeyFields {
        &mut vk.fields
    }

    #[test_only]
    public fun transfer_verification_key(vk: VerificationKey, recipient: address) {
        transfer::transfer(vk, recipient);
    }

    // Helper function for verifier_impl
    public(friend) fun check_key_validity(fields: &VerificationKeyFields): bool {
        !vector::is_empty(&fields.alpha) &&
        !vector::is_empty(&fields.beta) &&
        !vector::is_empty(&fields.gamma) &&
        !vector::is_empty(&fields.delta) &&
        !vector::is_empty(&fields.ic)
    }

    public fun get_fields(vk: &VerificationKey): &VerificationKeyFields {
        &vk.fields
    }

    // Proof getters
    public fun get_proof_a(proof: &Proof): &vector<u8> { &proof.a }
    public fun get_proof_b(proof: &Proof): &vector<u8> { &proof.b }
    public fun get_proof_c(proof: &Proof): &vector<u8> { &proof.c }
} 