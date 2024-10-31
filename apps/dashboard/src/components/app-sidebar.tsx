import { ChartCandlestick, Check, ChevronRight, Frame, Globe, LucideIcon, PieChart, Pill } from "lucide-react";
import { Link, useLocation, useNavigate } from "react-router-dom";

import { Button } from "@/components/ui/button";
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
import { useTrackerParams } from "@/hooks/use-tracker-params";
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
      url: "/analytics",
      icon: Frame,
    },
    {
      name: "Data analysis",
      url: "/data-analysis",
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
          <div className="flex-1" />
          <Footer />
          <div className="h-12" />
        </SidebarContent>
        <SidebarTrigger className="absolute bottom-4 right-[18px]" />
      </Sidebar>
    </>
  );
};

const Footer = () => {
  const { onlyPumpTokens, setOnlyPumpTokens } = useTrackerParams();

  return (
    <div className="flex flex-col">
      <Button
        variant="secondary"
        onClick={() => setOnlyPumpTokens(false)}
        className={cn("flex gap-2 items-center justify-start", onlyPumpTokens && "bg-transparent")}
      >
        <Globe className="size-4" />
        <span className="flex-1 text-left">All tokens</span>
        {!onlyPumpTokens && <Check className="size-4" />}
      </Button>
      <Button
        variant="secondary"
        onClick={() => setOnlyPumpTokens(true)}
        className={cn("flex gap-2 items-center justify-start", !onlyPumpTokens && "bg-transparent")}
      >
        <Pill className="size-4" />
        <span className="flex-1 text-left">pump.fun tokens</span>
        {onlyPumpTokens && <Check className="size-4" />}
      </Button>
    </div>
  );
};

const NavItem = (item: NavItemType) => {
  const navigate = useNavigate();
  const pathname = useLocation().pathname;

  return (
    <SidebarMenuItem key={item.name} className={cn(pathname === item.url && "bg-sidebar-accent")}>
      <SidebarMenuButton asChild>
        <Link to={item.url} className="text-sidebar-foreground">
          <item.icon />
          <span>{item.name}</span>
        </Link>
      </SidebarMenuButton>
      <SidebarMenuAction asChild showOnHover onClick={() => navigate(item.url)}>
        <ChevronRight className="size-4" />
      </SidebarMenuAction>
    </SidebarMenuItem>
  );
};
