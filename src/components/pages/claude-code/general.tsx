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

export function ClaudeCodeGeneralPage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>General</h1>
        <p className='text-muted-foreground'>General Claude Code settings</p>
      </div>

      <SettingSection
        description='Configure sandbox settings'
        title='Sandbox Mode'
      >
        <p className='text-muted-foreground text-sm'>
          ~/.claude/settings.local.json
        </p>
      </SettingSection>
    </div>
  );
}
