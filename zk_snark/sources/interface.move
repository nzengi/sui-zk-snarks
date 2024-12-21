module zk_snark::interface {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use std::vector;
    use zk_snark::key_types::VerificationKey;
    use zk_snark::verifier;
    use zk_snark::admin::{Self, AdminCap};

    // Subscription tiers
    const TIER_BASIC: u8 = 1;
    const TIER_PRO: u8 = 2;
    const TIER_ENTERPRISE: u8 = 3;

    // Subscription fees (in SUI)
    const BASIC_FEE: u64 = 1_000_000;     // 0.001 SUI
    const PRO_FEE: u64 = 10_000_000;      // 0.01 SUI
    const ENTERPRISE_FEE: u64 = 100_000_000; // 0.1 SUI

    struct Subscription has key {
        id: UID,
        tier: u8,
        expiry: u64,
        verification_count: u64,
        owner: address
    }

    // Events
    struct SubscriptionCreated has copy, drop {
        subscriber: address,
        tier: u8,
        expiry: u64
    }

    struct ProofVerified has copy, drop {
        prover: address,
        verified: bool,
        timestamp: u64
    }

    // Verification fee
    const VERIFICATION_FEE: u64 = 1_000_000; // 0.001 SUI

    // Errors
    const E_INSUFFICIENT_FEE: u64 = 1;

    // Submit and verify a proof
    public entry fun submit_proof(
        vk: &VerificationKey,
        proof_data: vector<u8>,
        public_inputs: vector<vector<u8>>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        // Check fee
        assert!(coin::value(payment) >= VERIFICATION_FEE, E_INSUFFICIENT_FEE);

        // Create proof object
        let proof = verifier::create_proof(
            proof_data,
            vector::empty(), // b
            vector::empty()  // c
        );

        // Verify proof
        let verified = verifier::verify(vk, &proof, public_inputs);

        // Emit event
        event::emit(ProofVerified {
            prover: tx_context::sender(ctx),
            verified,
            timestamp: tx_context::epoch(ctx)
        });

        // Take fee if verified
        if (verified) {
            let fee = coin::split(payment, VERIFICATION_FEE, ctx);
            transfer::public_transfer(fee, tx_context::sender(ctx));
        };
    }

    // Admin functions
    public entry fun update_verification_key(
        admin_cap: &AdminCap,
        vk: &mut VerificationKey,
        alpha: vector<u8>,
        beta: vector<u8>,
        gamma: vector<u8>,
        delta: vector<u8>,
        ic: vector<vector<u8>>
    ) {
        admin::update_verification_key(
            admin_cap, vk, alpha, beta, gamma, delta, ic
        );
    }

    public entry fun disable_verification_key(
        admin_cap: &AdminCap,
        vk: &mut VerificationKey
    ) {
        admin::disable_verification_key(admin_cap, vk);
    }

    // Create new subscription
    public entry fun create_subscription(
        payment: &mut Coin<SUI>,
        tier: u8,
        ctx: &mut TxContext
    ) {
        // Validate tier
        assert!(tier >= TIER_BASIC && tier <= TIER_ENTERPRISE, 1);

        // Calculate fee
        let fee = if (tier == TIER_BASIC) {
            BASIC_FEE
        } else if (tier == TIER_PRO) {
            PRO_FEE
        } else {
            ENTERPRISE_FEE
        };

        // Check payment
        assert!(coin::value(payment) >= fee, E_INSUFFICIENT_FEE);

        // Create subscription
        let subscription = Subscription {
            id: object::new(ctx),
            tier,
            expiry: tx_context::epoch(ctx) + 30 * 24 * 60 * 60, // 30 days
            verification_count: 0,
            owner: tx_context::sender(ctx)
        };

        // Take fee
        let fee_coin = coin::split(payment, fee, ctx);
        transfer::public_transfer(fee_coin, tx_context::sender(ctx));

        // Emit event
        event::emit(SubscriptionCreated {
            subscriber: tx_context::sender(ctx),
            tier,
            expiry: subscription.expiry
        });

        // Transfer subscription to user
        transfer::transfer(subscription, tx_context::sender(ctx));
    }

    // Verify proof with subscription
    public entry fun verify_with_subscription(
        vk: &VerificationKey,
        proof_data: vector<u8>,
        public_inputs: vector<vector<u8>>,
        subscription: &mut Subscription,
        ctx: &mut TxContext
    ) {
        // Check subscription expiry
        assert!(tx_context::epoch(ctx) <= subscription.expiry, 1);

        // Create and verify proof
        let proof = verifier::create_proof(
            proof_data,
            vector::empty(),
            vector::empty()
        );

        let verified = verifier::verify(vk, &proof, public_inputs);

        // Update verification count
        subscription.verification_count = subscription.verification_count + 1;

        // Emit event
        event::emit(ProofVerified {
            prover: tx_context::sender(ctx),
            verified,
            timestamp: tx_context::epoch(ctx)
        });
    }
} 