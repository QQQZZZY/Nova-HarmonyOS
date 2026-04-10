import { ArkWebSession } from '../arkweb/ArkWebSession';

export class SessionRegistry {
  private sessions: Array<ArkWebSession> = [];

  register(session: ArkWebSession): void {
    this.sessions.push(session);
  }

  unregister(sessionId: string): void {
    this.sessions = this.sessions.filter((session) => session.getId() !== sessionId);
  }

  snapshot(): Array<ArkWebSession> {
    return this.sessions.slice();
  }

  clear(): void {
    this.sessions = [];
  }
}
