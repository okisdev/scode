import { FolderOpen, Plug, Settings } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string;
  description: string;
  icon: React.ReactNode;
}

function StatCard({ title, value, description, icon }: StatCardProps) {
  return (
    <div className='flex flex-col gap-2 rounded-xl bg-muted/50 p-5'>
      <div className='flex items-center justify-between'>
        <span className='font-medium text-muted-foreground text-sm'>
          {title}
        </span>
        <div className='flex size-8 items-center justify-center rounded-full bg-muted'>
          {icon}
        </div>
      </div>
      <div className='font-bold text-3xl'>{value}</div>
      <span className='text-muted-foreground text-sm'>{description}</span>
    </div>
  );
}

export function HomePage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Dashboard</h1>
        <p className='text-muted-foreground'>
          Manage your Claude Code configuration and MCP servers
        </p>
      </div>

      <div className='grid gap-4 md:grid-cols-3'>
        <StatCard
          description='Configured servers'
          icon={<Plug className='size-4 text-muted-foreground' />}
          title='MCP Servers'
          value='-'
        />
        <StatCard
          description='Enabled plugins'
          icon={<Settings className='size-4 text-muted-foreground' />}
          title='Plugins'
          value='-'
        />
        <StatCard
          description='Configured projects'
          icon={<FolderOpen className='size-4 text-muted-foreground' />}
          title='Projects'
          value='-'
        />
      </div>
    </div>
  );
}
