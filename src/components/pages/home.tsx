import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { useScodeConfig } from '@/hooks/use-scode-config';
import { type SoftwareStatus, useSoftware } from '@/hooks/use-software';

interface ToolCardProps {
  status: SoftwareStatus;
  onToggle: (enabled: boolean) => void;
  disabled?: boolean;
}

function ToolCard({ status, onToggle, disabled }: ToolCardProps) {
  const { software, installed, enabled } = status;
  const isDirectMode = software.mode === 'direct';
  const canEnable = isDirectMode || installed;

  return (
    <div className='flex flex-col gap-4 rounded-xl bg-muted/50 p-5'>
      <div className='flex items-center gap-3'>
        <div className='flex size-10 items-center justify-center rounded-full bg-muted'>
          <software.icon className='size-5 text-muted-foreground' />
        </div>
        <div className='flex-1'>
          <h3 className='font-semibold'>{software.name}</h3>
          <p className='text-muted-foreground text-sm'>
            {software.description}
          </p>
        </div>
      </div>

      <div className='flex items-center justify-between'>
        {isDirectMode ? (
          <Badge
            className='border-0 bg-blue-500/10 text-blue-600'
            variant='secondary'
          >
            Available
          </Badge>
        ) : installed ? (
          <Badge
            className='border-0 bg-green-500/10 text-green-600'
            variant='secondary'
          >
            Installed
          </Badge>
        ) : (
          <Badge
            className='border-0 bg-muted text-muted-foreground'
            variant='secondary'
          >
            Not Installed
          </Badge>
        )}

        {canEnable && (
          <Switch
            checked={enabled}
            disabled={disabled}
            onCheckedChange={onToggle}
          />
        )}
      </div>
    </div>
  );
}

export function HomePage() {
  const { allWithStatus } = useSoftware();
  const { toggleEnabled, isToggling } = useScodeConfig();

  const handleToggle = (softwareId: string, enabled: boolean) => {
    toggleEnabled(softwareId, enabled);
  };

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Dashboard</h1>
        <p className='text-muted-foreground'>
          Manage your local configurations
        </p>
      </div>

      <div className='space-y-4'>
        <div className='space-y-1'>
          <h2 className='font-semibold text-lg'>Tools</h2>
          <p className='text-muted-foreground text-sm'>
            Select which tools to show in the sidebar
          </p>
        </div>

        <div className='grid gap-4 md:grid-cols-3'>
          {allWithStatus.map((status) => (
            <ToolCard
              disabled={isToggling}
              key={status.software.id}
              onToggle={(enabled) => handleToggle(status.software.id, enabled)}
              status={status}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
