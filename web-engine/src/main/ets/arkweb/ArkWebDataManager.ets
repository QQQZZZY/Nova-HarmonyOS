import { webview } from '@kit.ArkWeb';
import { CookieService } from '../data/CookieService';
import { UserAgentService } from '../data/UserAgentService';
import { mapDataClearPlan, WebDataClearPlan, WebDataService } from '../data/WebDataService';
import { WebDataManager } from '../public/WebDataManager';
import { WebDataClearOptions } from '../public/types/WebDataTypes';
import { ArkWebSession } from './ArkWebSession';

export function mapOfficialDataActions(options: WebDataClearOptions): WebDataClearPlan {
  return mapDataClearPlan(options);
}

export class ArkWebDataManager implements WebDataManager {
  private readonly dataService: WebDataService;
  private readonly cookieService: CookieService;
  private readonly userAgentService: UserAgentService;
  private readonly getSessions: () => Array<ArkWebSession>;

  constructor(
    getSessions: () => Array<ArkWebSession>,
    dataService: WebDataService = new WebDataService(),
    cookieService: CookieService = new CookieService(),
    userAgentService: UserAgentService = new UserAgentService()
  ) {
    this.getSessions = getSessions;
    this.dataService = dataService;
    this.cookieService = cookieService;
    this.userAgentService = userAgentService;
  }

  async clear(options: WebDataClearOptions): Promise<void> {
    this.dataService.clear(options, {
      clearCacheAction: (clearRom: boolean) => {
        webview.WebviewController.removeAllCache(clearRom);
      },
      clearSslStateAction: () => {
        this.getSessions().forEach((session) => {
          session.clearSslState();
        });
      },
      clearClientAuthStateAction: () => {
        this.getSessions().forEach((session) => {
          session.clearClientAuthState();
        });
      }
    });
  }

  getCookies(url: string, isPrivate: boolean): string {
    return this.cookieService.getCookies(url, isPrivate);
  }

  setCookie(url: string, value: string, isPrivate: boolean): void {
    this.cookieService.setCookie(url, value, isPrivate);
  }

  setAppCustomUserAgent(userAgent: string): void {
    this.userAgentService.setAppCustomUserAgent(userAgent);
  }

  setUserAgentForHosts(userAgent: string, hosts: Array<string>): void {
    this.userAgentService.setUserAgentForHosts(userAgent, hosts);
  }
}
