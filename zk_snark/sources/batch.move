module zk_snark::batch {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use std::vector;
    use zk_snark::key_types::{VerificationKey, Proof};
    use zk_snark::verifier;

    // Constants
    const MAX_BATCH_SIZE: u64 = 10;
    const E_BATCH_TOO_LARGE: u64 = 1;
    const VERIFICATION_FEE: u64 = 1_000_000; // 0.001 SUI

    // Public functions to access constants
    public fun get_max_batch_size(): u64 { MAX_BATCH_SIZE }
    public fun error_batch_too_large(): u64 { E_BATCH_TOO_LARGE }

    // Entry function için BatchProof'u Object yapalım
    struct BatchProof has key, store {
        id: UID,
        proofs: vector<Proof>,
        public_inputs: vector<vector<vector<u8>>>,
        start_time: u64
    }

    public fun verify_batch(
        vk: &VerificationKey,
        batch: &BatchProof,
        _ctx: &TxContext  // Unused parameter prefixed with _
    ): bool {
        let batch_size = vector::length(&batch.proofs);
        assert!(batch_size <= MAX_BATCH_SIZE, E_BATCH_TOO_LARGE);

        let result = true;
        let i = 0;
        while (i < batch_size) {
            let proof = vector::borrow(&batch.proofs, i);
            let inputs = vector::borrow(&batch.public_inputs, i);
            if (!verifier::verify(vk, proof, *inputs)) {
                result = false;
                break
            };
            i = i + 1;
        };
        result
    }

    // Add proof to batch - return bool for success/failure
    public fun add_to_batch(
        batch: &mut BatchProof,
        proof: &Proof,
        public_input: vector<vector<u8>>
    ): bool {
        if (vector::length(&batch.proofs) >= MAX_BATCH_SIZE) {
            false
        } else {
            vector::push_back(&mut batch.proofs, *proof);
            vector::push_back(&mut batch.public_inputs, public_input);
            true
        }
    }

    // Memory optimizasyonu için batch oluşturma
    public fun create_batch(
        ctx: &mut TxContext
    ): BatchProof {
        BatchProof {
            id: object::new(ctx),
            proofs: vector::empty(),
            public_inputs: vector::empty(),
            start_time: tx_context::epoch(ctx)
        }
    }

    // Get batch size
    public fun get_batch_size(batch: &BatchProof): u64 {
        vector::length(&batch.proofs)
    }

    // Calculate batch verification fee
    public fun calculate_batch_fee(batch_size: u64): u64 {
        VERIFICATION_FEE * batch_size  // Basit fee hesaplama
    }

    // Verify batch with fee
    public entry fun verify_batch_with_fee(
        batch: &mut BatchProof,
        vk: &VerificationKey,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let batch_size = get_batch_size(batch);
        let fee = VERIFICATION_FEE * batch_size;
        
        // Check payment
        assert!(coin::value(payment) >= fee, 1);

        // Verify batch
        let verified = verify_batch(vk, batch, ctx);

        // Take fee if verified
        if (verified) {
            let fee_coin = coin::split(payment, fee, ctx);
            transfer::public_transfer(fee_coin, tx_context::sender(ctx));
        };
    }

    #[test]
    fun test_batch_operations() {
        use sui::test_scenario;
        use zk_snark::verifier;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        // Initialize verifier first
        test_scenario::next_tx(scenario, admin);
        {
            verifier::init_for_testing(test_scenario::ctx(scenario));
        };

        // Create and test batch
        test_scenario::next_tx(scenario, admin);
        {
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            let batch = create_batch(test_scenario::ctx(scenario));
            
            // Add first proof
            let proof1 = verifier::create_proof(
                vector[1u8], vector[2u8], vector[3u8]
            );
            let public_input1 = vector[vector[4u8]];
            assert!(add_to_batch(&mut batch, &proof1, public_input1), 1);
            
            // Add more proofs until max
            let mut_i = 0;
            while (mut_i < MAX_BATCH_SIZE - 1) {  // -1 because we already added one
                let proof = verifier::create_proof(
                    vector[1u8], vector[2u8], vector[3u8]
                );
                let public_input = vector[vector[4u8]];
                assert!(add_to_batch(&mut batch, &proof, public_input), 2);
                mut_i = mut_i + 1;
            };

            // Try to add one more - should fail
            let proof = verifier::create_proof(
                vector[1u8], vector[2u8], vector[3u8]
            );
            let public_input = vector[vector[4u8]];
            assert!(!add_to_batch(&mut batch, &proof, public_input), 3);

            transfer::public_share_object(batch);
            test_scenario::return_to_sender(scenario, vk);
        };
        
        test_scenario::end(scenario_val);
    }
} 