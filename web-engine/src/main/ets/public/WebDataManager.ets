import { WebDataClearOptions } from './types/WebDataTypes';

export interface WebDataManager {
  clear(options: WebDataClearOptions): Promise<void>;
  getCookies(url: string, isPrivate: boolean): string;
  setCookie(url: string, value: string, isPrivate: boolean): void;
  setAppCustomUserAgent(userAgent: string): void;
  setUserAgentForHosts(userAgent: string, hosts: Array<string>): void;
}
