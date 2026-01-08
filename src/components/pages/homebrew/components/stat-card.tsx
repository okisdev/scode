import { Skeleton } from '@/components/ui/skeleton';

interface StatCardProps {
  title: string;
  value: string | number;
  description: string;
  icon: React.ReactNode;
  loading?: boolean;
}

export function StatCard({
  title,
  value,
  description,
  icon,
  loading,
}: StatCardProps) {
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
      {loading ? (
        <Skeleton className='h-9 w-16' />
      ) : (
        <div className='font-bold text-3xl'>{value}</div>
      )}
      <span className='text-muted-foreground text-sm'>{description}</span>
    </div>
  );
}
