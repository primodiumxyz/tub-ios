import { Config, ConfigService } from "../services/ConfigService";

export const config = () => ConfigService.getInstance().getConfig();
export const keyConfig = (key: keyof Config["tokens"]) => ConfigService.getInstance().getPublicKey(key);
