import { listen } from '@tauri-apps/api/event';
import { fetch } from '@tauri-apps/plugin-http';
import { openUrl } from '@tauri-apps/plugin-opener';
import { format } from 'date-fns';
import {
  Bug,
  CheckCircle,
  Download,
  Github,
  Loader2,
  RefreshCw,
  XCircle,
} from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

type UpdateStatus =
  | { state: 'idle' }
  | { state: 'checking' }
  | { state: 'up-to-date' }
  | { state: 'update-available'; version: string; url: string }
  | { state: 'error'; message: string };

interface GitHubRelease {
  tag_name: string;
  html_url: string;
}

const VERSION_PREFIX_REGEX = /^v/;

function compareVersions(current: string, latest: string): number {
  const normalize = (v: string) =>
    v
      .replace(VERSION_PREFIX_REGEX, '')
      .split('.')
      .map((n) => Number.parseInt(n, 10) || 0);
  const c = normalize(current);
  const l = normalize(latest);
  for (let i = 0; i < Math.max(c.length, l.length); i++) {
    const diff = (l[i] || 0) - (c[i] || 0);
    if (diff !== 0) {
      return diff;
    }
  }
  return 0;
}

export function AboutDialog() {
  const [open, setOpen] = useState(false);
  const [updateStatus, setUpdateStatus] = useState<UpdateStatus>({
    state: 'idle',
  });

  const checkForUpdates = useCallback(async () => {
    setUpdateStatus({ state: 'checking' });
    try {
      const response = await fetch(
        'https://api.github.com/repos/okisdev/scode/releases/latest',
        {
          method: 'GET',
          headers: {
            Accept: 'application/vnd.github.v3+json',
            'User-Agent': 'Scode',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = (await response.json()) as GitHubRelease;
      const latestVersion = data.tag_name.replace(VERSION_PREFIX_REGEX, '');
      const comparison = compareVersions(__APP_VERSION__, latestVersion);

      if (comparison > 0) {
        setUpdateStatus({
          state: 'update-available',
          version: latestVersion,
          url: data.html_url,
        });
      } else {
        setUpdateStatus({ state: 'up-to-date' });
      }
    } catch (error) {
      setUpdateStatus({
        state: 'error',
        message: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }, []);

  useEffect(() => {
    const unlisten = listen('show-about', () => {
      setOpen(true);
    });

    return () => {
      unlisten.then((fn) => fn());
    };
  }, []);

  const buildTime = format(new Date(__BUILD_TIME__), 'yyyy-MM-dd HH:mm');

  const renderUpdateStatus = () => {
    switch (updateStatus.state) {
      case 'idle':
        return (
          <button
            className='text-muted-foreground transition-colors hover:text-foreground'
            onClick={checkForUpdates}
            title='Check for updates'
            type='button'
          >
            <RefreshCw className='size-3.5' />
          </button>
        );
      case 'checking':
        return (
          <Loader2 className='size-3.5 animate-spin text-muted-foreground' />
        );
      case 'up-to-date':
        return (
          <span className='flex items-center gap-1 text-green-600 text-xs'>
            <CheckCircle className='size-3' />
            Latest
          </span>
        );
      case 'update-available':
        return (
          <button
            className='flex items-center gap-1 text-blue-600 text-xs transition-colors hover:text-blue-700'
            onClick={() => openUrl(updateStatus.url)}
            type='button'
          >
            <Download className='size-3' />v{updateStatus.version}
          </button>
        );
      case 'error':
        return (
          <button
            className='text-red-500 transition-colors hover:text-red-600'
            onClick={checkForUpdates}
            title='Retry'
            type='button'
          >
            <XCircle className='size-3.5' />
          </button>
        );
      default:
        return null;
    }
  };

  return (
    <Dialog onOpenChange={setOpen} open={open}>
      <DialogContent className='max-w-xs' showCloseButton={false}>
        <DialogHeader className='items-center'>
          <div className='flex size-16 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600'>
            <span className='font-bold text-2xl text-white'>S</span>
          </div>
          <DialogTitle className='text-center text-xl'>Scode</DialogTitle>
          <DialogDescription className='text-center'>
            GUI for local configurations
          </DialogDescription>
        </DialogHeader>

        <div className='space-y-1 rounded-lg bg-muted/50 px-3 py-2 text-sm'>
          <div className='flex items-center justify-between'>
            <span className='text-muted-foreground'>Version</span>
            <span className='flex items-center gap-2'>
              <span className='font-mono'>
                {__APP_VERSION__} ({__BUILD_HASH__})
              </span>
              {renderUpdateStatus()}
            </span>
          </div>
          <div className='flex items-center justify-between'>
            <span className='text-muted-foreground'>Build Time</span>
            <span>{buildTime}</span>
          </div>
        </div>

        <div className='grid grid-cols-2 gap-2'>
          <button
            className='flex items-center justify-center gap-1.5 rounded-lg bg-muted/50 px-3 py-2 text-sm transition-colors hover:bg-muted'
            onClick={() => openUrl('https://github.com/okisdev/scode')}
            type='button'
          >
            <Github className='size-4' />
            <span>GitHub</span>
          </button>
          <button
            className='flex items-center justify-center gap-1.5 rounded-lg bg-muted/50 px-3 py-2 text-sm transition-colors hover:bg-muted'
            onClick={() => openUrl('https://github.com/okisdev/scode/issues')}
            type='button'
          >
            <Bug className='size-4' />
            <span>Issue</span>
          </button>
        </div>

        <p className='text-center text-muted-foreground text-xs'>
          Made by Harry Yep
        </p>
      </DialogContent>
    </Dialog>
  );
}
