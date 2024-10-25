import { ChartCandlestick, ChevronRight, Frame, LucideIcon, PieChart } from "lucide-react";

import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuAction,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { cn } from "@/lib/utils";

type NavItemType = {
  name: string;
  url: string;
  icon: LucideIcon;
};

const nav = {
  explorer: [
    {
      name: "Pumping tokens",
      url: "/",
      icon: ChartCandlestick,
    },
  ],
  analytics: [
    {
      name: "Global",
      url: "#",
      icon: Frame,
    },
    {
      name: "Data analysis",
      url: "#",
      icon: PieChart,
    },
  ],
} as const satisfies Record<string, NavItemType[]>;

export const AppSidebar = () => {
  return (
    <>
      <Sidebar collapsible="icon" variant="floating">
        <SidebarContent>
          {Object.entries(nav).map(([key, value]) => {
            return (
              <SidebarGroup key={key}>
                <SidebarGroupLabel>{key}</SidebarGroupLabel>
                <SidebarMenu>
                  {value.map((item) => (
                    <NavItem key={item.name} {...item} />
                  ))}
                </SidebarMenu>
              </SidebarGroup>
            );
          })}
        </SidebarContent>
        <SidebarTrigger className="absolute bottom-4 right-[18px]" />
      </Sidebar>
    </>
  );
};

const NavItem = (item: NavItemType) => {
  return (
    <SidebarMenuItem key={item.name} className={cn(window.location.pathname.includes(item.url) && "bg-sidebar-accent")}>
      <SidebarMenuButton asChild>
        <a href={item.url} className="text-sidebar-foreground">
          <item.icon />
          <span>{item.name}</span>
        </a>
      </SidebarMenuButton>
      <SidebarMenuAction asChild showOnHover onClick={() => (window.location.href = item.url)}>
        <ChevronRight className="size-4" />
      </SidebarMenuAction>
    </SidebarMenuItem>
  );
};
