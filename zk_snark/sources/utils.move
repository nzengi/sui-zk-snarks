module zk_snark::utils {
    use std::vector;
    use zk_snark::verifier::{Self, Proof};

    // Constants
    const POINT_LENGTH: u64 = 32;
    const MAX_PUBLIC_INPUTS: u64 = 100;
    const FIELD_ELEMENT_LENGTH: u64 = 32;

    // Point length getter
    public fun get_point_length(): u64 {
        POINT_LENGTH
    }

    // Field element length getter
    public fun get_field_element_length(): u64 {
        FIELD_ELEMENT_LENGTH
    }

    // Validate field element encoding
    public fun validate_field_element(element: &vector<u8>): bool {
        vector::length(element) == FIELD_ELEMENT_LENGTH
    }

    // Validate public inputs
    public fun validate_public_inputs(inputs: &vector<vector<u8>>): bool {
        let len = vector::length(inputs);
        if (len > MAX_PUBLIC_INPUTS) {
            return false
        };

        let i = 0;
        while (i < len) {
            if (!validate_field_element(vector::borrow(inputs, i))) {
                return false
            };
            i = i + 1;
        };
        true
    }

    // Serialize multiple points into a single vector
    public fun serialize_points(points: &vector<vector<u8>>): vector<u8> {
        let result = vector::empty();
        let i = 0;
        let len = vector::length(points);
        
        // Add length prefix
        vector::append(&mut result, to_bytes(len));
        
        while (i < len) {
            let point = vector::borrow(points, i);
            vector::append(&mut result, *point);
            i = i + 1;
        };
        
        result
    }

    // Convert u64 to bytes
    fun to_bytes(value: u64): vector<u8> {
        let result = vector::empty();
        let i = 0;
        while (i < 8) {
            let byte = (((value >> (i * 8)) & 0xFF) as u8);
            vector::push_back(&mut result, byte);
            i = i + 1;
        };
        result
    }

    // Validate point encoding
    public fun validate_point_encoding(point: &vector<u8>): bool {
        vector::length(point) == POINT_LENGTH
    }

    // Combine multiple vectors into one
    public fun combine_vectors(vectors: &vector<vector<u8>>): vector<u8> {
        let result = vector::empty();
        let i = 0;
        let len = vector::length(vectors);
        
        while (i < len) {
            let current = vector::borrow(vectors, i);
            vector::append(&mut result, *current);
            i = i + 1;
        };
        
        result
    }

    // Calculate proof hash
    public fun calculate_proof_hash(proof: &Proof): vector<u8> {
        // TODO: Implement proper hash calculation
        let (a, b, c) = verifier::get_proof_points(proof);
        let combined = combine_vectors(&vector[
            a, b, c
        ]);
        combined
    }

    // Helper functions for byte operations
    public fun create_zero_pad(len: u64): vector<u8> {
        let result = vector::empty();
        let i = 0;
        while (i < len) {
            vector::push_back(&mut result, 0u8);
            i = i + 1;
        };
        result
    }

    public fun to_be_bytes_2(value: u64): vector<u8> {
        let result = vector::empty();
        vector::push_back(&mut result, ((value >> 8) as u8));
        vector::push_back(&mut result, ((value & 0xFF) as u8));
        result
    }

    public fun strxor(a: &vector<u8>, b: &vector<u8>): vector<u8> {
        let len = vector::length(a);
        assert!(len == vector::length(b), 1);
        
        let result = vector::empty();
        let i = 0;
        while (i < len) {
            let byte_a = *vector::borrow(a, i);
            let byte_b = *vector::borrow(b, i);
            vector::push_back(&mut result, byte_a ^ byte_b);
            i = i + 1;
        };
        result
    }

    #[test]
    fun test_utils() {
        // Test point validation
        let valid_point = vector::empty();
        let i = 0;
        while (i < POINT_LENGTH) {
            vector::push_back(&mut valid_point, 0u8);
            i = i + 1;
        };
        assert!(validate_point_encoding(&valid_point), 1);
        
        let invalid_point = vector::empty();
        let i = 0;
        while (i < POINT_LENGTH - 1) {
            vector::push_back(&mut invalid_point, 0u8);
            i = i + 1;
        };
        assert!(!validate_point_encoding(&invalid_point), 2);
        
        // Test vector combination
        let v1 = vector[1u8, 2u8];
        let v2 = vector[3u8, 4u8];
        let vectors = vector[v1, v2];
        let combined = combine_vectors(&vectors);
        assert!(vector::length(&combined) == 4, 3);

        // Test field element validation
        let valid_field = vector::empty();
        let i = 0;
        while (i < FIELD_ELEMENT_LENGTH) {
            vector::push_back(&mut valid_field, 0u8);
            i = i + 1;
        };
        assert!(validate_field_element(&valid_field), 4);

        // Test public inputs validation
        let valid_inputs = vector::empty();
        vector::push_back(&mut valid_inputs, valid_field);
        assert!(validate_public_inputs(&valid_inputs), 5);
    }
} 