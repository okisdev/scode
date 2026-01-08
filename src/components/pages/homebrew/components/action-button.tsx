import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface ActionButtonProps {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
  disabled?: boolean;
  loading?: boolean;
  variant?: 'default' | 'outline' | 'destructive';
}

export function ActionButton({
  icon,
  label,
  onClick,
  disabled,
  loading,
  variant = 'outline',
}: ActionButtonProps) {
  return (
    <Button
      className='gap-2'
      disabled={disabled || loading}
      onClick={onClick}
      size='sm'
      variant={variant}
    >
      {loading ? <Loader2 className='size-4 animate-spin' /> : icon}
      {label}
    </Button>
  );
}
