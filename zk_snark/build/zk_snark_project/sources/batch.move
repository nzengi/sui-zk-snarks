module zk_snark::batch {
    use zk_snark::verifier::{Self, VerificationKey, Proof};
    use std::vector;

    struct BatchProof has store, drop {
        proofs: vector<Proof>,
        public_inputs: vector<vector<vector<u8>>>
    }

    public fun verify_batch(
        vk: &VerificationKey,
        batch: &BatchProof
    ): bool {
        let i = 0;
        let len = vector::length(&batch.proofs);
        let valid = true;

        while (i < len) {
            let proof = vector::borrow(&batch.proofs, i);
            let inputs = vector::borrow(&batch.public_inputs, i);
            if (!verifier::verify(vk, proof, *inputs)) {
                valid = false;
                break
            };
            i = i + 1;
        };

        valid
    }

    public fun create_batch(
        proofs: vector<Proof>,
        public_inputs: vector<vector<vector<u8>>>
    ): BatchProof {
        BatchProof {
            proofs,
            public_inputs
        }
    }

    // Create batch from single proof
    public fun create_batch_from_single(
        proof: &Proof,
        public_input: vector<vector<u8>>
    ): BatchProof {
        let proofs = vector::empty();
        let public_inputs = vector::empty();
        
        vector::push_back(&mut proofs, *proof);
        vector::push_back(&mut public_inputs, public_input);
        
        BatchProof {
            proofs,
            public_inputs
        }
    }

    // Add proof to batch
    public fun add_to_batch(
        batch: &mut BatchProof,
        proof: &Proof,
        public_input: vector<vector<u8>>
    ) {
        vector::push_back(&mut batch.proofs, *proof);
        vector::push_back(&mut batch.public_inputs, public_input);
    }

    // Get batch size
    public fun get_batch_size(batch: &BatchProof): u64 {
        vector::length(&batch.proofs)
    }

    #[test]
    fun test_batch_verification() {
        // Test implementation
    }

    #[test]
    fun test_batch_operations() {
        use zk_snark::verifier;
        
        // Create a single proof
        let proof = verifier::create_proof(
            vector[1u8], vector[2u8], vector[3u8]
        );
        let public_input = vector[vector[4u8]];
        
        // Create batch from single proof
        let batch = create_batch_from_single(&proof, public_input);
        assert!(get_batch_size(&batch) == 1, 1);
        
        // Add another proof
        let proof2 = verifier::create_proof(
            vector[5u8], vector[6u8], vector[7u8]
        );
        let public_input2 = vector[vector[8u8]];
        add_to_batch(&mut batch, &proof2, public_input2);
        assert!(get_batch_size(&batch) == 2, 2);
    }
} 