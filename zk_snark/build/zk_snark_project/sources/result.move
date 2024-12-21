module zk_snark::result {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use zk_snark::verifier::{Self, VerificationKey};
    use zk_snark::admin::{Self, AdminCap};
    use zk_snark::utils::Self;
    use std::vector;

    struct VerificationResult has key {
        id: UID,
        verified: bool,
        timestamp: u64
    }

    public fun verify_with_result(
        vk: &VerificationKey,
        proof: &verifier::Proof,
        public_inputs: vector<vector<u8>>,
        ctx: &mut TxContext
    ): VerificationResult {
        let verified = verifier::verify(vk, proof, public_inputs);
        
        VerificationResult {
            id: object::new(ctx),
            verified,
            timestamp: tx_context::epoch(ctx)
        }
    }

    #[test]
    fun test_verify_with_result() {
        use sui::test_scenario;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        // Initialize verification key and admin capability
        test_scenario::next_tx(scenario, admin);
        {
            verifier::init_for_testing(test_scenario::ctx(scenario));
            admin::init_for_testing(test_scenario::ctx(scenario));
        };

        // Update verification key with valid parameters
        test_scenario::next_tx(scenario, admin);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            
            // Use valid test vectors
            let point_len = utils::get_point_length();
            let alpha = create_test_point(point_len);
            let beta = create_test_point(point_len);
            let gamma = create_test_point(point_len);
            let delta = create_test_point(point_len);
            let mut_ic = vector[create_test_point(point_len), create_test_point(point_len)];
            
            admin::update_verification_key(&admin_cap, &mut vk, alpha, beta, gamma, delta, mut_ic);
            
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_to_sender(scenario, vk);
        };

        // Test verification
        test_scenario::next_tx(scenario, admin);
        {
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            let point_len = utils::get_point_length();
            
            // Geçerli uzunlukta test proof oluştur
            let proof = verifier::create_proof(
                create_test_point(point_len),  // a
                create_test_point(point_len),  // b
                create_test_point(point_len)   // c
            );
            
            // Geçerli uzunlukta public input oluştur
            let public_inputs = vector[create_test_point(point_len)];
            
            let result = verify_with_result(&vk, &proof, public_inputs, test_scenario::ctx(scenario));
            assert!(result.verified, 1);
            
            test_scenario::return_to_sender(scenario, vk);
            transfer::transfer(result, admin);
        };
        
        test_scenario::end(scenario_val);
    }

    fun create_test_point(len: u64): vector<u8> {
        let result = vector::empty();
        let i = 0;
        while (i < len) {
            vector::push_back(&mut result, ((i + 1) as u8));
            i = i + 1;
        };
        result
    }
} 