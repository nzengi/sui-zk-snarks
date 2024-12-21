// src/app/page.tsx
import { ProofForm } from '@/components/verify/proof-form';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white">
      <main className="container mx-auto px-4 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold mb-4">
            ZK-SNARK Verification Platform
          </h1>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Verify zero-knowledge proofs on Sui blockchain with our secure and efficient platform. 
            Connect your wallet to start verifying proofs using BLS12-381 curve.
          </p>
        </div>

        {/* Features */}
        <div className="grid md:grid-cols-3 gap-8 mb-12">
          <div className="bg-gray-800 p-6 rounded-lg">
            <h3 className="text-xl font-semibold mb-2">Secure Verification</h3>
            <p className="text-gray-400">
              Zero-knowledge proof verification using BLS12-381 curve with robust security guarantees.
            </p>
          </div>
          <div className="bg-gray-800 p-6 rounded-lg">
            <h3 className="text-xl font-semibold mb-2">Batch Processing</h3>
            <p className="text-gray-400">
              Efficient batch verification support for multiple proofs in a single transaction.
            </p>
          </div>
          <div className="bg-gray-800 p-6 rounded-lg">
            <h3 className="text-xl font-semibold mb-2">Cost Effective</h3>
            <p className="text-gray-400">
              Optimized gas usage with transparent fee structure and subscription options.
            </p>
          </div>
        </div>

        {/* Verification Form */}
        <div className="max-w-2xl mx-auto bg-gray-800 p-8 rounded-lg shadow-lg">
          <h2 className="text-2xl font-bold mb-6 text-center">
            Verify Your Proof
          </h2>
          <ProofForm />
        </div>

        {/* Documentation Link */}
        <div className="text-center mt-12">
          <a 
            href="https://github.com/yourusername/zk-snark-platform" 
            target="_blank"
            rel="noopener noreferrer"
            className="text-blue-400 hover:text-blue-300"
          >
            View Documentation & Source Code →
          </a>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-800 mt-12">
        <div className="container mx-auto px-4 py-6 text-center text-gray-400">
          <p>Built with ❤️ using Sui Move and Next.js</p>
        </div>
      </footer>
    </div>
  );
}