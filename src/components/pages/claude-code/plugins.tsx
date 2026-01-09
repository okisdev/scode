interface SettingSectionProps {
  title: string;
  description: string;
  children: React.ReactNode;
}

function SettingSection({ title, description, children }: SettingSectionProps) {
  return (
    <div className='rounded-xl bg-muted/50 p-5'>
      <div className='space-y-1'>
        <h3 className='font-semibold'>{title}</h3>
        <p className='text-muted-foreground text-sm'>{description}</p>
      </div>
      <div className='mt-4'>{children}</div>
    </div>
  );
}

export function ClaudeCodePluginsPage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Plugins</h1>
        <p className='text-muted-foreground'>Manage installed plugins</p>
      </div>

      <SettingSection description='Manage installed plugins' title='Plugins'>
        <p className='text-muted-foreground text-sm'>~/.claude/plugins/</p>
      </SettingSection>
    </div>
  );
}
