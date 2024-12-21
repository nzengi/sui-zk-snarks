// src/components/verify/proof-form.tsx
'use client';

import { useCurrentAccount, useSignAndExecuteTransaction } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { WalletConnectButton } from '@/components/wallet/connect-button';
import { Button } from '@/components/ui/button';
import { useState } from 'react';
import { bcs } from '@mysten/bcs';

// BCS tiplerini tanımla
const VectorU8 = bcs.vector(bcs.u8());
const VectorVectorU8 = bcs.vector(VectorU8);

export function ProofForm() {
  const currentAccount = useCurrentAccount();
  const { mutate: signAndExecuteTransaction } = useSignAndExecuteTransaction();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>();
  const [txHash, setTxHash] = useState<string>();

  async function onSubmit(data: FormData) {
    if (!currentAccount?.address) return;
    
    setLoading(true);
    setError(undefined);
    setTxHash(undefined);

    try {
      const tx = new Transaction();
      
      // Input değerlerini al
      const vk = data.get('vk')?.toString().replace('0x', '').padStart(64, '0') || '';
      const proof = data.get('proof')?.toString().replace('0x', '').padStart(64, '0') || '';
      const publicInputs = data.get('publicInputs')?.toString().replace('0x', '').padStart(64, '0') || '';

      // Hex string'leri byte array'e çevir
      const vkBytes = Array.from(Buffer.from(vk, 'hex'));
      const proofBytes = Array.from(Buffer.from(proof, 'hex'));
      const publicInputsBytes = [Array.from(Buffer.from(publicInputs, 'hex'))];

      tx.moveCall({
        target: `${process.env.NEXT_PUBLIC_PACKAGE_ID}::interface::submit_proof`,
        arguments: [
          tx.pure(VectorU8.serialize(vkBytes).toBytes()),
          tx.pure(VectorU8.serialize(proofBytes).toBytes()),
          tx.pure(VectorVectorU8.serialize(publicInputsBytes).toBytes()),
        ],
      });

      signAndExecuteTransaction(
        {
          transaction: tx,
          chain: 'sui:testnet',
        },
        {
          onSuccess: (result) => {
            setTxHash(result.digest);
            console.log('Transaction result:', result);
          },
          onError: (error) => {
            setError(error.message);
          },
        }
      );
      
    } catch (err) {
      console.error(err);
      setError(err instanceof Error ? err.message : 'Unknown error occurred');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      {!currentAccount?.address ? (
        <div className="text-center">
          <p className="mb-4">Connect your wallet to verify proofs</p>
          <WalletConnectButton />
        </div>
      ) : (
        <form action={onSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">
              Verification Key
            </label>
            <input
              type="text"
              name="vk"
              className="w-full p-2 border rounded"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              Proof
            </label>
            <textarea
              name="proof"
              className="w-full p-2 border rounded"
              rows={4}
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              Public Inputs
            </label>
            <textarea
              name="publicInputs"
              className="w-full p-2 border rounded"
              rows={4}
              required
            />
          </div>

          <div className="flex justify-between items-center">
            <Button 
              type="submit" 
              disabled={loading}
            >
              {loading ? 'Verifying...' : 'Verify Proof'}
            </Button>
            <WalletConnectButton />
          </div>

          {error && (
            <div className="p-4 bg-red-50 text-red-600 rounded">
              {error}
            </div>
          )}

          {txHash && (
            <div className="p-4 bg-green-50 text-green-600 rounded">
              Transaction successful! Hash: {txHash}
            </div>
          )}
        </form>
      )}
    </div>
  );
}