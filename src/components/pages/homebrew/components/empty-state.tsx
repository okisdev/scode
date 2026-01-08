interface EmptyStateProps {
  icon: React.ReactNode;
  message: string;
}

export function EmptyState({ icon, message }: EmptyStateProps) {
  return (
    <div className='flex flex-col items-center gap-2 py-12'>
      {icon}
      <p className='text-muted-foreground'>{message}</p>
    </div>
  );
}
