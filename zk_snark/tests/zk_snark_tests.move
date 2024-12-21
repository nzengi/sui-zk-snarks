#[test_only]
module zk_snark::zk_snark_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::transfer;
    use zk_snark::key_types::VerificationKey;
    use zk_snark::verifier;
    use zk_snark::admin::{Self, AdminCap};
    use zk_snark::utils;
    use std::vector;
    use zk_snark::batch;

    const ADMIN: address = @0xCAFE;
    const E_INVALID_PROOF: u64 = 2;
    const E_INVALID_KEY: u64 = 3;

    fun setup_test(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            verifier::init_for_testing(test_scenario::ctx(scenario));
            admin::init_for_testing(test_scenario::ctx(scenario));
        };
    }

    fun create_dummy_verification_key(): (vector<u8>, vector<u8>, vector<u8>, vector<u8>, vector<vector<u8>>) {
        let point_len = utils::get_point_length();
        
        // Create dummy points
        let alpha = create_dummy_point(point_len);
        let beta = create_dummy_point(point_len);
        let gamma = create_dummy_point(point_len);
        let delta = create_dummy_point(point_len);
        
        // Create IC vector
        let ic = vector::empty();
        vector::push_back(&mut ic, create_dummy_point(point_len));
        vector::push_back(&mut ic, create_dummy_point(point_len));
        
        (alpha, beta, gamma, delta, ic)
    }

    fun create_dummy_point(len: u64): vector<u8> {
        let point = vector::empty();
        let i = 0;
        while (i < len) {
            vector::push_back(&mut point, (i as u8));
            i = i + 1;
        };
        point
    }

    #[test]
    fun test_verification_flow() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;
        
        setup_test(scenario);

        // Initialize verification key with valid parameters
        test_scenario::next_tx(scenario, ADMIN);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            
            // Create valid test vectors
            let alpha = create_dummy_point(utils::get_point_length());
            let beta = create_dummy_point(utils::get_point_length());
            let gamma = create_dummy_point(utils::get_point_length());
            let delta = create_dummy_point(utils::get_point_length());
            let mut_ic = vector::empty();
            vector::push_back(&mut mut_ic, create_dummy_point(utils::get_point_length()));
            
            admin::update_verification_key(&admin_cap, &mut vk, alpha, beta, gamma, delta, mut_ic);
            
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_to_sender(scenario, vk);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_invalid_proof() {
        let scenario = test_scenario::begin(ADMIN);
        setup_test(&mut scenario);

        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let vk = test_scenario::take_from_sender<VerificationKey>(&scenario);
            
            // Boş proof geçerli olabilir, farklı bir invalid proof oluşturalım
            let proof = verifier::create_proof(
                vector[0xFFu8], // Invalid point
                vector[0xFFu8], // Invalid point
                vector[0xFFu8]  // Invalid point
            );

            let public_inputs = vector[vector[0xFFu8]]; // Invalid input
            
            // Verification should fail
            let result = verifier::verify(&vk, &proof, public_inputs);
            assert!(!result, E_INVALID_PROOF);

            test_scenario::return_to_sender(&scenario, vk);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_admin_operations() {
        let scenario = test_scenario::begin(ADMIN);
        setup_test(&mut scenario);

        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            let vk = test_scenario::take_from_sender<VerificationKey>(&scenario);
            
            // Test key update
            let (alpha, beta, gamma, delta, ic) = create_dummy_verification_key();
            admin::update_verification_key(
                &admin_cap,
                &mut vk,
                alpha,
                beta,
                gamma,
                delta,
                ic
            );
            assert!(verifier::is_key_valid(&vk), E_INVALID_KEY);

            // Test key disable
            admin::disable_verification_key(&admin_cap, &mut vk);
            assert!(!verifier::is_key_valid(&vk), 0);

            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_to_sender(&scenario, vk);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_batch_verification() {
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, admin);
        {
            verifier::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin);
        {
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            let batch = batch::create_batch(test_scenario::ctx(scenario));
            
            let proof1 = verifier::create_proof(
                vector[1u8], vector[2u8], vector[3u8]
            );
            let public_input1 = vector[vector[4u8]];
            
            assert!(batch::add_to_batch(&mut batch, &proof1, public_input1), 1);
            
            let mut_i = 0;
            while (mut_i < batch::get_max_batch_size() - 1) {  // -1 because we already added one
                let proof = verifier::create_proof(
                    vector[1u8], vector[2u8], vector[3u8]
                );
                let public_input = vector[vector[4u8]];
                
                let success = batch::add_to_batch(&mut batch, &proof, public_input);
                assert!(success, 2);
                
                mut_i = mut_i + 1;
            };

            transfer::public_share_object(batch);
            test_scenario::return_to_sender(scenario, vk);
        };
        
        test_scenario::end(scenario_val);
    }
}
