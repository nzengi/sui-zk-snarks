module zk_snark::revenue {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use std::vector;
    use zk_snark::admin::{Self, AdminCap};
    use sui::balance::{Self, Balance};

    // Error codes
    const E_INVALID_SHARES: u64 = 1;
    const E_UNAUTHORIZED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;

    // Revenue pool for managing shared revenue
    struct RevenuePool has key {
        id: UID,
        balance: Balance<SUI>,
        stakeholders: vector<address>,
        shares: vector<u64>, // Percentage shares (total should be 100)
        total_distributed: u64,
        last_distribution: u64
    }

    // Events
    struct RevenueDistributed has copy, drop {
        amount: u64,
        timestamp: u64
    }

    struct StakeholderAdded has copy, drop {
        stakeholder: address,
        share: u64
    }

    // Initialize revenue pool
    public entry fun initialize_pool(
        admin_cap: &AdminCap,
        ctx: &mut TxContext
    ) {
        assert!(admin::is_admin(admin_cap), E_UNAUTHORIZED);

        let pool = RevenuePool {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            stakeholders: vector::empty(),
            shares: vector::empty(),
            total_distributed: 0,
            last_distribution: tx_context::epoch(ctx)
        };

        transfer::share_object(pool);
    }

    // Add revenue to pool
    public entry fun add_revenue(
        pool: &mut RevenuePool,
        payment: &mut Coin<SUI>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let coin_balance = coin::into_balance(
            coin::split(payment, amount, ctx)
        );
        balance::join(&mut pool.balance, coin_balance);
    }

    // Add stakeholder
    public entry fun add_stakeholder(
        admin_cap: &AdminCap,
        pool: &mut RevenuePool,
        stakeholder: address,
        share: u64,
        _ctx: &mut TxContext
    ) {
        assert!(admin::is_admin(admin_cap), E_UNAUTHORIZED);
        
        // Calculate total shares
        let total_shares = 0u64;
        let i = 0;
        let len = vector::length(&pool.shares);
        while (i < len) {
            total_shares = total_shares + *vector::borrow(&pool.shares, i);
            i = i + 1;
        };
        
        // Ensure total shares don't exceed 100%
        assert!(total_shares + share <= 100, E_INVALID_SHARES);

        vector::push_back(&mut pool.stakeholders, stakeholder);
        vector::push_back(&mut pool.shares, share);

        event::emit(StakeholderAdded {
            stakeholder,
            share
        });
    }

    // Distribute revenue
    public entry fun distribute_revenue(
        pool: &mut RevenuePool,
        ctx: &mut TxContext
    ) {
        let total = balance::value(&pool.balance);
        assert!(total > 0, E_INSUFFICIENT_BALANCE);

        let i = 0;
        let len = vector::length(&pool.stakeholders);
        
        while (i < len) {
            let stakeholder = *vector::borrow(&pool.stakeholders, i);
            let share = *vector::borrow(&pool.shares, i);
            
            let amount = (total * share) / 100;
            if (amount > 0) {
                let payment = coin::from_balance(
                    balance::split(&mut pool.balance, amount),
                    ctx
                );
                transfer::public_transfer(payment, stakeholder);
            };
            
            i = i + 1;
        };

        pool.total_distributed = pool.total_distributed + total;
        pool.last_distribution = tx_context::epoch(ctx);

        event::emit(RevenueDistributed {
            amount: total,
            timestamp: tx_context::epoch(ctx)
        });
    }

    // View functions
    public fun get_pool_info(pool: &RevenuePool): (u64, u64, u64) {
        (
            balance::value(&pool.balance),
            pool.total_distributed,
            pool.last_distribution
        )
    }

    #[test]
    fun test_revenue_distribution() {
        use sui::test_scenario;
        
        let admin = @0xCAFE;
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        // Initialize admin first
        test_scenario::next_tx(scenario, admin);
        {
            admin::init_for_testing(test_scenario::ctx(scenario));
        };

        // Initialize pool
        test_scenario::next_tx(scenario, admin);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            initialize_pool(&admin_cap, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        // Add stakeholders
        test_scenario::next_tx(scenario, admin);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let pool = test_scenario::take_shared<RevenuePool>(scenario);

            add_stakeholder(&admin_cap, &mut pool, @0x1, 60, test_scenario::ctx(scenario)); // 60%
            add_stakeholder(&admin_cap, &mut pool, @0x2, 40, test_scenario::ctx(scenario)); // 40%

            test_scenario::return_shared(pool);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        // Add revenue and distribute
        test_scenario::next_tx(scenario, admin);
        {
            let pool = test_scenario::take_shared<RevenuePool>(scenario);
            let payment = coin::mint_for_testing<SUI>(100_000_000, test_scenario::ctx(scenario));

            add_revenue(&mut pool, &mut payment, 100_000_000, test_scenario::ctx(scenario));
            distribute_revenue(&mut pool, test_scenario::ctx(scenario));

            let (balance, total_distributed, _) = get_pool_info(&pool);
            assert!(balance == 0, 1);
            assert!(total_distributed == 100_000_000, 2);

            test_scenario::return_shared(pool);
            coin::burn_for_testing(payment);
        };

        test_scenario::end(scenario_val);
    }
} 