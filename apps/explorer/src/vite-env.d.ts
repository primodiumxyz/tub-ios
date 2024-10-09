/// <reference types="vite/client" />
interface ImportMetaEnv {
  readonly VITE_BITQUERY_ACCESS_TOKEN: string;
  readonly VITE_ALCHEMY_RPC_URL: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
