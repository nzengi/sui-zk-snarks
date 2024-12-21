module zk_snark::license {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use zk_snark::admin::{Self, AdminCap};

    // License types
    const LICENSE_STANDARD: u8 = 1;
    const LICENSE_PREMIUM: u8 = 2;
    const LICENSE_ENTERPRISE: u8 = 3;

    // License fees
    const STANDARD_FEE: u64 = 1_000_000_000;    // 1 SUI
    const PREMIUM_FEE: u64 = 5_000_000_000;     // 5 SUI
    const ENTERPRISE_FEE: u64 = 10_000_000_000; // 10 SUI

    // Error codes
    const E_INVALID_LICENSE_TYPE: u64 = 1;
    const E_INSUFFICIENT_PAYMENT: u64 = 2;
    const E_LICENSE_EXPIRED: u64 = 3;
    const E_UNAUTHORIZED: u64 = 4;

    struct License has key {
        id: UID,
        license_type: u8,
        holder: address,
        expiry: u64,
        max_verifications: u64,
        used_verifications: u64,
        custom_parameters: vector<u8>
    }

    // Events
    struct LicenseCreated has copy, drop {
        license_type: u8,
        holder: address,
        expiry: u64
    }

    struct LicenseUsed has copy, drop {
        license_id: address,
        verifications_left: u64
    }

    // Create new license
    public entry fun create_license(
        payment: &mut Coin<SUI>,
        license_type: u8,
        ctx: &mut TxContext
    ) {
        // Validate license type
        assert!(
            license_type >= LICENSE_STANDARD && 
            license_type <= LICENSE_ENTERPRISE,
            E_INVALID_LICENSE_TYPE
        );

        // Calculate fee and max verifications
        let (fee, max_verifications) = if (license_type == LICENSE_STANDARD) {
            (STANDARD_FEE, 1000)
        } else if (license_type == LICENSE_PREMIUM) {
            (PREMIUM_FEE, 5000)
        } else {
            (ENTERPRISE_FEE, 100000)
        };

        // Check payment
        assert!(coin::value(payment) >= fee, E_INSUFFICIENT_PAYMENT);

        // Create license
        let license = License {
            id: object::new(ctx),
            license_type,
            holder: tx_context::sender(ctx),
            expiry: tx_context::epoch(ctx) + 365 * 24 * 60 * 60, // 1 year
            max_verifications,
            used_verifications: 0,
            custom_parameters: vector[]
        };

        // Take fee
        let fee_coin = coin::split(payment, fee, ctx);
        transfer::public_transfer(fee_coin, tx_context::sender(ctx));

        // Emit event
        event::emit(LicenseCreated {
            license_type,
            holder: tx_context::sender(ctx),
            expiry: license.expiry
        });

        // Transfer license to holder
        transfer::transfer(license, tx_context::sender(ctx));
    }

    // Use license for verification
    public fun use_license(license: &mut License, ctx: &TxContext): bool {
        // Check expiry
        assert!(tx_context::epoch(ctx) <= license.expiry, E_LICENSE_EXPIRED);
        
        // Check usage limit
        if (license.used_verifications >= license.max_verifications) {
            return false
        };

        // Update usage
        license.used_verifications = license.used_verifications + 1;

        // Emit event
        event::emit(LicenseUsed {
            license_id: object::uid_to_address(&license.id),
            verifications_left: license.max_verifications - license.used_verifications
        });

        true
    }

    // Admin functions
    public entry fun update_license_parameters(
        admin_cap: &AdminCap,
        license: &mut License,
        custom_parameters: vector<u8>
    ) {
        // Only admin can update parameters
        assert!(admin::is_admin(admin_cap), E_UNAUTHORIZED);
        license.custom_parameters = custom_parameters;
    }

    // View functions
    public fun get_license_info(license: &License): (u8, u64, u64, u64) {
        (
            license.license_type,
            license.expiry,
            license.max_verifications,
            license.used_verifications
        )
    }

    #[test]
    fun test_license_creation_and_usage() {
        use sui::test_scenario;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        // Initialize admin first
        test_scenario::next_tx(scenario, admin);
        {
            admin::init_for_testing(test_scenario::ctx(scenario));
        };

        // Create license
        test_scenario::next_tx(scenario, admin);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            
            // Create test payment
            let payment = coin::mint_for_testing<SUI>(STANDARD_FEE, test_scenario::ctx(scenario));
            
            // Create license
            create_license(
                &mut payment,
                LICENSE_STANDARD,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_to_sender(scenario, admin_cap);
            coin::burn_for_testing(payment);
        };

        // Test license usage
        test_scenario::next_tx(scenario, admin);
        {
            let license = test_scenario::take_from_sender<License>(scenario);
            
            // Use license
            assert!(use_license(&mut license, test_scenario::ctx(scenario)), 1);
            
            let (_, _, max, used) = get_license_info(&license);
            assert!(used == 1, 2);
            assert!(max == 1000, 3);

            test_scenario::return_to_sender(scenario, license);
        };

        test_scenario::end(scenario_val);
    }
} 