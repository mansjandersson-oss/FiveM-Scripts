import { Check, FlaskConical, Gauge, Thermometer, Timer, Wine, X } from 'lucide-react';
import { ChangeEvent, FormEvent, useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { Badge } from './components/ui/badge';
import { Button } from './components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from './components/ui/card';
import { cn } from './lib/utils';

type DialogKind = 'ferment' | 'distill' | 'bottle';

type Option = {
  label: string;
  value: string;
};

type Range = {
  min: number;
  max: number;
};

type DialogPayload = {
  title?: string;
  subtitle?: string;
  submitLabel?: string;
  cancelLabel?: string;
  routeLabel?: string;
  sourceLabel?: string;
  productLabel?: string;
  tempLabel?: string;
  timeLabel?: string;
  stirLabel?: string;
  nameLabel?: string;
  nameDescription?: string;
  purityLabel?: string;
  purityDescription?: string;
  routes?: Option[];
  sources?: Option[];
  products?: Record<string, Option[]>;
  temp?: Range;
  time?: Range;
  stir?: Range;
  purity?: Range;
};

type FormValues = Record<string, string | number>;

type NuiMessage = {
  action?: 'openDialog' | 'closeDialog';
  kind?: DialogKind;
  requestId?: number;
  payload?: DialogPayload;
};

const emptyPayload: DialogPayload = {};

function getResourceName() {
  return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'nb-destil';
}

async function nui(event: string, data?: unknown) {
  try {
    await fetch(`https://${getResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    });
  } catch {
    // Vite preview has no FiveM callback endpoint.
  }
}

function firstValue(options?: Option[]) {
  return options?.[0]?.value ?? '';
}

function initialValues(kind: DialogKind, payload: DialogPayload): FormValues {
  if (kind === 'ferment') {
    return {
      route: firstValue(payload.routes),
      temp: payload.temp?.min ?? 18,
      stir: payload.stir?.min ?? 1,
    };
  }

  if (kind === 'distill') {
    const source = firstValue(payload.sources);
    return {
      source,
      product: firstValue(payload.products?.[source]),
      temp: payload.temp?.min ?? 60,
      time: payload.time?.min ?? 20,
    };
  }

  return {
    bottleName: 'House Blend',
    purity: 85,
  };
}

function FieldLabel({ children, icon }: { children: string; icon?: ReactNode }) {
  return (
    <label className="mb-2 flex items-center gap-2 text-sm font-medium text-foreground">
      {icon}
      <span>{children}</span>
    </label>
  );
}

function SelectField({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: Option[];
  onChange: (value: string) => void;
}) {
  return (
    <div>
      <FieldLabel icon={<Wine className="h-4 w-4 text-primary" />}>{label}</FieldLabel>
      <select className="field-control" value={value} onChange={(event) => onChange(event.target.value)}>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  );
}

function NumberField({
  label,
  value,
  range,
  icon,
  onChange,
}: {
  label: string;
  value: number;
  range?: Range;
  icon: ReactNode;
  onChange: (value: number) => void;
}) {
  return (
    <div>
      <FieldLabel icon={icon}>{label}</FieldLabel>
      <div className="grid grid-cols-[1fr_76px] gap-3">
        <input
          className="accent-primary"
          type="range"
          min={range?.min}
          max={range?.max}
          value={value}
          onChange={(event) => onChange(Number(event.target.value))}
        />
        <input
          className="field-control text-center"
          type="number"
          min={range?.min}
          max={range?.max}
          value={value}
          onChange={(event) => onChange(Number(event.target.value))}
        />
      </div>
    </div>
  );
}

export function App() {
  const [visible, setVisible] = useState(false);
  const [kind, setKind] = useState<DialogKind>('ferment');
  const [requestId, setRequestId] = useState<number | null>(null);
  const [payload, setPayload] = useState<DialogPayload>(emptyPayload);
  const [values, setValues] = useState<FormValues>(() => initialValues('ferment', emptyPayload));

  useEffect(() => {
    const onMessage = (event: MessageEvent<NuiMessage>) => {
      if (event.data.action === 'openDialog' && event.data.kind && event.data.requestId) {
        const nextPayload = event.data.payload ?? emptyPayload;
        setKind(event.data.kind);
        setPayload(nextPayload);
        setRequestId(event.data.requestId);
        setValues(initialValues(event.data.kind, nextPayload));
        setVisible(true);
      }

      if (event.data.action === 'closeDialog') {
        setVisible(false);
      }
    };

    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && requestId) {
        setVisible(false);
        void nui('closeDialog', { requestId });
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [requestId]);

  const productsForSource = useMemo(() => {
    const source = String(values.source ?? '');
    return payload.products?.[source] ?? [];
  }, [payload.products, values.source]);

  function setValue(key: string, value: string | number) {
    setValues((current) => ({ ...current, [key]: value }));
  }

  function onSourceChange(value: string) {
    const nextProduct = firstValue(payload.products?.[value]);
    setValues((current) => ({ ...current, source: value, product: nextProduct }));
  }

  function close() {
    if (!requestId) return;
    setVisible(false);
    void nui('closeDialog', { requestId });
  }

  function submit(event: FormEvent) {
    event.preventDefault();
    if (!requestId) return;

    const nextValues =
      kind === 'bottle'
        ? {
            bottleName: String(values.bottleName ?? '').trim(),
            purity: Number(values.purity ?? 0),
          }
        : Object.fromEntries(Object.entries(values).map(([key, value]) => [key, typeof value === 'number' ? value : String(value)]));

    setVisible(false);
    void nui('submitDialog', { requestId, values: nextValues });
  }

  if (!visible) return null;

  const title = payload.title ?? 'NB Destil';
  const subtitle = payload.subtitle ?? (kind === 'distill' ? 'Distillery run' : kind === 'bottle' ? 'Bottle run' : 'Fermentation run');

  return (
    <main className="min-h-screen w-screen bg-transparent p-6 text-foreground">
      <div className="pointer-events-none flex min-h-[calc(100vh-48px)] items-center justify-center">
        <Card className="pointer-events-auto w-[430px] overflow-hidden">
          <form onSubmit={submit}>
            <CardHeader className="border-b border-border bg-card/95">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <Badge className="mb-3 gap-1.5 border-primary/35 text-primary">
                    <FlaskConical className="h-3.5 w-3.5" />
                    {subtitle}
                  </Badge>
                  <CardTitle>{title}</CardTitle>
                  <CardDescription>NB Destil</CardDescription>
                </div>
                <Button aria-label="Close" title="Close" type="button" variant="ghost" className="h-8 w-8 shrink-0 px-0" onClick={close}>
                  <X className="h-4 w-4" />
                </Button>
              </div>
            </CardHeader>

            <CardContent className="space-y-4">
              {kind === 'ferment' && (
                <>
                  <SelectField
                    label={payload.routeLabel ?? 'Mash type'}
                    value={String(values.route ?? '')}
                    options={payload.routes ?? []}
                    onChange={(value) => setValue('route', value)}
                  />
                  <NumberField
                    label={payload.tempLabel ?? 'Temperature'}
                    value={Number(values.temp ?? payload.temp?.min ?? 0)}
                    range={payload.temp}
                    icon={<Thermometer className="h-4 w-4 text-primary" />}
                    onChange={(value) => setValue('temp', value)}
                  />
                  <NumberField
                    label={payload.stirLabel ?? 'Stir'}
                    value={Number(values.stir ?? payload.stir?.min ?? 0)}
                    range={payload.stir}
                    icon={<Gauge className="h-4 w-4 text-primary" />}
                    onChange={(value) => setValue('stir', value)}
                  />
                </>
              )}

              {kind === 'distill' && (
                <>
                  <SelectField
                    label={payload.sourceLabel ?? 'Mash source'}
                    value={String(values.source ?? '')}
                    options={payload.sources ?? []}
                    onChange={onSourceChange}
                  />
                  <SelectField
                    label={payload.productLabel ?? 'Product'}
                    value={String(values.product ?? '')}
                    options={productsForSource}
                    onChange={(value) => setValue('product', value)}
                  />
                  <NumberField
                    label={payload.tempLabel ?? 'Temperature'}
                    value={Number(values.temp ?? payload.temp?.min ?? 0)}
                    range={payload.temp}
                    icon={<Thermometer className="h-4 w-4 text-primary" />}
                    onChange={(value) => setValue('temp', value)}
                  />
                  <NumberField
                    label={payload.timeLabel ?? 'Time'}
                    value={Number(values.time ?? payload.time?.min ?? 0)}
                    range={payload.time}
                    icon={<Timer className="h-4 w-4 text-primary" />}
                    onChange={(value) => setValue('time', value)}
                  />
                </>
              )}

              {kind === 'bottle' && (
                <>
                  <div>
                    <FieldLabel icon={<Wine className="h-4 w-4 text-primary" />}>{payload.nameLabel ?? 'Bottle name'}</FieldLabel>
                    <input
                      className="field-control"
                      maxLength={24}
                      value={String(values.bottleName ?? '')}
                      onChange={(event: ChangeEvent<HTMLInputElement>) => setValue('bottleName', event.target.value)}
                    />
                    <p className="mt-1 text-xs text-muted-foreground">{payload.nameDescription}</p>
                  </div>
                  <NumberField
                    label={payload.purityLabel ?? 'Purity'}
                    value={Number(values.purity ?? payload.purity?.min ?? 70)}
                    range={payload.purity}
                    icon={<Gauge className="h-4 w-4 text-primary" />}
                    onChange={(value) => setValue('purity', value)}
                  />
                  <p className={cn('text-xs text-muted-foreground', !payload.purityDescription && 'hidden')}>{payload.purityDescription}</p>
                </>
              )}
            </CardContent>

            <CardFooter className="justify-end border-t border-border bg-card/95">
              <Button type="button" variant="secondary" onClick={close}>
                <X className="h-4 w-4" />
                {payload.cancelLabel ?? 'Cancel'}
              </Button>
              <Button type="submit">
                <Check className="h-4 w-4" />
                {payload.submitLabel ?? 'Confirm'}
              </Button>
            </CardFooter>
          </form>
        </Card>
      </div>
    </main>
  );
}
