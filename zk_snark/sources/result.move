module zk_snark::result {
    use zk_snark::verifier::{Self, VerificationKey, Proof};
    use std::vector;

    struct VerificationResult has copy, drop {
        success: bool,
        error_code: u64,
        error_message: vector<u8>
    }

    public fun verify_with_result(
        vk: &VerificationKey,
        proof: &Proof,
        public_inputs: vector<vector<u8>>
    ): VerificationResult {
        if (!verifier::validate_inputs_length(vk, &public_inputs)) {
            return VerificationResult {
                success: false,
                error_code: verifier::error_invalid_public_inputs(),
                error_message: b"Invalid number of public inputs"
            }
        };
        
        let valid = verifier::verify(vk, proof, public_inputs);
        
        VerificationResult {
            success: valid,
            error_code: 0,
            error_message: vector::empty()
        }
    }

    #[test]
    fun test_verify_with_result() {
        use sui::test_scenario;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        test_scenario::next_tx(scenario, admin);
        {
            let invalid_proof = verifier::create_proof(
                vector::empty(),
                vector::empty(),
                vector::empty()
            );
            
            let public_inputs = vector::empty<vector<u8>>();
            let vk = test_scenario::take_from_sender<VerificationKey>(scenario);
            
            let result = verify_with_result(&vk, &invalid_proof, public_inputs);
            assert!(!result.success, 1);
            assert!(result.error_code == verifier::error_invalid_public_inputs(), 2);
            
            test_scenario::return_to_sender(scenario, vk);
        };
        
        test_scenario::end(scenario_val);
    }
} 