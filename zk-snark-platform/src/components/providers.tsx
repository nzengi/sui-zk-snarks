// src/components/providers.tsx
'use client';

import { SuiClientProvider, WalletProvider } from '@mysten/dapp-kit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { SuiClient } from '@mysten/sui/client';

const queryClient = new QueryClient();

// Create Sui clients for each network
const networks = {
  testnet: new SuiClient({ url: 'https://fullnode.testnet.sui.io:443' }),
  mainnet: new SuiClient({ url: 'https://fullnode.mainnet.sui.io:443' }),
};

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <SuiClientProvider networks={networks} defaultNetwork="testnet">
        <WalletProvider
          autoConnect
          preferredWallets={['Sui Wallet', 'Ethos Wallet', 'Suiet']}
        >
          {children}
        </WalletProvider>
      </SuiClientProvider>
    </QueryClientProvider>
  );
}