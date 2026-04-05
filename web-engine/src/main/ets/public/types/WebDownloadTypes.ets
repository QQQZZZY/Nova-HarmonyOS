export enum WebDownloadDecisionType {
  ALLOW,
  REJECT
}

export enum WebDownloadStatus {
  PENDING,
  IN_PROGRESS,
  PAUSED,
  FINISHED,
  FAILED,
  CANCELED
}

export class WebDownloadDecision {
  type: WebDownloadDecisionType = WebDownloadDecisionType.ALLOW;
  destinationUri: string = '';
}

export class WebDownloadRequest {
  url: string = '';
  suggestedFilename: string = '';
  mimeType: string = '';
  contentLength: number = -1;
}

export class WebDownloadSnapshot {
  id: string = '';
  url: string = '';
  suggestedFilename: string = '';
  mimeType: string = '';
  receivedBytes: number = 0;
  totalBytes: number = -1;
  progress: number = 0;
  status: WebDownloadStatus = WebDownloadStatus.PENDING;
}

export class WebDownloadEvent {
  snapshot: WebDownloadSnapshot = new WebDownloadSnapshot();
  errorMessage: string = '';
}
