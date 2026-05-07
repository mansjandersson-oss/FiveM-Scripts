import * as React from 'react';
import { cn } from '../../lib/utils';

export function Progress({ value, className }: { value: number; className?: string }) {
  return (
    <div className={cn('h-2 overflow-hidden rounded-sm bg-secondary', className)}>
      <div className="h-full rounded-sm bg-primary transition-all" style={{ width: `${Math.max(0, Math.min(100, value))}%` }} />
    </div>
  );
}

