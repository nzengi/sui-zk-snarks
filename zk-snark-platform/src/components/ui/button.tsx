// src/components/ui/button.tsx
import { ButtonHTMLAttributes } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary';
}

export function Button({ 
  children, 
  variant = 'primary',
  className = '',
  ...props 
}: ButtonProps) {
  return (
    <button
      className={`px-4 py-2 rounded-lg font-medium
        ${variant === 'primary' 
          ? 'bg-blue-500 text-white hover:bg-blue-600' 
          : 'bg-gray-200 text-gray-800 hover:bg-gray-300'}
        ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}