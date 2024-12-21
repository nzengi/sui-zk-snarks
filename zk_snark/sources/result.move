module zk_snark::result {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::vector;
    use zk_snark::key_types::{VerificationKey, Proof};
    use zk_snark::verifier;
    use zk_snark::verifier_impl;

    struct VerificationResult has key, store {
        id: UID,
        verified: bool,
        gas_used: u64
    }

    public fun verify_with_result(
        vk: &VerificationKey,
        proof: &Proof,
        public_inputs: vector<vector<u8>>,
        ctx: &mut TxContext
    ): VerificationResult {
        let (verified, gas_stats) = verifier_impl::verify_with_gas(vk, proof, public_inputs, ctx);
        let (total_gas, _, _, _) = verifier_impl::get_gas_stats_fields(&gas_stats);
        
        VerificationResult {
            id: object::new(ctx),
            verified,
            gas_used: total_gas
        }
    }

    #[test]
    fun test_verify_with_result() {
        use sui::test_scenario;
        use sui::transfer;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, admin);
        {
            verifier_impl::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin);
        {
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            
            let proof = verifier::create_proof(
                vector::empty<u8>(),
                vector::empty<u8>(),
                vector::empty<u8>()
            );
            
            let public_inputs = vector[vector::empty<u8>()];
            
            let result = verify_with_result(
                &vk,
                &proof,
                public_inputs,
                test_scenario::ctx(scenario)
            );
            
            assert!(result.verified, 1);
            
            transfer::transfer(result, admin);
            test_scenario::return_to_sender(scenario, vk);
        };
        
        test_scenario::end(scenario_val);
    }
} 