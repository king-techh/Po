#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║                                                              ║
# ║   ████████╗██╗███████╗██╗  ██╗███████╗██╗      ██████╗ ██╗  ║
# ║   ╚══██╔══╝██║██╔════╝██║ ██╔╝██╔════╝██║     ██╔═══██╗██║  ║
# ║      ██║   ██║███████╗█████╔╝ █████╗  ██║     ██║   ██║██║  ║
# ║      ██║   ██║╚════██║██╔═██╗ ██╔══╝  ██║     ██║   ██║██║  ║
# ║      ██║   ██║███████║██║  ██╗███████╗███████╗╚██████╔╝██║  ║
# ║      ╚═╝   ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ║
# ║                                                              ║
# ║         ToxicSSH - Auto Installer v2.0                       ║
# ║         Premium SSH & VPN Account Platform                    ║
# ║         by Toxic Tech Kenya                                  ║
# ║                                                              ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage: bash install-toxicssh.sh
#
# This script will:
# 1. Install Node.js 20 + Bun
# 2. Create ToxicSSH project
# 3. Build & start on port 3000
# 4. Auto-seed your server
# 5. Setup systemd service for auto-restart
#
# ═══════════════════════════════════════════════════════════════

set -e

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ─── Config ───
APP_DIR="/root/toxicssh"
APP_PORT=3000
APP_NAME="toxicssh"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║   ${CYAN}ToxicSSH${GREEN} - Auto Installer v2.0                          ║${NC}"
echo -e "${GREEN}║   Premium SSH & VPN Account Platform                         ║${NC}"
echo -e "${GREEN}║   by ${PURPLE}Toxic Tech Kenya${GREEN}                                    ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ─── Get server info ───
echo -e "${CYAN}[?] Server Configuration${NC}"
echo -e "${YELLOW}─────────────────────────${NC}"

# Get server hostname/IP
DEFAULT_HOST=$(hostname -f 2>/dev/null || curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")
read -p "Server Host/IP [${DEFAULT_HOST}]: " SERVER_HOST
SERVER_HOST=${SERVER_HOST:-$DEFAULT_HOST}

read -p "SSH Root Password (for account creation): " SSH_PASSWORD
if [ -z "$SSH_PASSWORD" ]; then
  echo -e "${RED}Error: SSH password is required for creating accounts on this server${NC}"
  exit 1
fi

DEFAULT_COUNTRY="Kenya"
read -p "Server Country [${DEFAULT_COUNTRY}]: " SERVER_COUNTRY
SERVER_COUNTRY=${SERVER_COUNTRY:-$DEFAULT_COUNTRY}

DEFAULT_CODE="KE"
read -p "Country Code [${DEFAULT_CODE}]: " COUNTRY_CODE
COUNTRY_CODE=${COUNTRY_CODE:-$DEFAULT_CODE}

SERVER_NAME="Toxic Tech Kenya - ${SERVER_COUNTRY}"

echo ""
echo -e "${GREEN}[✓] Configuration saved${NC}"
echo ""

# ─── Step 1: Install Node.js ───
echo -e "${CYAN}[1/7] Installing Node.js 20...${NC}"
if command -v node &> /dev/null && [[ $(node -v) == v20* || $(node -v) == v22* ]]; then
  echo -e "${GREEN}  ✓ Node.js $(node -v) already installed${NC}"
else
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &> /dev/null
  apt-get install -y nodejs &> /dev/null
  echo -e "${GREEN}  ✓ Node.js $(node -v) installed${NC}"
fi

# ─── Step 2: Install Bun ───
echo -e "${CYAN}[2/7] Installing Bun...${NC}"
if command -v bun &> /dev/null; then
  echo -e "${GREEN}  ✓ Bun already installed${NC}"
else
  curl -fsSL https://bun.sh/install | bash &> /dev/null
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  echo -e "${GREEN}  ✓ Bun installed${NC}"
fi

# ─── Step 3: Create project ───
echo -e "${CYAN}[3/7] Creating ToxicSSH project...${NC}"

rm -rf ${APP_DIR}
mkdir -p ${APP_DIR}
cd ${APP_DIR}

# Init project
cat > package.json << 'PKGJSON'
{
  "name": "toxicssh",
  "version": "2.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "NODE_ENV=production node .next/standalone/server.js",
    "db:push": "prisma db push",
    "db:generate": "prisma generate"
  }
}
PKGJSON

# ─── Step 4: Install dependencies ───
echo -e "${CYAN}[4/7] Installing dependencies...${NC}"
bun add next@latest react@latest react-dom@latest \
  @prisma/client@latest prisma@latest \
  ssh2 framer-motion lucide-react \
  class-variance-authority clsx tailwind-merge \
  @radix-ui/react-dialog @radix-ui/react-label @radix-ui/react-progress \
  @radix-ui/react-select @radix-ui/react-tabs @radix-ui/react-toast \
  @radix-ui/react-slot sonner tailwindcss@latest \
  @tailwindcss/postcss zod react-hook-form next-themes \
  @hookform/resolvers uuid &> /dev/null

bun add -d @types/react @types/react-dom @types/node @types/ssh2 \
  @tailwindcss/postcss typescript eslint eslint-config-next postcss &> /dev/null

echo -e "${GREEN}  ✓ Dependencies installed${NC}"

# ─── Create all project files ───
echo -e "${CYAN}[5/7] Creating project files...${NC}"

# tsconfig.json
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TSCONFIG

# next.config.ts
cat > next.config.ts << 'NEXTCONFIG'
import type { NextConfig } from "next";
const nextConfig: NextConfig = {
  output: "standalone",
};
export default nextConfig;
NEXTCONFIG

# postcss.config.mjs
cat > postcss.config.mjs << 'POSTCSS'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
export default config;
POSTCSS

# .env
cat > .env << ENV
DATABASE_URL="file:./db/custom.db"
NODE_ENV="production"
ENV

# ─── Prisma Schema ───
mkdir -p prisma db src/lib src/app/api/servers src/app/api/accounts src/app/api/setup src/components/ui

cat > prisma/schema.prisma << 'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model Server {
  id            String   @id @default(cuid())
  name          String
  country       String
  countryCode   String   @default("SG")
  host          String
  sshPort       Int      @default(22)
  dropbearPort  Int      @default(443)
  v2rayPort     Int      @default(443)
  sslPort       Int      @default(443)
  wsPort        Int      @default(80)
  sshUser       String   @default("root")
  sshKey        String?
  sshPassword   String?
  status        String   @default("online")
  maxAccounts   Int      @default(100)
  activeAccounts Int     @default(0)
  bandwidth     String   @default("Unlimited")
  premium       Boolean  @default(false)
  load          Int      @default(0)
  ping          Int      @default(0)
  uptime        String   @default("99.9%")
  protocols     String   @default("ssh,ssl,v2ray,ws")
  order         Int      @default(0)
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  accounts      Account[]
}

model Account {
  id             String   @id @default(cuid())
  username       String   @unique
  password       String
  serverId       String
  protocol       String   @default("ssh")
  duration       Int      @default(7)
  maxDevices     Int      @default(2)
  usedDevices    Int      @default(0)
  bandwidthUsed  Float    @default(0)
  bandwidthLimit Float?
  v2rayUuid      String?
  isActive       Boolean  @default(true)
  isPremium      Boolean  @default(false)
  expiresAt      DateTime
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt
  server         Server   @relation(fields: [serverId], references: [id], onDelete: Cascade)
}

model SiteSettings {
  id            String   @id @default(cuid())
  siteName      String   @default("ToxicSSH")
  tagline       String   @default("Premium SSH & VPN Accounts")
  domain        String   @default("toxictech.guru")
  telegramUrl   String?
  whatsappUrl   String?
  premiumPrice  String   @default("KES 500/mo")
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}
PRISMA

# ─── DB Client ───
cat > src/lib/db.ts << 'DBTS'
import { PrismaClient } from '@prisma/client'
const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined }
export const db = globalForPrisma.prisma ?? new PrismaClient()
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
DBTS

# ─── Utils ───
cat > src/lib/utils.ts << 'UTILS'
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"
export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)) }
UTILS

# ─── SSH Manager ───
cat > src/lib/ssh-manager.ts << 'SSHMGR'
import { Client } from 'ssh2';
import type { ConnectConfig } from 'ssh2';

interface SSHResult { success: boolean; output: string; error?: string; }

function connectAndExecute(config: ConnectConfig, command: string): Promise<SSHResult> {
  return new Promise((resolve) => {
    const conn = new Client();
    conn.on('ready', () => {
      conn.exec(command, (err, stream) => {
        if (err) { conn.end(); resolve({ success: false, output: '', error: err.message }); return; }
        let output = '', errorOutput = '';
        stream.on('data', (data: Buffer) => { output += data.toString(); });
        stream.stderr.on('data', (data: Buffer) => { errorOutput += data.toString(); });
        stream.on('close', (code: number) => { conn.end(); resolve({ success: code === 0, output: output.trim(), error: errorOutput.trim() || undefined }); });
      });
    });
    conn.on('error', (err) => { resolve({ success: false, output: '', error: err.message }); });
    conn.connect(config);
  });
}

export interface VPSServerConfig {
  host: string; port?: number; username: string; password?: string; privateKey?: string;
}

function buildConfig(vps: VPSServerConfig): ConnectConfig {
  const config: ConnectConfig = { host: vps.host, port: vps.port || 22, username: vps.username, readyTimeout: 15000 };
  if (vps.privateKey) { config.privateKey = Buffer.from(vps.privateKey, 'base64').toString(); }
  else if (vps.password) { config.password = vps.password; }
  return config;
}

export async function createSSHAccount(vps: VPSServerConfig, username: string, password: string, durationDays: number): Promise<SSHResult> {
  const expiryDate = new Date(); expiryDate.setDate(expiryDate.getDate() + durationDays);
  const expiryStr = expiryDate.toISOString().split('T')[0];
  const command = `useradd -M -s /usr/sbin/nologin "${username}" 2>/dev/null || true && echo "${username}:${password}" | chpasswd && chage -E "${expiryStr}" "${username}" && usermod -aG ssh-users "${username}" 2>/dev/null || true && echo "Account created: ${username} Expires: ${expiryStr}"`;
  return connectAndExecute(buildConfig(vps), command);
}

export async function deleteSSHAccount(vps: VPSServerConfig, username: string): Promise<SSHResult> {
  return connectAndExecute(buildConfig(vps), `userdel -f "${username}" 2>/dev/null || true && echo "Deleted: ${username}"`);
}

export async function getServerStatus(vps: VPSServerConfig) {
  const command = `echo "CPU:$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)" && echo "RAM:$(free | grep Mem | awk '{print ($3/$2)*100}')" && echo "UPTIME:$(uptime -p 2>/dev/null || echo unknown)" && echo "USERS:$(who | wc -l)"`;
  try {
    const result = await connectAndExecute(buildConfig(vps), command);
    if (!result.success) return { online: false, cpu: 0, ram: 0, uptime: 'N/A', activeUsers: 0 };
    const parse = (prefix: string) => { const l = result.output.split('\n').find(x => x.startsWith(prefix)); return l ? l.split(':')[1] : '0'; };
    return { online: true, cpu: parseFloat(parse('CPU:')) || 0, ram: parseFloat(parse('RAM:')) || 0, uptime: parse('UPTIME:') || 'N/A', activeUsers: parseInt(parse('USERS:')) || 0 };
  } catch { return { online: false, cpu: 0, ram: 0, uptime: 'N/A', activeUsers: 0 }; }
}

export async function createV2RayAccount(vps: VPSServerConfig, username: string, durationDays: number): Promise<{ result: SSHResult; uuid: string }> {
  const { randomUUID } = require('crypto');
  const uuid = randomUUID();
  const command = `useradd -M -s /usr/sbin/nologin "v2_${username}" 2>/dev/null || true && echo "V2Ray UUID: ${uuid}" && echo "Account: ${username}"`;
  const result = await connectAndExecute(buildConfig(vps), command);
  return { result, uuid };
}
SSHMGR

echo -e "${GREEN}  ✓ Core files created${NC}"

# ─── API Routes ───

# Servers API
cat > src/app/api/servers/route.ts << 'SERVERSAPI'
import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function GET() {
  try {
    const servers = await db.server.findMany({ orderBy: { order: 'asc' }, include: { _count: { select: { accounts: { where: { isActive: true } } } } } });
    const result = servers.map(s => ({
      id: s.id, name: s.name, country: s.country, countryCode: s.countryCode,
      host: s.host, sshPort: s.sshPort, dropbearPort: s.dropbearPort, v2rayPort: s.v2rayPort,
      sslPort: s.sslPort, wsPort: s.wsPort, status: s.status, maxAccounts: s.maxAccounts,
      activeAccounts: s._count.accounts, bandwidth: s.bandwidth, premium: s.premium,
      load: s.load, ping: s.ping, uptime: s.uptime, protocols: s.protocols.split(','),
    }));
    return NextResponse.json({ servers: result });
  } catch (error) { return NextResponse.json({ error: 'Failed to fetch servers' }, { status: 500 }); }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const server = await db.server.create({ data: {
      name: body.name, country: body.country, countryCode: body.countryCode || 'KE',
      host: body.host, sshPort: body.sshPort || 22, dropbearPort: body.dropbearPort || 443,
      v2rayPort: body.v2rayPort || 443, sslPort: body.sslPort || 443, wsPort: body.wsPort || 80,
      sshUser: body.sshUser || 'root', sshPassword: body.sshPassword || null, sshKey: body.sshKey || null,
      status: body.status || 'online', maxAccounts: body.maxAccounts || 100,
      bandwidth: body.bandwidth || 'Unlimited', premium: body.premium || false,
      protocols: (body.protocols || ['ssh','ssl','v2ray','ws']).join(','), order: body.order || 0,
    }});
    return NextResponse.json({ server });
  } catch (error) { return NextResponse.json({ error: 'Failed to create server' }, { status: 500 }); }
}
SERVERSAPI

# Accounts API
cat > src/app/api/accounts/route.ts << 'ACCOUNTSAPI'
import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { createSSHAccount, deleteSSHAccount, createV2RayAccount } from '@/lib/ssh-manager';
import crypto from 'crypto';

function genUser(prefix = 'toxic'): string { const c = 'abcdefghijklmnopqrstuvwxyz0123456789'; let s = ''; for (let i = 0; i < 6; i++) s += c[Math.floor(Math.random() * c.length)]; return prefix + s; }
function genPass(len = 12): string { const c = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789'; let p = ''; for (let i = 0; i < len; i++) p += c[Math.floor(Math.random() * c.length)]; return p; }

export async function POST(req: Request) {
  try {
    const { serverId, protocol, duration, username: customUsername } = await req.json();
    if (!serverId || !protocol || !duration) return NextResponse.json({ error: 'Missing: serverId, protocol, duration' }, { status: 400 });
    const server = await db.server.findUnique({ where: { id: serverId } });
    if (!server) return NextResponse.json({ error: 'Server not found' }, { status: 404 });
    if (server.status !== 'online') return NextResponse.json({ error: 'Server offline' }, { status: 400 });
    const activeCount = await db.account.count({ where: { serverId, isActive: true } });
    if (activeCount >= server.maxAccounts) return NextResponse.json({ error: 'Server full' }, { status: 400 });

    const username = customUsername || genUser();
    const password = genPass();
    const expiresAt = new Date(); expiresAt.setDate(expiresAt.getDate() + duration);
    let vpsResult: any = null; let v2rayUuid: string | null = null;

    if (server.sshPassword || server.sshKey) {
      try {
        const vpsConfig = { host: server.host, port: server.sshPort, username: server.sshUser, password: server.sshPassword || undefined, privateKey: server.sshKey || undefined };
        if (protocol === 'v2ray') { const r = await createV2RayAccount(vpsConfig, username, duration); vpsResult = r.result; v2rayUuid = r.uuid; }
        else { vpsResult = await createSSHAccount(vpsConfig, username, password, duration); }
      } catch (err) { vpsResult = { success: false, output: '', error: 'SSH connection failed' }; }
    } else { vpsResult = { success: false, output: '', error: 'No SSH credentials' }; }

    const account = await db.account.create({ data: { username, password, serverId, protocol, duration, expiresAt, v2rayUuid, isPremium: server.premium } });
    await db.server.update({ where: { id: serverId }, data: { activeAccounts: activeCount + 1 } });

    return NextResponse.json({ success: true, account: {
      id: account.id, username: account.username, password: account.password, protocol: account.protocol,
      duration: account.duration, expiresAt: account.expiresAt, host: server.host, sshPort: server.sshPort,
      dropbearPort: server.dropbearPort, v2rayPort: server.v2rayPort, sslPort: server.sslPort, wsPort: server.wsPort,
      v2rayUuid, serverName: server.name, country: server.country,
      vpsCreated: vpsResult?.success || false, vpsMessage: vpsResult?.output || vpsResult?.error || 'VPS not connected',
    }});
  } catch (error) { console.error(error); return NextResponse.json({ error: 'Failed to create account' }, { status: 500 }); }
}

export async function DELETE(req: Request) {
  try {
    const id = new URL(req.url).searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'Account ID required' }, { status: 400 });
    const account = await db.account.findUnique({ where: { id }, include: { server: true } });
    if (!account) return NextResponse.json({ error: 'Not found' }, { status: 404 });
    if (account.server.sshPassword || account.server.sshKey) {
      try { await deleteSSHAccount({ host: account.server.host, port: account.server.sshPort, username: account.server.sshUser, password: account.server.sshPassword || undefined, privateKey: account.server.sshKey || undefined }, account.username); } catch {}
    }
    await db.account.update({ where: { id }, data: { isActive: false } });
    const c = await db.account.count({ where: { serverId: account.serverId, isActive: true } });
    await db.server.update({ where: { id: account.serverId }, data: { activeAccounts: c } });
    return NextResponse.json({ success: true });
  } catch (error) { return NextResponse.json({ error: 'Failed' }, { status: 500 }); }
}

export async function GET(req: Request) {
  try {
    const username = new URL(req.url).searchParams.get('username');
    if (username) {
      const account = await db.account.findUnique({ where: { username }, include: { server: true } });
      if (!account) return NextResponse.json({ error: 'Not found' }, { status: 404 });
      return NextResponse.json({ account: { id: account.id, username: account.username, protocol: account.protocol, duration: account.duration, expiresAt: account.expiresAt, isActive: account.isActive, host: account.server.host, sshPort: account.server.sshPort, serverName: account.server.name, country: account.server.country } });
    }
    const accounts = await db.account.findMany({ where: { isActive: true }, orderBy: { createdAt: 'desc' }, take: 50, include: { server: true } });
    return NextResponse.json({ accounts });
  } catch (error) { return NextResponse.json({ error: 'Failed' }, { status: 500 }); }
}
ACCOUNTSAPI

# Setup API
cat > src/app/api/setup/route.ts << 'SETUPAPI'
import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const existing = await db.server.findFirst({ where: { host: body.host || 'toxictech.guru' } });
    if (existing) return NextResponse.json({ message: 'Server exists', server: existing });
    const server = await db.server.create({ data: {
      name: body.name || 'Server 1', country: body.country || 'Kenya', countryCode: body.countryCode || 'KE',
      host: body.host, sshPort: body.sshPort || 22, dropbearPort: body.dropbearPort || 443,
      v2rayPort: body.v2rayPort || 443, sslPort: body.sslPort || 443, wsPort: body.wsPort || 80,
      sshUser: body.sshUser || 'root', sshPassword: body.sshPassword || null, sshKey: body.sshKey || null,
      status: 'online', maxAccounts: body.maxAccounts || 100, bandwidth: body.bandwidth || 'Unlimited',
      premium: false, load: 15, ping: 12, uptime: '99.9%', protocols: 'ssh,ssl,v2ray,ws', order: 1,
    }});
    const existingSettings = await db.siteSettings.findFirst();
    if (!existingSettings) { await db.siteSettings.create({ data: { siteName: 'ToxicSSH', tagline: 'Premium SSH & VPN', domain: body.host, telegramUrl: body.telegramUrl, whatsappUrl: body.whatsappUrl } }); }
    return NextResponse.json({ success: true, server });
  } catch (error) { return NextResponse.json({ error: 'Setup failed' }, { status: 500 }); }
}
SETUPAPI

echo -e "${GREEN}  ✓ API routes created${NC}"

# ─── UI Components (minimal set) ───

cat > src/components/ui/button.tsx << 'BUTTON'
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"
const buttonVariants = cva("inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] shadow-xs px-4 py-2 has-[>svg]:px-3", {
  variants: {
    variant: { default: "bg-primary text-primary-foreground hover:bg-primary/90", destructive: "bg-destructive text-white hover:bg-destructive/90", outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground", secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80", ghost: "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50", link: "text-primary underline-offset-4 hover:underline" },
    size: { default: "h-9 px-4 py-2", sm: "h-8 rounded-md px-3 text-xs", lg: "h-10 rounded-md px-6", icon: "size-9" }
  }, defaultVariants: { variant: "default", size: "default" }
})
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>, VariantProps<typeof buttonVariants> { asChild?: boolean }
const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(({ className, variant, size, asChild = false, ...props }, ref) => { const Comp = asChild ? Slot : "button"; return <Comp className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} /> })
Button.displayName = "Button"
export { Button, buttonVariants }
BUTTON

cat > src/components/ui/card.tsx << 'CARD'
import * as React from "react"
import { cn } from "@/lib/utils"
const Card = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => <div ref={ref} className={cn("rounded-xl border py-6 shadow-sm", className)} {...props} />)
const CardHeader = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => <div ref={ref} className={cn("flex flex-col space-y-1.5 px-6", className)} {...props} />)
const CardTitle = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => <div ref={ref} className={cn("font-semibold leading-none tracking-tight", className)} {...props} />)
const CardDescription = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => <div ref={ref} className={cn("text-sm text-muted-foreground", className)} {...props} />)
const CardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => <div ref={ref} className={cn("px-6", className)} {...props} />)
Card.displayName = "Card"; CardHeader.displayName = "CardHeader"; CardTitle.displayName = "CardTitle"; CardDescription.displayName = "CardDescription"; CardContent.displayName = "CardContent"
export { Card, CardHeader, CardTitle, CardDescription, CardContent }
CARD

cat > src/components/ui/input.tsx << 'INPUT'
import * as React from "react"
import { cn } from "@/lib/utils"
const Input = React.forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(({ className, type, ...props }, ref) => <input type={type} className={cn("flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50", className)} ref={ref} {...props} />)
Input.displayName = "Input"
export { Input }
INPUT

cat > src/components/ui/label.tsx << 'LABEL'
import * as React from "react"
import * as LabelPrimitive from "@radix-ui/react-label"
import { cn } from "@/lib/utils"
const Label = React.forwardRef<React.ComponentRef<typeof LabelPrimitive.Root>, React.ComponentPropsWithoutRef<typeof LabelPrimitive.Root>>(({ className, ...props }, ref) => <LabelPrimitive.Root ref={ref} className={cn("flex items-center gap-2 font-medium select-none group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50 peer-disabled:cursor-not-allowed peer-disabled:opacity-50 text-sm", className)} {...props} />)
Label.displayName = "Label"
export { Label }
LABEL

cat > src/components/ui/badge.tsx << 'BADGE'
import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"
const badgeVariants = cva("inline-flex items-center justify-center rounded-md border px-2 py-0.5 font-medium w-fit whitespace-nowrap shrink-0 [&>svg]:size-3 gap-1 [&>svg]:pointer-events-none transition-[color,box-shadow] overflow-hidden", {
  variants: { variant: { default: "border-transparent bg-primary text-primary-foreground shadow-sm", secondary: "border-transparent bg-secondary text-secondary-foreground", destructive: "border-transparent bg-destructive text-white shadow-sm", outline: "text-foreground" } },
  defaultVariants: { variant: "default" }
})
function Badge({ className, variant, ...props }: React.HTMLAttributes<HTMLDivElement> & VariantProps<typeof badgeVariants>) { return <div className={cn(badgeVariants({ variant }), className)} {...props} /> }
export { Badge, badgeVariants }
BADGE

cat > src/components/ui/progress.tsx << 'PROGRESS'
import * as React from "react"
import * as ProgressPrimitive from "@radix-ui/react-progress"
import { cn } from "@/lib/utils"
const Progress = React.forwardRef<React.ComponentRef<typeof ProgressPrimitive.Root>, React.ComponentPropsWithoutRef<typeof ProgressPrimitive.Root>>(({ className, value, ...props }, ref) => <ProgressPrimitive.Root ref={ref} className={cn("relative h-2 w-full overflow-hidden rounded-full bg-primary/20", className)} {...props}><ProgressPrimitive.Indicator data-slot="indicator" className="h-full w-full flex-1 bg-primary transition-all" style={{ transform: `translateX(-${100 - (value || 0)}%)` }} /></ProgressPrimitive.Root>)
Progress.displayName = "Progress"
export { Progress }
PROGRESS

cat > src/components/ui/toaster.tsx << 'TOASTER'
"use client"
import { Toaster as Sonner } from "sonner"
function Toaster() { return <Sonner position="top-right" richColors closeButton /> }
export { Toaster }
TOASTER

echo -e "${GREEN}  ✓ UI components created${NC}"

# ─── Global CSS ───
cat > src/app/globals.css << 'GCSS'
@import "tailwindcss";
@custom-variant dark (&:is(.dark *));
@theme inline {
  --color-background: var(--background); --color-foreground: var(--foreground);
  --font-sans: var(--font-geist-sans); --font-mono: var(--font-geist-mono);
  --color-ring: var(--ring); --color-input: var(--input); --color-border: var(--border);
  --color-destructive: var(--destructive); --color-accent-foreground: var(--accent-foreground);
  --color-accent: var(--accent); --color-muted-foreground: var(--muted-foreground);
  --color-muted: var(--muted); --color-secondary-foreground: var(--secondary-foreground);
  --color-secondary: var(--secondary); --color-primary-foreground: var(--primary-foreground);
  --color-primary: var(--primary); --color-card-foreground: var(--card-foreground);
  --color-card: var(--card); --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px); --radius-lg: var(--radius);
  --color-toxic-green: #00ff88; --color-toxic-purple: #8b5cf6;
  --color-toxic-dark: #0a0a0f; --color-toxic-card: #111118;
  --color-toxic-border: #1e1e2e; --color-toxic-glow: rgba(0,255,136,0.15);
}
:root {
  --radius: 0.75rem; --background: #0a0a0f; --foreground: #e4e4e7;
  --card: #111118; --card-foreground: #e4e4e7;
  --primary: #00ff88; --primary-foreground: #0a0a0f;
  --secondary: #1a1a2e; --secondary-foreground: #e4e4e7;
  --muted: #16161e; --muted-foreground: #71717a;
  --accent: #8b5cf6; --accent-foreground: #ffffff;
  --destructive: #ef4444; --border: #1e1e2e; --input: #1e1e2e; --ring: #00ff88;
}
@layer base { * { @apply border-border outline-ring/50; } body { @apply bg-background text-foreground; } }
::-webkit-scrollbar { width: 6px; } ::-webkit-scrollbar-track { background: #0a0a0f; }
::-webkit-scrollbar-thumb { background: #1e1e2e; border-radius: 3px; }
.toxic-glow { box-shadow: 0 0 20px rgba(0,255,136,0.15), 0 0 40px rgba(0,255,136,0.05); }
.toxic-glow-purple { box-shadow: 0 0 20px rgba(139,92,246,0.15), 0 0 40px rgba(139,92,246,0.05); }
.toxic-text-glow { text-shadow: 0 0 10px rgba(0,255,136,0.5), 0 0 20px rgba(0,255,136,0.2); }
@keyframes toxic-pulse { 0%,100% { opacity:1; } 50% { opacity:0.5; } }
.animate-toxic-pulse { animation: toxic-pulse 2s ease-in-out infinite; }
.toxic-grid { background-image: linear-gradient(rgba(0,255,136,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(0,255,136,0.03) 1px, transparent 1px); background-size: 50px 50px; }
.toxic-card-hover { transition: all 0.3s ease; }
.toxic-card-hover:hover { transform: translateY(-2px); border-color: rgba(0,255,136,0.3); box-shadow: 0 8px 30px rgba(0,255,136,0.1); }
GCSS

# ─── Layout ───
cat > src/app/layout.tsx << 'LAYOUT'
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });
export const metadata: Metadata = { title: "ToxicSSH - Premium SSH & VPN Accounts", description: "Create free and premium SSH, SSL, V2Ray, and WebSocket VPN accounts. Powered by Toxic Tech Kenya." };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en" className="dark" suppressHydrationWarning><body className={`${geistSans.variable} ${geistMono.variable} antialiased bg-background text-foreground`}>{children}<Toaster /></body></html>;
}
LAYOUT

echo -e "${GREEN}  ✓ Layout & styles created${NC}"

# ─── Main Page (the big one) ───
echo -e "${CYAN}  Creating main page...${NC}"

cat > src/app/page.tsx << 'PAGEEOF'
'use client';
import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Shield, Server, Zap, Globe, Clock, Users, Signal, Lock, Copy, Eye, EyeOff, Sparkles, AlertTriangle, CheckCircle2, Menu, Phone, MessageCircle, Rocket, Cpu, HardDrive, Activity, Fingerprint, KeyRound, MonitorSmartphone, Terminal, Wifi } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { toast } from 'sonner';

interface ServerInfo { id:string; name:string; country:string; countryCode:string; host:string; sshPort:number; dropbearPort:number; v2rayPort:number; sslPort:number; wsPort:number; status:string; maxAccounts:number; activeAccounts:number; bandwidth:string; premium:boolean; load:number; ping:number; uptime:string; protocols:string[]; }
interface AccountInfo { id:string; username:string; password:string; protocol:string; duration:number; expiresAt:string; host:string; sshPort:number; dropbearPort:number; v2rayPort:number; sslPort:number; wsPort:number; v2rayUuid:string|null; serverName:string; country:string; vpsCreated:boolean; vpsMessage:string; }

const flags: Record<string,string> = { KE:'🇰🇪', SG:'🇸🇬', US:'🇺🇸', DE:'🇩🇪', NL:'🇳🇱', JP:'🇯🇵', IN:'🇮🇳', CA:'🇨🇦', UK:'🇬🇧', AU:'🇦🇺', FR:'🇫🇷', KR:'🇰🇷' };
const protocols: Record<string,{label:string;icon:React.ReactNode;color:string;desc:string}> = {
  ssh:{ label:'SSH', icon:<Terminal className="w-4 h-4"/>, color:'text-green-400', desc:'SSH Tunnel - Port 22/443' },
  ssl:{ label:'SSL/TLS', icon:<Lock className="w-4 h-4"/>, color:'text-blue-400', desc:'SSL Tunnel - Port 443' },
  v2ray:{ label:'V2Ray', icon:<Globe className="w-4 h-4"/>, color:'text-purple-400', desc:'V2Ray VMess Protocol' },
  ws:{ label:'WebSocket', icon:<Wifi className="w-4 h-4"/>, color:'text-cyan-400', desc:'WebSocket Tunnel - Port 80' },
};
const durations = [
  {v:1,l:'1 Day',p:false},{v:3,l:'3 Days',p:false},{v:7,l:'7 Days',p:false},
  {v:14,l:'14 Days',p:false},{v:30,l:'30 Days',p:true},{v:90,l:'90 Days',p:true},
];

function PlusIcon(){return <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 5v14M5 12h14"/></svg>}

export default function ToxicSSHPage(){
  const [servers,setServers]=useState<ServerInfo[]>([]);
  const [loading,setLoading]=useState(true);
  const [selServer,setSelServer]=useState<ServerInfo|null>(null);
  const [selProto,setSelProto]=useState('ssh');
  const [selDur,setSelDur]=useState(7);
  const [creating,setCreating]=useState(false);
  const [account,setAccount]=useState<AccountInfo|null>(null);
  const [showPw,setShowPw]=useState(false);
  const [tab,setTab]=useState('create');
  const [checking,setChecking]=useState(false);
  const [lookupUser,setLookupUser]=useState('');
  const [lookupRes,setLookupRes]=useState<any>(null);
  const [showSetup,setShowSetup]=useState(false);
  const [mobileMenu,setMobileMenu]=useState(false);
  const [setup,setSetupForm]=useState({host:'',sshUser:'root',sshPassword:'',name:'',country:'Kenya',countryCode:'KE'});

  const fetchServers=useCallback(async()=>{
    try{const r=await fetch('/api/servers');const d=await r.json();if(d.servers?.length){setServers(d.servers);if(!selServer)setSelServer(d.servers[0])}else setShowSetup(true)}catch{}finally{setLoading(false)}
  },[]);

  useEffect(()=>{fetchServers()},[fetchServers]);

  const handleSetup=async()=>{
    try{const r=await fetch('/api/setup',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(setup)});const d=await r.json();if(d.success||d.server){toast.success('Server configured!');setShowSetup(false);fetchServers()}else toast.error(d.error||'Setup failed')}catch{toast.error('Setup failed')}
  };

  const handleCreate=async()=>{
    if(!selServer){toast.error('Select a server');return}
    setCreating(true);
    try{const r=await fetch('/api/accounts',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({serverId:selServer.id,protocol:selProto,duration:selDur})});const d=await r.json();if(d.success){setAccount(d.account);setTab('account');toast.success('Account created!');fetchServers()}else toast.error(d.error||'Failed')}catch{toast.error('Failed')}finally{setCreating(false)}
  };

  const handleCheck=async()=>{
    if(!lookupUser.trim())return;setChecking(true);
    try{const r=await fetch(`/api/accounts?username=${encodeURIComponent(lookupUser)}`);const d=await r.json();if(d.account)setLookupRes(d.account);else{toast.error('Not found');setLookupRes(null)}}catch{toast.error('Failed')}finally{setChecking(false)}
  };

  const copy=(t:string,l:string)=>{navigator.clipboard.writeText(t);toast.success(l+' copied!')};
  const fmtDate=(d:string)=>new Date(d).toLocaleDateString('en-KE',{year:'numeric',month:'short',day:'numeric',hour:'2-digit',minute:'2-digit'});

  if(showSetup){
    return <div className="min-h-screen flex items-center justify-center p-4 toxic-grid">
      <motion.div initial={{opacity:0,scale:0.95}} animate={{opacity:1,scale:1}} className="w-full max-w-md">
        <Card className="border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)] toxic-glow">
          <CardContent className="p-6 space-y-4">
            <div className="text-center"><div className="flex items-center justify-center gap-2 mb-2"><Shield className="w-8 h-8 text-[var(--color-toxic-green)]"/><h1 className="text-2xl font-bold text-[var(--color-toxic-green)] toxic-text-glow">ToxicSSH</h1></div><p className="text-sm text-muted-foreground">Initial Server Setup</p></div>
            <div className="space-y-2"><Label className="text-sm">Server Name</Label><Input value={setup.name} onChange={e=>setSetupForm(p=>({...p,name:e.target.value}))} className="bg-[var(--color-toxic-dark)] border-[var(--color-toxic-border)]" placeholder="My VPN Server"/></div>
            <div className="space-y-2"><Label className="text-sm">Server Host / IP</Label><Input value={setup.host} onChange={e=>setSetupForm(p=>({...p,host:e.target.value}))} className="bg-[var(--color-toxic-dark)] border-[var(--color-toxic-border)]" placeholder="toxictech.guru"/></div>
            <div className="grid grid-cols-2 gap-3"><div className="space-y-2"><Label className="text-sm">SSH User</Label><Input value={setup.sshUser} onChange={e=>setSetupForm(p=>({...p,sshUser:e.target.value}))} className="bg-[var(--color-toxic-dark)] border-[var(--color-toxic-border)]" placeholder="root"/></div><div className="space-y-2"><Label className="text-sm">SSH Password</Label><Input type="password" value={setup.sshPassword} onChange={e=>setSetupForm(p=>({...p,sshPassword:e.target.value}))} className="bg-[var(--color-toxic-dark)] border-[var(--color-toxic-border)]" placeholder="VPS password"/></div></div>
            <div className="grid grid-cols-2 gap-3"><div className="space-y-2"><Label className="text-sm">Country</Label><Input value={setup.country} onChange={e=>setSetupForm(p=>({...p,country:e.target.value}))} className="bg-[var(--color-toxic-dark)] border-[var(--color-toxic-border)]" placeholder="Kenya"/></div><div className="space-y-2"><Label className="text-sm">Code</Label><Input value={setup.countryCode} onChange={e=>setSetupForm(p=>({...p,countryCode:e.target.value.toUpperCase()}))} className="bg-[var(--color-toxic-dark)] border-[var(--color-toxic-border)]" maxLength={2} placeholder="KE"/></div></div>
            <Button onClick={handleSetup} className="w-full bg-[var(--color-toxic-green)] text-[var(--color-toxic-dark)] hover:bg-[var(--color-toxic-green)]/90 font-semibold"><Rocket className="w-4 h-4 mr-2"/>Setup Server</Button>
          </CardContent>
        </Card>
      </motion.div>
    </div>;
  }

  return <div className="min-h-screen flex flex-col toxic-grid">
    <header className="sticky top-0 z-50 border-b border-[var(--color-toxic-border)] bg-[var(--color-toxic-dark)]/80 backdrop-blur-xl">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2"><Shield className="w-6 h-6 text-[var(--color-toxic-green)]"/><span className="text-lg font-bold text-[var(--color-toxic-green)] toxic-text-glow">ToxicSSH</span><Badge variant="outline" className="text-[10px] border-[var(--color-toxic-green)]/30 text-[var(--color-toxic-green)] ml-1 hidden sm:inline-flex">v2.0</Badge></div>
        <nav className="hidden md:flex items-center gap-1">{[{id:'create',label:'Create',icon:<PlusIcon/>},{id:'servers',label:'Servers',icon:<Server className="w-4 h-4"/>},{id:'check',label:'Check Account',icon:<Fingerprint className="w-4 h-4"/>},{id:'premium',label:'Premium',icon:<Sparkles className="w-4 h-4"/>}].map(t=><button key={t.id} onClick={()=>setTab(t.id)} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm transition-all ${tab===t.id?'bg-[var(--color-toxic-green)]/10 text-[var(--color-toxic-green)]':'text-muted-foreground hover:text-foreground hover:bg-white/5'}`}>{t.icon}{t.label}</button>)}</nav>
        <div className="flex items-center gap-2"><a href="https://t.me/toxictechke" target="_blank" className="hidden sm:flex items-center gap-1 text-xs text-muted-foreground hover:text-[var(--color-toxic-green)] transition-colors"><MessageCircle className="w-3.5 h-3.5"/>Telegram</a><Button variant="ghost" size="icon" className="md:hidden" onClick={()=>setMobileMenu(!mobileMenu)}><Menu className="w-5 h-5"/></Button></div>
      </div>
      <AnimatePresence>{mobileMenu&&<motion.div initial={{height:0,opacity:0}} animate={{height:'auto',opacity:1}} exit={{height:0,opacity:0}} className="md:hidden border-t border-[var(--color-toxic-border)] overflow-hidden"><div className="p-3 flex flex-col gap-1">{[{id:'create',label:'Create Account',icon:<PlusIcon/>},{id:'servers',label:'Servers',icon:<Server className="w-4 h-4"/>},{id:'check',label:'Check Account',icon:<Fingerprint className="w-4 h-4"/>},{id:'premium',label:'Premium',icon:<Sparkles className="w-4 h-4"/>}].map(t=><button key={t.id} onClick={()=>{setTab(t.id);setMobileMenu(false)}} className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm ${tab===t.id?'bg-[var(--color-toxic-green)]/10 text-[var(--color-toxic-green)]':'text-muted-foreground'}`}>{t.icon}{t.label}</button>)}</div></motion.div>}</AnimatePresence>
    </header>

    <main className="flex-1 max-w-7xl mx-auto w-full px-4 sm:px-6 py-6">
      <AnimatePresence mode="wait">
        {tab==='create'&&<motion.div key="create" initial={{opacity:0,y:10}} animate={{opacity:1,y:0}} exit={{opacity:0,y:-10}} className="space-y-6">
          <div className="text-center space-y-3 py-4"><motion.div initial={{scale:0.9}} animate={{scale:1}} transition={{type:'spring',stiffness:200}}><h1 className="text-3xl sm:text-4xl font-bold"><span className="text-[var(--color-toxic-green)] toxic-text-glow">Toxic</span><span className="text-foreground">SSH</span></h1></motion.div><p className="text-muted-foreground text-sm sm:text-base max-w-md mx-auto">Create free & premium SSH, SSL, V2Ray, and WebSocket VPN accounts. Fast, secure, unlimited bandwidth.</p><div className="flex items-center justify-center gap-4 text-xs text-muted-foreground"><span className="flex items-center gap-1"><Shield className="w-3 h-3 text-[var(--color-toxic-green)]"/>Secure</span><span className="flex items-center gap-1"><Zap className="w-3 h-3 text-[var(--color-toxic-green)]"/>Fast</span><span className="flex items-center gap-1"><Globe className="w-3 h-3 text-[var(--color-toxic-green)]"/>Global</span><span className="flex items-center gap-1"><Signal className="w-3 h-3 text-[var(--color-toxic-green)]"/>Unlimited</span></div></div>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 space-y-4"><h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider flex items-center gap-2"><Server className="w-4 h-4 text-[var(--color-toxic-green)]"/>Select Server</h2>
              {loading?<div className="grid grid-cols-1 sm:grid-cols-2 gap-3">{[1,2].map(i=><div key={i} className="h-32 rounded-lg bg-[var(--color-toxic-card)] animate-pulse border border-[var(--color-toxic-border)]"/>)}</div>
              :servers.length===0?<Card className="border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)]"><CardContent className="py-8 text-center"><AlertTriangle className="w-8 h-8 text-yellow-500 mx-auto mb-2"/><p className="text-sm text-muted-foreground">No servers</p><Button onClick={()=>setShowSetup(true)} variant="outline" className="mt-3 border-[var(--color-toxic-green)]/30 text-[var(--color-toxic-green)]">Setup Server</Button></CardContent></Card>
              :<div className="grid grid-cols-1 sm:grid-cols-2 gap-3">{servers.map(s=><motion.div key={s.id} whileHover={{scale:1.01}} whileTap={{scale:0.99}}><Card className={`cursor-pointer toxic-card-hover border transition-all ${selServer?.id===s.id?'border-[var(--color-toxic-green)]/50 toxic-glow bg-[var(--color-toxic-green)]/5':'border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)] hover:border-[var(--color-toxic-green)]/20'}`} onClick={()=>setSelServer(s)}><CardContent className="p-4"><div className="flex items-start justify-between"><div className="flex items-center gap-2"><span className="text-xl">{flags[s.countryCode]||'🌍'}</span><div><h3 className="font-semibold text-sm">{s.name}</h3><p className="text-xs text-muted-foreground">{s.country}</p></div></div><div className="flex items-center gap-1">{s.status==='online'?<span className="flex items-center gap-1 text-[10px] text-green-400"><span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-toxic-pulse"/>Online</span>:<span className="text-[10px] text-red-400">Offline</span>}{s.premium&&<Badge className="text-[9px] bg-[var(--color-toxic-purple)]/20 text-[var(--color-toxic-purple)] border-0 px-1 py-0">PRO</Badge>}</div></div><div className="mt-3 grid grid-cols-3 gap-2 text-[10px] text-muted-foreground"><div className="flex items-center gap-1"><Activity className="w-3 h-3"/><span>{s.load}%</span></div><div className="flex items-center gap-1"><Clock className="w-3 h-3"/><span>{s.uptime}</span></div><div className="flex items-center gap-1"><Users className="w-3 h-3"/><span>{s.activeAccounts}/{s.maxAccounts}</span></div></div><div className="mt-2 flex flex-wrap gap-1">{s.protocols.map(p=><span key={p} className={`text-[9px] px-1.5 py-0.5 rounded ${protocols[p]?.color||'text-gray-400'} bg-white/5`}>{(protocols[p]?.label||p).toUpperCase()}</span>)}</div><div className="mt-2"><Progress value={(s.activeAccounts/s.maxAccounts)*100} className="h-1 bg-white/5 [&>[data-slot=indicator]]:bg-[var(--color-toxic-green)]"/></div></CardContent></Card></motion.div>)}</div>}
            </div>
            <div className="space-y-4"><h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider flex items-center gap-2"><KeyRound className="w-4 h-4 text-[var(--color-toxic-green)]"/>Account Details</h2>
              <Card className="border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)]"><CardContent className="p-4 space-y-4">
                <div className="space-y-2"><Label className="text-xs text-muted-foreground">Protocol</Label><div className="grid grid-cols-2 gap-2">{Object.entries(protocols).map(([k,v])=>{const avail=selServer?.protocols.includes(k);return <button key={k} disabled={!avail} onClick={()=>setSelProto(k)} className={`flex flex-col items-center gap-1 p-2.5 rounded-lg text-xs transition-all border ${selProto===k?'border-[var(--color-toxic-green)]/50 bg-[var(--color-toxic-green)]/5 toxic-glow':avail?'border-[var(--color-toxic-border)] hover:border-[var(--color-toxic-green)]/20':'border-[var(--color-toxic-border)]/50 opacity-30 cursor-not-allowed'}`}><span className={selProto===k?'text-[var(--color-toxic-green)]':v.color}>{v.icon}</span><span className={selProto===k?'text-[var(--color-toxic-green)]':''}>{v.label}</span></button>})}</div><p className="text-[10px] text-muted-foreground">{protocols[selProto]?.desc}</p></div>
                <div className="space-y-2"><Label className="text-xs text-muted-foreground">Duration</Label><div className="grid grid-cols-3 gap-2">{durations.map(d=><button key={d.v} onClick={()=>setSelDur(d.v)} className={`relative p-2 rounded-lg text-xs transition-all border ${selDur===d.v?'border-[var(--color-toxic-green)]/50 bg-[var(--color-toxic-green)]/5':d.p?'border-[var(--color-toxic-purple)]/30 bg-[var(--color-toxic-purple)]/5 hover:border-[var(--color-toxic-purple)]/50':'border-[var(--color-toxic-border)] hover:border-[var(--color-toxic-green)]/20'}`}>{d.p&&<Sparkles className="w-2.5 h-2.5 text-[var(--color-toxic-purple)] absolute top-1 right-1"/>}<span className={selDur===d.v?'text-[var(--color-toxic-green)]':''}>{d.l}</span></button>)}</div></div>
                {selServer&&<div className="rounded-lg bg-[var(--color-toxic-dark)] p-3 space-y-2 text-xs"><div className="flex justify-between"><span className="text-muted-foreground">Server</span><span>{selServer.name}</span></div><div className="flex justify-between"><span className="text-muted-foreground">Host</span><span className="font-mono">{selServer.host}</span></div><div className="flex justify-between"><span className="text-muted-foreground">Protocol</span><span className={protocols[selProto]?.color}>{protocols[selProto]?.label}</span></div><div className="flex justify-between"><span className="text-muted-foreground">Duration</span><span>{selDur} days</span></div><div className="flex justify-between"><span className="text-muted-foreground">Bandwidth</span><span className="text-[var(--color-toxic-green)]">{selServer.bandwidth}</span></div></div>}
                <Button onClick={handleCreate} disabled={creating||!selServer} className="w-full bg-[var(--color-toxic-green)] text-[var(--color-toxic-dark)] hover:bg-[var(--color-toxic-green)]/90 font-bold text-sm h-11">{creating?<span className="flex items-center gap-2"><span className="w-4 h-4 border-2 border-[var(--color-toxic-dark)]/30 border-t-[var(--color-toxic-dark)] rounded-full animate-spin"/>Creating...</span>:<span className="flex items-center gap-2"><Zap className="w-4 h-4"/>Create Account</span>}</Button>
              </CardContent></Card>
            </div>
          </div>
        </motion.div>}

        {tab==='account'&&account&&<motion.div key="account" initial={{opacity:0,y:10}} animate={{opacity:1,y:0}} exit={{opacity:0,y:-10}} className="max-w-2xl mx-auto space-y-4">
          <div className="text-center py-4"><motion.div initial={{scale:0}} animate={{scale:1}} transition={{type:'spring',stiffness:300,delay:0.1}}><CheckCircle2 className="w-16 h-16 text-[var(--color-toxic-green)] mx-auto mb-3"/></motion.div><h2 className="text-2xl font-bold">Account Created!</h2><p className="text-sm text-muted-foreground mt-1">Your {protocols[account.protocol]?.label} account is ready</p></div>
          <Card className="border-[var(--color-toxic-green)]/20 bg-[var(--color-toxic-card)] toxic-glow"><CardContent className="p-5 space-y-4">
            <h3 className="text-sm font-semibold text-[var(--color-toxic-green)] flex items-center gap-2"><KeyRound className="w-4 h-4"/>Credentials</h3>
            <div className="flex items-center justify-between p-3 rounded-lg bg-[var(--color-toxic-dark)]"><div><span className="text-[10px] text-muted-foreground block">Username</span><span className="font-mono text-sm">{account.username}</span></div><Button variant="ghost" size="icon" className="h-8 w-8" onClick={()=>copy(account.username,'Username')}><Copy className="w-3.5 h-3.5"/></Button></div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-[var(--color-toxic-dark)]"><div><span className="text-[10px] text-muted-foreground block">Password</span><span className="font-mono text-sm">{showPw?account.password:'••••••••••••'}</span></div><div className="flex gap-1"><Button variant="ghost" size="icon" className="h-8 w-8" onClick={()=>setShowPw(!showPw)}>{showPw?<EyeOff className="w-3.5 h-3.5"/>:<Eye className="w-3.5 h-3.5"/>}</Button><Button variant="ghost" size="icon" className="h-8 w-8" onClick={()=>copy(account.password,'Password')}><Copy className="w-3.5 h-3.5"/></Button></div></div>
            {account.v2rayUuid&&<div className="flex items-center justify-between p-3 rounded-lg bg-[var(--color-toxic-dark)]"><div><span className="text-[10px] text-muted-foreground block">V2Ray UUID</span><span className="font-mono text-xs break-all">{account.v2rayUuid}</span></div><Button variant="ghost" size="icon" className="h-8 w-8" onClick={()=>copy(account.v2rayUuid!,'UUID')}><Copy className="w-3.5 h-3.5"/></Button></div>}
            <h3 className="text-sm font-semibold text-[var(--color-toxic-green)] flex items-center gap-2"><Globe className="w-4 h-4"/>Connection</h3>
            <div className="grid grid-cols-2 gap-2">{[['Host',account.host],['Protocol',protocols[account.protocol]?.label||account.protocol]].concat(account.protocol==='ssh'?[['SSH Port',account.sshPort],['Dropbear',account.dropbearPort]]:account.protocol==='ssl'?[['SSL Port',account.sslPort]]:account.protocol==='v2ray'?[['V2Ray Port',account.v2rayPort]]:[['WS Port',account.wsPort]]).map(([l,v]:any)=><div key={l} className="p-3 rounded-lg bg-[var(--color-toxic-dark)] text-center"><span className="text-[10px] text-muted-foreground block">{l}</span><span className="font-mono text-xs">{v}</span></div>)}</div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-[var(--color-toxic-dark)]"><div className="flex items-center gap-2"><Clock className="w-4 h-4 text-yellow-500"/><div><span className="text-[10px] text-muted-foreground block">Expires</span><span className="text-xs">{fmtDate(account.expiresAt)}</span></div></div><Badge className="bg-[var(--color-toxic-green)]/10 text-[var(--color-toxic-green)] border-0">{account.duration} Days</Badge></div>
            <div className={`p-3 rounded-lg text-xs ${account.vpsCreated?'bg-green-500/10 text-green-400':'bg-yellow-500/10 text-yellow-400'}`}><div className="flex items-center gap-2">{account.vpsCreated?<CheckCircle2 className="w-4 h-4"/>:<AlertTriangle className="w-4 h-4"/>}<span>{account.vpsMessage}</span></div></div>
            <div className="flex gap-2"><Button onClick={()=>{setTab('create');setAccount(null)}} variant="outline" className="flex-1 border-[var(--color-toxic-border)]">Create Another</Button><Button onClick={()=>copy(`${account.username}:${account.password}@${account.host}:${account.protocol==='ssh'?account.sshPort:account.sslPort}`,'Account')} className="flex-1 bg-[var(--color-toxic-green)] text-[var(--color-toxic-dark)] hover:bg-[var(--color-toxic-green)]/90"><Copy className="w-4 h-4 mr-1"/>Copy All</Button></div>
          </CardContent></Card>
        </motion.div>}

        {tab==='servers'&&<motion.div key="servers" initial={{opacity:0,y:10}} animate={{opacity:1,y:0}} exit={{opacity:0,y:-10}} className="space-y-6">
          <div className="text-center py-4"><h2 className="text-2xl font-bold">Server <span className="text-[var(--color-toxic-green)]">Status</span></h2><p className="text-sm text-muted-foreground mt-1">Real-time server monitoring</p></div>
          {servers.length===0?<Card className="border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)]"><CardContent className="py-8 text-center"><Server className="w-8 h-8 text-muted-foreground mx-auto mb-2"/><p className="text-sm text-muted-foreground">No servers</p></CardContent></Card>
          :<div className="grid grid-cols-1 md:grid-cols-2 gap-4">{servers.map(s=><Card key={s.id} className="border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)] toxic-card-hover"><CardContent className="p-5"><div className="flex items-center justify-between mb-4"><div className="flex items-center gap-3"><span className="text-2xl">{flags[s.countryCode]||'🌍'}</span><div><h3 className="font-semibold">{s.name}</h3><p className="text-xs text-muted-foreground">{s.host}</p></div></div><Badge className={`${s.status==='online'?'bg-green-500/10 text-green-400':'bg-red-500/10 text-red-400'} border-0`}><span className={`w-1.5 h-1.5 rounded-full mr-1 ${s.status==='online'?'bg-green-400 animate-toxic-pulse':'bg-red-400'}`}/>{s.status==='online'?'Online':'Offline'}</Badge></div><div className="grid grid-cols-2 gap-3 mb-4"><div className="p-2.5 rounded-lg bg-[var(--color-toxic-dark)]"><span className="text-[10px] text-muted-foreground block mb-0.5">CPU Load</span><div className="flex items-center gap-2"><Progress value={s.load} className="h-1.5 flex-1 bg-white/5 [&>[data-slot=indicator]]:bg-[var(--color-toxic-green)]"/><span className="text-xs font-mono">{s.load}%</span></div></div><div className="p-2.5 rounded-lg bg-[var(--color-toxic-dark)]"><span className="text-[10px] text-muted-foreground block mb-0.5">Accounts</span><div className="flex items-center gap-2"><Progress value={(s.activeAccounts/s.maxAccounts)*100} className="h-1.5 flex-1 bg-white/5 [&>[data-slot=indicator]]:bg-[var(--color-toxic-purple)]"/><span className="text-xs font-mono">{s.activeAccounts}/{s.maxAccounts}</span></div></div></div><div className="grid grid-cols-3 gap-2 text-center text-xs"><div className="p-2 rounded bg-[var(--color-toxic-dark)]"><Cpu className="w-3 h-3 mx-auto mb-1 text-muted-foreground"/><span className="text-muted-foreground block">Ping</span><span className="font-mono">{s.ping}ms</span></div><div className="p-2 rounded bg-[var(--color-toxic-dark)]"><Activity className="w-3 h-3 mx-auto mb-1 text-muted-foreground"/><span className="text-muted-foreground block">Uptime</span><span className="font-mono">{s.uptime}</span></div><div className="p-2 rounded bg-[var(--color-toxic-dark)]"><HardDrive className="w-3 h-3 mx-auto mb-1 text-muted-foreground"/><span className="text-muted-foreground block">BW</span><span className="font-mono text-[var(--color-toxic-green)]">{s.bandwidth}</span></div></div><div className="mt-3 flex flex-wrap gap-1">{s.protocols.map(p=><Badge key={p} variant="outline" className={`text-[10px] ${protocols[p]?.color||''} border-current/20`}>{protocols[p]?.label||p}</Badge>)}</div></CardContent></Card>)}</div>}
        </motion.div>}

        {tab==='check'&&<motion.div key="check" initial={{opacity:0,y:10}} animate={{opacity:1,y:0}} exit={{opacity:0,y:-10}} className="max-w-lg mx-auto space-y-4">
          <div className="text-center py-4"><h2 className="text-2xl font-bold">Check <span className="text-[var(--color-toxic-green)]">Account</span></h2><p className="text-sm text-muted-foreground mt-1">Look up your account status</p></div>
          <Card className="border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)]"><CardContent className="p-5 space-y-4">
            <div className="flex gap-2"><Input value={lookupUser} onChange={e=>setLookupUser(e.target.value)} placeholder="Enter username" className="bg-[var(--color-toxic-dark)] border-[var(--color-toxic-border)] font-mono" onKeyDown={e=>e.key==='Enter'&&handleCheck()}/><Button onClick={handleCheck} disabled={checking} className="bg-[var(--color-toxic-green)] text-[var(--color-toxic-dark)] hover:bg-[var(--color-toxic-green)]/90 px-4">{checking?<span className="w-4 h-4 border-2 border-[var(--color-toxic-dark)]/30 border-t-[var(--color-toxic-dark)] rounded-full animate-spin"/>:<Fingerprint className="w-4 h-4"/>}</Button></div>
            {lookupRes&&<motion.div initial={{opacity:0,y:5}} animate={{opacity:1,y:0}} className="space-y-3"><div className="p-4 rounded-lg bg-[var(--color-toxic-dark)] space-y-2">{[['Username',lookupRes.username],['Protocol',protocols[lookupRes.protocol]?.label||lookupRes.protocol],['Server',lookupRes.serverName],['Host',lookupRes.host]].map(([l,v]:any)=><div key={l} className="flex justify-between text-sm"><span className="text-muted-foreground">{l}</span><span className="font-mono text-xs">{v}</span></div>)}<div className="flex justify-between text-sm"><span className="text-muted-foreground">Expires</span><span>{fmtDate(lookupRes.expiresAt)}</span></div><div className="flex justify-between text-sm"><span className="text-muted-foreground">Status</span><Badge className={`${lookupRes.isActive?'bg-green-500/10 text-green-400':'bg-red-500/10 text-red-400'} border-0`}>{lookupRes.isActive?'Active':'Expired'}</Badge></div></div></motion.div>}
          </CardContent></Card>
        </motion.div>}

        {tab==='premium'&&<motion.div key="premium" initial={{opacity:0,y:10}} animate={{opacity:1,y:0}} exit={{opacity:0,y:-10}} className="space-y-6">
          <div className="text-center py-4"><h2 className="text-2xl font-bold"><span className="text-[var(--color-toxic-purple)]">Premium</span> Plans</h2><p className="text-sm text-muted-foreground mt-1">Unlock more features</p></div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 max-w-4xl mx-auto">
            {[{name:'Free',price:'KES 0',period:'',features:['SSH Tunnel Access','Up to 7 days','2 devices','Standard speed'],btn:'Get Started',color:'border-[var(--color-toxic-border)]',btnClass:'border-[var(--color-toxic-border)]',icon:<CheckCircle2 className="w-4 h-4 text-[var(--color-toxic-green)] shrink-0"/>},
              {name:'Premium',price:'KES 500',period:'/mo',features:['All protocols','Up to 30 days','5 devices','Priority speed','Premium servers','24/7 Support'],btn:'Upgrade Now',color:'border-[var(--color-toxic-purple)]/30 toxic-glow-purple',btnClass:'bg-[var(--color-toxic-purple)] text-white hover:bg-[var(--color-toxic-purple)]/90',icon:<CheckCircle2 className="w-4 h-4 text-[var(--color-toxic-purple)] shrink-0"/>,popular:true},
              {name:'VIP',price:'KES 1,500',period:'/mo',features:['All Premium features','Up to 90 days','Unlimited devices','Maximum speed','Dedicated server','Custom username'],btn:'Go VIP',color:'border-[var(--color-toxic-green)]/20 toxic-glow',btnClass:'bg-[var(--color-toxic-green)] text-[var(--color-toxic-dark)] hover:bg-[var(--color-toxic-green)]/90 font-bold',icon:<CheckCircle2 className="w-4 h-4 text-[var(--color-toxic-green)] shrink-0"/>}
            ].map(plan=><Card key={plan.name} className={`bg-[var(--color-toxic-card)] ${plan.color} relative overflow-hidden`}>{plan.popular&&<div className="absolute top-0 right-0 bg-[var(--color-toxic-purple)] text-white text-[10px] font-bold px-3 py-1 rounded-bl-lg">POPULAR</div>}<CardContent className="p-5 text-center space-y-4"><div><h3 className="text-lg font-bold">{plan.name==='Premium'?<span className="text-[var(--color-toxic-purple)]">{plan.name}</span>:plan.name==='VIP'?<span className="text-[var(--color-toxic-green)]">{plan.name}</span>:plan.name}</h3><p className="text-3xl font-bold mt-2">{plan.price}<span className="text-sm text-muted-foreground">{plan.period}</span></p></div><div className="space-y-2 text-sm text-left">{plan.features.map((f,i)=><div key={i} className="flex items-center gap-2">{plan.icon}<span className="text-xs">{f}</span></div>)}</div><Button onClick={()=>setTab('create')} className={`w-full ${plan.btnClass}`} variant={plan.name==='Free'?'outline':undefined}>{plan.btn}</Button></CardContent></Card>)}
          </div>
          <Card className="border-[var(--color-toxic-border)] bg-[var(--color-toxic-card)] max-w-md mx-auto"><CardContent className="p-5 text-center space-y-3"><h3 className="font-semibold">Upgrade via WhatsApp</h3><p className="text-xs text-muted-foreground">Contact us to upgrade your account</p><a href="https://wa.me/254795314221" target="_blank"><Button className="bg-green-600 hover:bg-green-700 text-white"><Phone className="w-4 h-4 mr-2"/>WhatsApp Us</Button></a></CardContent></Card>
        </motion.div>}
      </AnimatePresence>
    </main>

    <footer className="border-t border-[var(--color-toxic-border)] bg-[var(--color-toxic-dark)] mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4"><div className="flex flex-col sm:flex-row items-center justify-between gap-2"><div className="flex items-center gap-2 text-sm"><Shield className="w-4 h-4 text-[var(--color-toxic-green)]"/><span className="text-muted-foreground"><span className="text-[var(--color-toxic-green)] font-semibold">ToxicSSH</span> by Toxic Tech Kenya</span></div><div className="flex items-center gap-4 text-xs text-muted-foreground"><a href="https://t.me/toxictechke" target="_blank" className="hover:text-[var(--color-toxic-green)] flex items-center gap-1"><MessageCircle className="w-3 h-3"/>Telegram</a><a href="https://wa.me/254795314221" target="_blank" className="hover:text-[var(--color-toxic-green)] flex items-center gap-1"><Phone className="w-3 h-3"/>WhatsApp</a><span className="flex items-center gap-1"><MonitorSmartphone className="w-3 h-3"/>{servers.length} Servers</span></div></div></div>
    </footer>
  </div>;
}
PAGEEOF

echo -e "${GREEN}  ✓ Main page created${NC}"

# ─── Step 6: Build ───
echo -e "${CYAN}[6/7] Building project...${NC}"
cd ${APP_DIR}
export PATH="$HOME/.bun/bin:$PATH"

# Generate Prisma client
npx prisma generate &> /dev/null
echo -e "${GREEN}  ✓ Prisma client generated${NC}"

# Build Next.js
npx next build &> /dev/null
echo -e "${GREEN}  ✓ Next.js build complete${NC}"

# Copy standalone files
cp -r .next/static .next/standalone/.next/ 2>/dev/null
cp -r public .next/standalone/ 2>/dev/null

# ─── Step 7: Seed server & Create systemd service ───
echo -e "${CYAN}[7/7] Setting up service...${NC}"

# Create systemd service
cat > /etc/systemd/system/toxicssh.service << SERVICE
[Unit]
Description=ToxicSSH - Premium SSH & VPN Platform
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/.next/standalone/server.js
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production
Environment=PORT=${APP_PORT}
Environment=DATABASE_URL=file:${APP_DIR}/db/custom.db

[Install]
WantedBy=multi-user.target
SERVICE

# Actually let's use a simple start script with bun for easier management
cat > ${APP_DIR}/start.sh << 'STARTSH'
#!/bin/bash
cd "$(dirname "$0")"
export DATABASE_URL="file:./db/custom.db"
export NODE_ENV="production"
export PORT=3000
mkdir -p db
npx prisma db push --skip-generate 2>/dev/null
node .next/standalone/server.js
STARTSH
chmod +x ${APP_DIR}/start.sh

# Seed the server via API (start temporarily)
echo -e "${CYAN}  Seeding server...${NC}"
cd ${APP_DIR}
export DATABASE_URL="file:./db/custom.db"
npx prisma db push --skip-generate 2>/dev/null

# Start the server temporarily to seed
node .next/standalone/server.js &
SERVER_PID=$!
sleep 5

curl -s -X POST http://localhost:3000/api/setup \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${SERVER_NAME}\",\"host\":\"${SERVER_HOST}\",\"sshUser\":\"root\",\"sshPassword\":\"${SSH_PASSWORD}\",\"country\":\"${SERVER_COUNTRY}\",\"countryCode\":\"${COUNTRY_CODE}\"}" &> /dev/null

kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

# Enable and start service
systemctl daemon-reload
systemctl enable toxicssh
systemctl start toxicssh

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║   ${CYAN}ToxicSSH${GREEN} installed successfully! ✅                       ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📋 Details:${NC}"
echo -e "   ${GREEN}URL:${NC}        http://${SERVER_HOST}:${APP_PORT}"
echo -e "   ${GREEN}Directory:${NC}  ${APP_DIR}"
echo -e "   ${GREEN}Database:${NC}   ${APP_DIR}/db/custom.db"
echo -e "   ${GREEN}Service:${NC}    toxicssh.service"
echo ""
echo -e "${CYAN}🔧 Commands:${NC}"
echo -e "   ${GREEN}Start:${NC}      systemctl start toxicssh"
echo -e "   ${GREEN}Stop:${NC}       systemctl stop toxicssh"
echo -e "   ${GREEN}Restart:${NC}    systemctl restart toxicssh"
echo -e "   ${GREEN}Logs:${NC}       journalctl -u toxicssh -f"
echo -e "   ${GREEN}Status:${NC}     systemctl status toxicssh"
echo ""
echo -e "${CYAN}🌐 API Endpoints:${NC}"
echo -e "   ${GREEN}GET${NC}  /api/servers          - List all servers"
echo -e "   ${GREEN}POST${NC} /api/servers          - Add new server"
echo -e "   ${GREEN}POST${NC} /api/accounts         - Create SSH account"
echo -e "   ${GREEN}GET${NC}  /api/accounts?username - Check account"
echo -e "   ${GREEN}DEL${NC}  /api/accounts?id=     - Delete account"
echo -e "   ${GREEN}POST${NC} /api/setup            - Initial setup"
echo ""
echo -e "${YELLOW}⚠️  For HTTPS, setup Nginx reverse proxy + SSL (certbot)${NC}"
echo ""
