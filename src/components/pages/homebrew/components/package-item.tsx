import {
  AppWindow,
  ArrowUpCircle,
  Check,
  Download,
  Package as PackageIcon,
  Trash2,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { Cask, Package } from '@/lib/homebrew';

interface PackageItemProps {
  pkg: Package | Cask;
  type: 'formula' | 'cask';
  variant: 'installed' | 'search';
  operating: boolean;
  isInstalled?: boolean;
  onInstall?: () => void;
  onUninstall?: () => void;
  onUpgrade?: () => void;
}

export function PackageItem({
  pkg,
  type,
  variant,
  operating,
  isInstalled,
  onInstall,
  onUninstall,
  onUpgrade,
}: PackageItemProps) {
  const Icon = type === 'cask' ? AppWindow : PackageIcon;
  const showUpgrade = variant === 'installed' && pkg.outdated && onUpgrade;

  return (
    <div className='flex items-center justify-between rounded-lg bg-muted px-3 py-2'>
      <div className='flex min-w-0 flex-1 items-center gap-3'>
        <div className='flex size-8 shrink-0 items-center justify-center rounded-md bg-muted-foreground/10'>
          <Icon className='size-4 text-muted-foreground' />
        </div>
        <div className='flex min-w-0 flex-1 flex-col'>
          <span className='truncate font-medium text-sm'>{pkg.name}</span>
          <span className='truncate text-muted-foreground text-xs'>
            {variant === 'search' && pkg.description ? (
              pkg.description
            ) : (
              <>
                {'current_version' in pkg && pkg.current_version
                  ? pkg.current_version
                  : pkg.version}
                {pkg.outdated &&
                  'latest_version' in pkg &&
                  pkg.latest_version && (
                    <span className='ml-1 text-amber-500'>
                      → {pkg.latest_version}
                    </span>
                  )}
              </>
            )}
          </span>
        </div>
      </div>

      <div className='ml-2 flex shrink-0 items-center gap-1'>
        {variant === 'search' ? (
          <Button
            className='h-7 px-2 text-xs'
            disabled={operating || isInstalled}
            onClick={onInstall}
            size='sm'
            variant={isInstalled ? 'ghost' : 'outline'}
          >
            {isInstalled ? (
              <>
                <Check className='mr-1 size-3' />
                Installed
              </>
            ) : (
              <>
                <Download className='mr-1 size-3' />
                Install
              </>
            )}
          </Button>
        ) : (
          <>
            {showUpgrade && (
              <Button
                className='h-7 px-2 text-xs'
                disabled={operating}
                onClick={onUpgrade}
                size='sm'
                variant='outline'
              >
                <ArrowUpCircle className='mr-1 size-3' />
                Upgrade
              </Button>
            )}
            {onUninstall && (
              <Button
                className='size-7 p-0'
                disabled={operating}
                onClick={onUninstall}
                size='sm'
                variant='ghost'
              >
                <Trash2 className='size-3.5' />
              </Button>
            )}
          </>
        )}
      </div>
    </div>
  );
}
