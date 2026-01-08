import { Monitor, Moon, Sun } from 'lucide-react';
import { useTheme } from '@/hooks/use-theme';
import { cn } from '@/lib/utils';

type ThemeOption = 'light' | 'dark' | 'system';

interface ThemeCardProps {
  theme: ThemeOption;
  label: string;
  icon: React.ReactNode;
  isActive: boolean;
  onClick: () => void;
}

function ThemeCard({ label, icon, isActive, onClick }: ThemeCardProps) {
  return (
    <button
      className={cn(
        'flex flex-col items-center gap-2 rounded-lg p-4 transition-colors',
        isActive ? 'bg-muted' : 'bg-muted/50 hover:bg-muted'
      )}
      onClick={onClick}
      type='button'
    >
      <div
        className={cn(
          'flex size-9 items-center justify-center rounded-full transition-colors',
          isActive ? 'bg-foreground text-background' : 'bg-background'
        )}
      >
        {icon}
      </div>
      <span className='font-medium text-sm'>{label}</span>
    </button>
  );
}

export function SettingsPage() {
  const { theme, setTheme } = useTheme();

  const themeOptions: {
    value: ThemeOption;
    label: string;
    icon: React.ReactNode;
  }[] = [
    { value: 'light', label: 'Light', icon: <Sun className='size-4' /> },
    { value: 'dark', label: 'Dark', icon: <Moon className='size-4' /> },
    { value: 'system', label: 'System', icon: <Monitor className='size-4' /> },
  ];

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Settings</h1>
        <p className='text-muted-foreground'>Customize your experience</p>
      </div>

      <div className='space-y-4'>
        <div className='space-y-1'>
          <h2 className='font-semibold text-lg'>Appearance</h2>
          <p className='text-muted-foreground text-sm'>
            Choose how Scode looks on your device
          </p>
        </div>

        <div className='grid grid-cols-3 gap-4'>
          {themeOptions.map((option) => (
            <ThemeCard
              icon={option.icon}
              isActive={theme === option.value}
              key={option.value}
              label={option.label}
              onClick={() => setTheme(option.value)}
              theme={option.value}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
