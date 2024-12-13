import { ConfigService } from "../services/ConfigService";

export const config = () => ConfigService.getInstance().getConfig();
