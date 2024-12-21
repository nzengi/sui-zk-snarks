module zk_snark::utils {
    use std::vector;

    // Constants
    const POINT_LENGTH: u64 = 32;
    const FIELD_ELEMENT_LENGTH: u64 = 32;

    // Basic validation functions
    public fun validate_length(data: &vector<u8>, expected_length: u64): bool {
        vector::length(data) == expected_length
    }

    // Helper functions
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

    // Getters for constants
    public fun get_point_length(): u64 { POINT_LENGTH }
    public fun get_field_element_length(): u64 { FIELD_ELEMENT_LENGTH }

    // Serialize multiple points into a single vector
    public fun serialize_points(points: &vector<vector<u8>>): vector<u8> {
        let result = vector::empty();
        let i = 0;
        let len = vector::length(points);
        
        while (i < len) {
            let point = vector::borrow(points, i);
            vector::append(&mut result, *point);
            i = i + 1;
        };
        
        result
    }
} 