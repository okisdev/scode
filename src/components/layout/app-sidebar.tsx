import { Home } from 'lucide-react';
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from '@/components/ui/sidebar';
import { useSoftware } from '@/hooks/use-software';

interface AppSidebarProps {
  currentPage: string;
  onNavigate: (page: string) => void;
}

export function AppSidebar({ currentPage, onNavigate }: AppSidebarProps) {
  const { installed } = useSoftware();

  return (
    <Sidebar variant='inset'>
      <SidebarHeader>
        <div className='flex items-center gap-2 px-2 py-2'>
          <span className='font-semibold'>Scode</span>
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton
                  isActive={currentPage === 'home'}
                  onClick={() => onNavigate('home')}
                  tooltip='Home'
                >
                  <Home />
                  <span>Home</span>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        <SidebarGroup>
          <SidebarGroupLabel>Software</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {installed.map((software) => (
                <SidebarMenuItem key={software.id}>
                  <SidebarMenuButton
                    isActive={currentPage === software.id}
                    onClick={() => onNavigate(software.id)}
                    tooltip={software.name}
                  >
                    <software.icon />
                    <span>{software.name}</span>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
    </Sidebar>
  );
}
