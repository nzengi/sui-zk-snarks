// app/api/verify/route.ts
import { NextResponse } from 'next/server';
import { SuiClient } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';

// Network tipini belirtelim
const NETWORKS = ['mainnet', 'testnet', 'devnet', 'localnet'] as const;
type Network = typeof NETWORKS[number];
const NETWORK = (process.env.NEXT_PUBLIC_SUI_NETWORK || 'mainnet') as Network;

if (!NETWORKS.includes(NETWORK)) {
  throw new Error(`Invalid network: ${NETWORK}`);
}

const suiClient = new SuiClient({
  url: `https://fullnode.${NETWORK}.sui.io:443`
});

export async function POST(req: Request) {
  try {
    const { vk, proof, publicInputs } = await req.json();

    const tx = new Transaction();
    
    tx.moveCall({
      target: `${process.env.PACKAGE_ID}::interface::submit_proof`,
      arguments: [
        tx.pure(vk, { type: 'string' }),
        tx.pure(proof, { type: 'string' }),
        tx.pure(publicInputs, { type: 'string' }),
      ],
    });

    // Admin keypair oluştur
    const adminKeypair = Ed25519Keypair.fromSecretKey(
      Buffer.from(process.env.ADMIN_PRIVATE_KEY || '', 'base64')
    );

    const result = await suiClient.signAndExecuteTransaction({
      transaction: tx,
      signer: adminKeypair,
      requestType: 'WaitForLocalExecution',
    });

    return NextResponse.json({ 
      success: true, 
      result 
    });
    
  } catch (error) {
    if (error instanceof Error) {
      return NextResponse.json(
        { success: false, error: error.message },
        { status: 500 }
      );
    }
    return NextResponse.json(
      { success: false, error: 'Unknown error occurred' },
      { status: 500 }
    );
  }
}