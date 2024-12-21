'use client';

import { ConnectButton } from '@mysten/dapp-kit';
import { Button } from '@/components/ui/button';
import { ReactNode } from 'react';

interface ConnectButtonProps {
  connected: boolean;
  connecting: boolean;
  connect: () => void;
  disconnect: () => void;
}

export function WalletConnectButton() {
  return (
    <ConnectButton>
      {(props: ConnectButtonProps): ReactNode => {
        const { connected, connecting, connect, disconnect } = props;
        return (
          <Button
            onClick={connected ? disconnect : connect}
            disabled={connecting}
          >
            {connecting ? 'Connecting...' : connected ? 'Disconnect' : 'Connect Wallet'}
          </Button>
        );
      }}
    </ConnectButton>
  );
}