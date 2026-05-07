import { Check, Circle, ClipboardList, HandCoins, RefreshCw, X } from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { Badge } from './components/ui/badge';
import { Button } from './components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from './components/ui/card';
import { Progress } from './components/ui/progress';

type ContractVehicle = {
  index: number;
  model: string;
  label: string;
  completed: boolean;
};

type ContractPayload = {
  title: string;
  subtitle: string;
  hint: string;
  vehicles: ContractVehicle[];
  completedCount: number;
  totalCount: number;
  complete: boolean;
};

const emptyContract: ContractPayload = {
  title: 'Active Contract',
  subtitle: 'Street vehicle list',
  hint: 'Find matching vehicles already driving around the city and bring each one to the chop zone.',
  vehicles: [],
  completedCount: 0,
  totalCount: 0,
  complete: false,
};

function getResourceName() {
  return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'chopshop';
}

async function nui(event: string, data?: unknown) {
  await fetch(`https://${getResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  });
}

export function App() {
  const [visible, setVisible] = useState(false);
  const [contract, setContract] = useState<ContractPayload>(emptyContract);

  useEffect(() => {
    const onMessage = (event: MessageEvent<{ action?: string; payload?: ContractPayload }>) => {
      if (event.data.action === 'openContract') {
        setContract(event.data.payload ?? emptyContract);
        setVisible(true);
      }

      if (event.data.action === 'updateContract') {
        setContract(event.data.payload ?? emptyContract);
      }

      if (event.data.action === 'closeContract') {
        setVisible(false);
      }
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setVisible(false);
        void nui('close');
      }
    };

    window.addEventListener('message', onMessage);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('message', onMessage);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, []);

  const progress = useMemo(() => {
    if (contract.totalCount < 1) return 0;
    return (contract.completedCount / contract.totalCount) * 100;
  }, [contract.completedCount, contract.totalCount]);

  if (!visible) return null;

  return (
    <main className="min-h-screen w-screen bg-transparent p-6 text-foreground">
      <div className="pointer-events-none flex min-h-[calc(100vh-48px)] items-center justify-end">
        <Card className="pointer-events-auto w-[430px] overflow-hidden">
          <CardHeader className="border-b border-border bg-card/95">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <Badge className="mb-3 gap-1.5 border-primary/35 text-primary">
                  <ClipboardList className="h-3.5 w-3.5" />
                  {contract.subtitle}
                </Badge>
                <CardTitle>{contract.title}</CardTitle>
                <CardDescription>{contract.hint}</CardDescription>
              </div>
              <Button aria-label="Close" title="Close" variant="ghost" className="h-8 w-8 shrink-0 px-0" onClick={() => void nui('close')}>
                <X className="h-4 w-4" />
              </Button>
            </div>
          </CardHeader>

          <CardContent className="space-y-4">
            <div className="rounded-md border border-border bg-secondary/50 p-3">
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Progress</span>
                <span className="font-medium">
                  {contract.completedCount}/{contract.totalCount}
                </span>
              </div>
              <Progress value={progress} />
            </div>

            <div className="space-y-2">
              {contract.vehicles.map((vehicle) => (
                <div
                  key={`${vehicle.model}-${vehicle.index}`}
                  className="flex min-h-14 items-center gap-3 rounded-md border border-border bg-background/55 px-3 py-2"
                >
                  <div className={vehicle.completed ? 'text-primary' : 'text-muted-foreground'}>
                    {vehicle.completed ? <Check className="h-5 w-5" /> : <Circle className="h-5 w-5" />}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-medium">{vehicle.label}</div>
                    <div className="text-xs uppercase text-muted-foreground">{vehicle.model}</div>
                  </div>
                  <Badge className={vehicle.completed ? 'border-primary/35 text-primary' : undefined}>
                    {vehicle.completed ? 'Done' : `#${vehicle.index}`}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>

          <CardFooter className="justify-between border-t border-border bg-card/95">
            <Button variant="secondary" onClick={() => void nui('refresh')}>
              <RefreshCw className="h-4 w-4" />
              Refresh
            </Button>
            <Button disabled={!contract.complete} onClick={() => void nui('turnIn')}>
              <HandCoins className="h-4 w-4" />
              Turn in
            </Button>
          </CardFooter>
        </Card>
      </div>
    </main>
  );
}

