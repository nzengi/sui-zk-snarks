module zk_snark::verifier {
    friend zk_snark::admin_impl;
    
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use std::vector;
    use zk_snark::crypto;
    use zk_snark::key_types::{Self, VerificationKeyFields};

    // Struct to store verification key
    struct VerificationKey has key {
        id: UID,
        fields: VerificationKeyFields
    }

    // Struct to store proof
    struct Proof has store, drop, copy {
        a: vector<u8>,
        b: vector<u8>,
        c: vector<u8>
    }

    // Events
    struct ProofVerified has copy, drop {
        proof_hash: vector<u8>,
        verified: bool,
        timestamp: u64
    }

    // Error codes - public fonksiyonlar aracılığıyla erişim sağlayacağız
    const E_INVALID_PROOF_LENGTH: u64 = 1;
    const E_INVALID_PUBLIC_INPUTS: u64 = 2;
    const E_INVALID_VERIFICATION_KEY: u64 = 3;
    const E_UNAUTHORIZED: u64 = 4;

    // Public functions to access error codes
    public fun error_invalid_proof_length(): u64 { E_INVALID_PROOF_LENGTH }
    public fun error_invalid_public_inputs(): u64 { E_INVALID_PUBLIC_INPUTS }
    public fun error_invalid_verification_key(): u64 { E_INVALID_VERIFICATION_KEY }
    public fun error_unauthorized(): u64 { E_UNAUTHORIZED }

    // Initialize verification key
    fun init(ctx: &mut TxContext) {
        let verification_key = VerificationKey {
            id: object::new(ctx),
            fields: key_types::create_fields()
        };
        transfer::transfer(verification_key, tx_context::sender(ctx));
    }

    // Core verification logic
    public fun verify(
        vk: &VerificationKey,
        proof: &Proof,
        public_inputs: vector<vector<u8>>
    ): bool {
        let fields = &vk.fields;
        let ic = key_types::get_ic(fields);
        let ic_len = vector::length(&ic);
        
        // 1. Input validation
        if (ic_len == 0 || vector::length(&public_inputs) != ic_len - 1) {
            return false
        };

        // 2. Compute linear combination of inputs
        let vk_x = compute_linear_combination(vk, &public_inputs);

        // 3. Perform pairing checks:
        // e(A, B) = e(α, β)
        // e(A*C, γ) = e(vk_x + proof.A + proof.C, δ)
        let valid = check_pairings(
            vk,
            proof,
            &vk_x
        );

        valid
    }

    fun compute_linear_combination(
        vk: &VerificationKey,
        inputs: &vector<vector<u8>>
    ): vector<u8> {
        let fields = &vk.fields;
        let ic = key_types::get_ic(fields);
        let result = *vector::borrow(&ic, 0);
        let i = 0;
        let len = vector::length(inputs);
        
        while (i < len) {
            let input = vector::borrow(inputs, i);
            let ic_element = vector::borrow(&ic, i + 1);
            let term = crypto::mul_g1_point(ic_element, input);
            result = crypto::add_g1_points(&result, &term);
            i = i + 1;
        };
        
        result
    }

    fun check_pairings(
        vk: &VerificationKey,
        proof: &Proof,
        vk_x: &vector<u8>
    ): bool {
        let fields = &vk.fields;
        // Check e(A, B) = e(α, β)
        let pairing1 = crypto::compute_pairing(&proof.a, &proof.b);
        let alpha = key_types::get_alpha(fields);
        let beta = key_types::get_beta(fields);
        let pairing2 = crypto::compute_pairing(&alpha, &beta);
        
        if (pairing1 != pairing2) {
            return false
        };

        // Check e(A*C, γ) = e(vk_x + proof.A + proof.C, δ)
        let ac = crypto::add_g1_points(&proof.a, &proof.c);
        let gamma = key_types::get_gamma(fields);
        let pairing3 = crypto::compute_pairing(&ac, &gamma);

        let vk_x_plus_a = crypto::add_g1_points(vk_x, &proof.a);
        let sum = crypto::add_g1_points(&vk_x_plus_a, &proof.c);
        let delta = key_types::get_delta(fields);
        let pairing4 = crypto::compute_pairing(&sum, &delta);

        pairing3 == pairing4
    }

    // Proof creation
    public fun create_proof(
        a: vector<u8>,
        b: vector<u8>,
        c: vector<u8>
    ): Proof {
        Proof { a, b, c }
    }

    // Event emission
    public fun emit_verification_event(
        proof: &Proof,
        verified: bool,
        ctx: &TxContext
    ) {
        let proof_hash = calculate_proof_hash(proof);
        event::emit(ProofVerified {
            proof_hash,
            verified,
            timestamp: tx_context::epoch(ctx)
        });
    }

    fun calculate_proof_hash(proof: &Proof): vector<u8> {
        // Basit hash implementasyonu
        proof.a
    }

    // Helper function to get IC length
    public fun get_ic_length(vk: &VerificationKey): u64 {
        let fields = &vk.fields;
        let ic = key_types::get_ic(fields);
        vector::length(&ic)
    }

    // Helper function to validate inputs length
    public fun validate_inputs_length(
        vk: &VerificationKey,
        public_inputs: &vector<vector<u8>>
    ): bool {
        let fields = &vk.fields;
        let ic = key_types::get_ic(fields);
        vector::length(public_inputs) == vector::length(&ic) - 1
    }

    // Update key parameters
    public(friend) fun update_key_params(
        vk: &mut VerificationKey,
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    ) {
        let fields = &mut vk.fields;
        key_types::update_fields(fields, alpha, beta, gamma, delta, ic)
    }

    // Disable verification key
    public(friend) fun disable_key(vk: &mut VerificationKey) {
        let fields = &mut vk.fields;
        key_types::disable_fields(fields)
    }

    // Check if verification key is valid
    public fun is_key_valid(vk: &VerificationKey): bool {
        let fields = &vk.fields;
        let alpha = key_types::get_alpha(fields);
        let beta = key_types::get_beta(fields);
        let gamma = key_types::get_gamma(fields);
        let delta = key_types::get_delta(fields);
        let ic = key_types::get_ic(fields);
        
        !vector::is_empty(&alpha) &&
        !vector::is_empty(&beta) &&
        !vector::is_empty(&gamma) &&
        !vector::is_empty(&delta) &&
        !vector::is_empty(&ic)
    }

    // Helper functions to access Proof fields
    public fun get_proof_a(proof: &Proof): vector<u8> {
        proof.a
    }

    public fun get_proof_b(proof: &Proof): vector<u8> {
        proof.b
    }

    public fun get_proof_c(proof: &Proof): vector<u8> {
        proof.c
    }

    public fun get_proof_points(proof: &Proof): (vector<u8>, vector<u8>, vector<u8>) {
        (proof.a, proof.b, proof.c)
    }

    #[test]
    fun test_verify() {
        use sui::test_scenario;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, admin);
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin);
        {
            let dummy_proof = create_proof(
                vector[1], vector[2], vector[3]
            );
            
            let public_inputs = vector::empty<vector<u8>>();
            vector::push_back(&mut public_inputs, vector[4]);
            
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            assert!(verify(&vk, &dummy_proof, public_inputs), 1);
            test_scenario::return_to_sender(scenario, vk);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}