import { ConfigService } from "../services/ConfigService";

export const config = async () => {
  const service = await ConfigService.getInstance();
  return service.getConfig();
};
