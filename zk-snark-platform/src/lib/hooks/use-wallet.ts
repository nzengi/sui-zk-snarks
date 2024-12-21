// src/lib/hooks/use-wallet.ts
import { useCurrentWallet } from "@mysten/dapp-kit";
import { useEffect } from "react";

export function useWallet() {
  const { currentWallet, isConnected } = useCurrentWallet();

  useEffect(() => {
    if (isConnected && currentWallet) {
      console.log("Wallet connected:", currentWallet.accounts[0]?.address);
    }
  }, [isConnected, currentWallet]);

  return {
    address: currentWallet?.accounts[0]?.address,
    connected: isConnected,
    connect: () => currentWallet?.accounts[0]?.address,
    disconnect: () => undefined,
  };
}
