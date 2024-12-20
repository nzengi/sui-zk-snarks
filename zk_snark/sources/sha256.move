module zk_snark::sha256 {
    use std::vector;

    // SHA-256 Constants
    const BLOCK_SIZE: u64 = 64;  // 512 bits
    const OUTPUT_SIZE: u64 = 32; // 256 bits
    
    // Public functions to access constants
    public fun get_block_size(): u64 { BLOCK_SIZE }
    public fun get_output_size(): u64 { OUTPUT_SIZE }
    
    // Initial hash values (first 32 bits of the fractional parts of the square roots of the first 8 primes)
    const H0: u32 = 0x6a09e667;
    const H1: u32 = 0xbb67ae85;
    const H2: u32 = 0x3c6ef372;
    const H3: u32 = 0xa54ff53a;
    const H4: u32 = 0x510e527f;
    const H5: u32 = 0x9b05688c;
    const H6: u32 = 0x1f83d9ab;
    const H7: u32 = 0x5be0cd19;

    // Round constants (first 32 bits of the fractional parts of the cube roots of the first 64 primes)
    const K: vector<u32> = vector[
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ];

    // Error codes
    const E_INVALID_LENGTH: u64 = 1;
    const E_INVALID_STATE: u64 = 2;

    struct SHA256State has copy, drop {
        h: vector<u32>,    // Hash state
        data: vector<u8>,  // Pending data
        len: u64          // Total length processed
    }

    public fun new(): SHA256State {
        let h = vector::empty();
        vector::push_back(&mut h, H0);
        vector::push_back(&mut h, H1);
        vector::push_back(&mut h, H2);
        vector::push_back(&mut h, H3);
        vector::push_back(&mut h, H4);
        vector::push_back(&mut h, H5);
        vector::push_back(&mut h, H6);
        vector::push_back(&mut h, H7);

        SHA256State {
            h,
            data: vector::empty(),
            len: 0
        }
    }

    public fun update(state: &mut SHA256State, input: &vector<u8>) {
        let i = 0;
        let input_len = vector::length(input);
        
        while (i < input_len) {
            vector::push_back(&mut state.data, *vector::borrow(input, i));
            
            if (vector::length(&state.data) == BLOCK_SIZE) {
                process_block(state);
            };
            
            i = i + 1;
        };
        
        state.len = state.len + input_len;
    }

    public fun finalize(state: &mut SHA256State): vector<u8> {
        // Add padding
        let _data_len = vector::length(&state.data);
        let total_len = state.len * 8; // Length in bits
        
        // Add 1 bit
        vector::push_back(&mut state.data, 0x80);
        
        // Add zeros
        while ((vector::length(&state.data) + 8) % BLOCK_SIZE != 0) {
            vector::push_back(&mut state.data, 0);
        };
        
        // Add length as big-endian 64-bit integer
        let mut_i = 7;
        while (mut_i >= 0) {
            vector::push_back(&mut state.data, ((total_len >> (mut_i * 8)) & 0xFF as u8));
            mut_i = mut_i - 1;
            if (mut_i == 0) break;
        };
        
        // Process remaining blocks
        while (!vector::is_empty(&state.data)) {
            process_block(state);
        };
        
        // Convert state to bytes
        let result = vector::empty();
        let i = 0;
        while (i < 8) {
            let word = *vector::borrow(&state.h, i);
            let j = 3;
            while (j >= 0) {
                vector::push_back(&mut result, ((word >> (j * 8)) & 0xFF as u8));
                j = j - 1;
            };
            i = i + 1;
        };
        
        result
    }

    fun process_block(state: &mut SHA256State) {
        // Ensure we have enough data
        assert!(vector::length(&state.data) >= BLOCK_SIZE, E_INVALID_LENGTH);
        
        // 1. Prepare message schedule
        let w = vector::empty();
        let i = 0;
        while (i < 64) {
            if (i < 16) {
                let b0 = (*vector::borrow(&state.data, i * 4) as u32);
                let b1 = (*vector::borrow(&state.data, i * 4 + 1) as u32);
                let b2 = (*vector::borrow(&state.data, i * 4 + 2) as u32);
                let b3 = (*vector::borrow(&state.data, i * 4 + 3) as u32);
                
                let word = bitwise_or(
                    leftshift(b0, 24),
                    bitwise_or(
                        leftshift(b1, 16),
                        bitwise_or(
                            leftshift(b2, 8),
                            b3
                        )
                    )
                );
                vector::push_back(&mut w, word);
            } else {
                let w15 = *vector::borrow(&w, i - 15);
                let w2 = *vector::borrow(&w, i - 2);
                let w16 = *vector::borrow(&w, i - 16);
                let w7 = *vector::borrow(&w, i - 7);
                
                let s0 = bitwise_xor(
                    rightrotate(w15, 7),
                    bitwise_xor(
                        rightrotate(w15, 18),
                        rightshift(w15, 3)
                    )
                );
                
                let s1 = bitwise_xor(
                    rightrotate(w2, 17),
                    bitwise_xor(
                        rightrotate(w2, 19),
                        rightshift(w2, 10)
                    )
                );
                
                let new_w = w16 + s0 + w7 + s1;
                vector::push_back(&mut w, new_w);
            };
            i = i + 1;
        };

        // 2. Initialize working variables
        let a = *vector::borrow(&state.h, 0);
        let b = *vector::borrow(&state.h, 1);
        let c = *vector::borrow(&state.h, 2);
        let d = *vector::borrow(&state.h, 3);
        let e = *vector::borrow(&state.h, 4);
        let f = *vector::borrow(&state.h, 5);
        let g = *vector::borrow(&state.h, 6);
        let h = *vector::borrow(&state.h, 7);

        // 3. Main loop
        let i = 0;
        while (i < 64) {
            let k_i = *vector::borrow(&K, i);
            let w_i = *vector::borrow(&w, i);
            
            let s1 = bitwise_xor(
                rightrotate(e, 6),
                bitwise_xor(rightrotate(e, 11), rightrotate(e, 25))
            );

            let ch = bitwise_xor(
                bitwise_and(e, f),
                bitwise_and(bitwise_not(e), g)
            );

            let temp1 = h + s1 + ch + k_i + w_i;
            
            let s0 = bitwise_xor(
                rightrotate(a, 2),
                bitwise_xor(rightrotate(a, 13), rightrotate(a, 22))
            );

            // maj = (a & b) ^ (a & c) ^ (b & c)
            let maj = bitwise_xor(
                bitwise_and(a, b),
                bitwise_xor(
                    bitwise_and(a, c),
                    bitwise_and(b, c)
                )
            );

            let temp2 = s0 + maj;
            
            h = g;
            g = f;
            f = e;
            e = d + temp1;
            d = c;
            c = b;
            b = a;
            a = temp1 + temp2;
            
            i = i + 1;
        };

        // 4. Update state
        *vector::borrow_mut(&mut state.h, 0) = *vector::borrow(&state.h, 0) + a;
        *vector::borrow_mut(&mut state.h, 1) = *vector::borrow(&state.h, 1) + b;
        *vector::borrow_mut(&mut state.h, 2) = *vector::borrow(&state.h, 2) + c;
        *vector::borrow_mut(&mut state.h, 3) = *vector::borrow(&state.h, 3) + d;
        *vector::borrow_mut(&mut state.h, 4) = *vector::borrow(&state.h, 4) + e;
        *vector::borrow_mut(&mut state.h, 5) = *vector::borrow(&state.h, 5) + f;
        *vector::borrow_mut(&mut state.h, 6) = *vector::borrow(&state.h, 6) + g;
        *vector::borrow_mut(&mut state.h, 7) = *vector::borrow(&state.h, 7) + h;

        // Clear processed data
        state.data = vector::empty();
    }

    fun rightrotate(value: u32, shift: u8): u32 {
        let value64 = (value as u64);
        let shift32 = ((shift % 32) as u8);
        let right = value64 >> shift32;
        let left = value64 << (32 - shift32);
        ((right | left) & 0xFFFFFFFF) as u32
    }

    fun leftshift(value: u32, shift: u8): u32 {
        let value64 = (value as u64);
        let shift32 = ((shift % 32) as u8);
        ((value64 << shift32) & 0xFFFFFFFF) as u32
    }

    fun rightshift(value: u32, shift: u8): u32 {
        let value64 = (value as u64);
        let shift32 = ((shift % 32) as u8);
        (value64 >> shift32) as u32
    }

    // Bitwise operations
    fun bitwise_and(a: u32, b: u32): u32 {
        ((a as u64) & (b as u64) as u32)
    }

    fun bitwise_or(a: u32, b: u32): u32 {
        ((a as u64) | (b as u64) as u32)
    }

    fun bitwise_xor(a: u32, b: u32): u32 {
        ((a as u64) ^ (b as u64) as u32)
    }

    // NOT işlemi için 1'lerin tümleyeni
    fun bitwise_not(a: u32): u32 {
        let max_u32: u64 = 0xFFFFFFFF;
        ((max_u32 ^ (a as u64)) as u32)
    }

    // Helper function to compare hash results
    fun compare_hash(a: &vector<u8>, b: &vector<u8>): bool {
        if (vector::length(a) != vector::length(b)) return false;
        let i = 0;
        let len = vector::length(a);
        while (i < len) {
            if (*vector::borrow(a, i) != *vector::borrow(b, i)) return false;
            i = i + 1;
        };
        true
    }

    #[test]
    fun test_sha256() {
        // Test empty string
        let state = new();
        let result = finalize(&mut state);
        assert!(vector::length(&result) == OUTPUT_SIZE, E_INVALID_LENGTH);
        
        // Known hash for empty string
        let expected = x"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
        assert!(compare_hash(&result, &expected), E_INVALID_STATE);

        // Test "abc"
        let state = new();
        let input = b"abc";
        update(&mut state, &input);
        let result = finalize(&mut state);
        
        // Known hash for "abc"
        let expected = x"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
        assert!(compare_hash(&result, &expected), E_INVALID_STATE);

        // Test long input
        let state = new();
        let input = b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
        update(&mut state, &input);
        let result = finalize(&mut state);
        
        // Known hash for the long input
        let expected = x"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1";
        assert!(compare_hash(&result, &expected), E_INVALID_STATE);

        // Test multiple updates
        let state = new();
        update(&mut state, &b"a");
        update(&mut state, &b"b");
        update(&mut state, &b"c");
        let result = finalize(&mut state);
        
        // Should match hash of "abc"
        let expected = x"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
        assert!(compare_hash(&result, &expected), E_INVALID_STATE);
    }

    #[test]
    fun test_bitwise_operations() {
        // Test AND
        assert!(bitwise_and(0xFFFFFFFF, 0x0F0F0F0F) == 0x0F0F0F0F, 1);
        
        // Test OR
        assert!(bitwise_or(0xF0F0F0F0, 0x0F0F0F0F) == 0xFFFFFFFF, 2);
        
        // Test XOR
        assert!(bitwise_xor(0xAAAAAAAA, 0x55555555) == 0xFFFFFFFF, 3);
        
        // Test NOT
        assert!(bitwise_not(0x00000000) == 0xFFFFFFFF, 4);
        assert!(bitwise_not(0xFFFFFFFF) == 0x00000000, 5);
        
        // Test shifts
        assert!(leftshift(0x01234567, 8) == 0x23456700, 6);
        assert!(rightshift(0x89ABCDEF, 8) == 0x0089ABCD, 7);
        
        // Test rotate
        assert!(rightrotate(0x01234567, 8) == 0x67012345, 8);
    }
} 