import { Skeleton } from '@/components/ui/skeleton';
import { useSoftware } from '@/hooks/use-software';

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

function StatCardSkeleton() {
  return (
    <div className='flex flex-col gap-2 rounded-xl bg-muted/50 p-5'>
      <div className='flex items-center justify-between'>
        <Skeleton className='h-4 w-20' />
        <Skeleton className='size-8 rounded-full' />
      </div>
      <Skeleton className='h-9 w-12' />
      <Skeleton className='h-4 w-32' />
    </div>
  );
}

export function HomePage() {
  const { installed, loading } = useSoftware();

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Dashboard</h1>
        <p className='text-muted-foreground'>
          Manage your local configurations
        </p>
      </div>

      <div className='grid gap-4 md:grid-cols-3'>
        {loading ? (
          <>
            <StatCardSkeleton />
            <StatCardSkeleton />
            <StatCardSkeleton />
          </>
        ) : installed.length > 0 ? (
          installed.map((software) => (
            <StatCard
              description={software.description}
              icon={<software.icon className='size-4 text-muted-foreground' />}
              key={software.id}
              title={software.name}
              value='-'
            />
          ))
        ) : (
          <div className='col-span-3 rounded-xl bg-muted/50 p-8 text-center'>
            <p className='text-muted-foreground'>No software detected</p>
          </div>
        )}
      </div>
    </div>
  );
}
