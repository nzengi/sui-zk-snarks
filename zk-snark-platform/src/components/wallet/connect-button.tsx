'use client';

import { ConnectButton } from '@mysten/dapp-kit';
import { Button } from '@/components/ui/button';
import { ComponentProps } from 'react';

type ConnectButtonRenderProps = ComponentProps<typeof ConnectButton>['children'];

export function WalletConnectButton() {
  return (
    <ConnectButton>
      {({ connected, connecting, connect, disconnect }: ConnectButtonRenderProps) => (
        <Button
          onClick={connected ? disconnect : connect}
          disabled={connecting}
        >
          {connecting ? 'Connecting...' : connected ? 'Disconnect' : 'Connect Wallet'}
        </Button>
      )}
    </ConnectButton>
  );
}