module zk_snark::admin {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use zk_snark::key_types::VerificationKey;
    use zk_snark::admin_impl;

    // Admin capability
    struct AdminCap has key {
        id: UID
    }

    // Public function to check if a capability is valid
    public fun is_admin(cap: &AdminCap): bool {
        object::id(cap) != object::id_from_address(@0x0)
    }

    // Initialize admin
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            AdminCap { id: object::new(ctx) },
            tx_context::sender(ctx)
        );
    }

    // Update verification key parameters
    public fun update_verification_key(
        _admin_cap: &AdminCap,
        vk: &mut VerificationKey,
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    ) {
        admin_impl::update_key_params(vk, alpha, beta, gamma, delta, ic)
    }

    // Disable verification key
    public fun disable_verification_key(
        _admin_cap: &AdminCap,
        vk: &mut VerificationKey
    ) {
        admin_impl::disable_key(vk)
    }

    #[test]
    fun test_admin_operations() {
        use sui::test_scenario;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let _scenario = &scenario_val;
        
        test_scenario::end(scenario_val);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
} 