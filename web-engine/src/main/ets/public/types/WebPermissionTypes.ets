export enum WebPermissionKind {
  CAMERA,
  MICROPHONE,
  CAMERA_AND_MICROPHONE,
  GEOLOCATION,
  UNKNOWN
}

export enum WebPermissionDecision {
  ALLOW,
  DENY
}

export class WebPermissionRequest {
  kind: WebPermissionKind = WebPermissionKind.UNKNOWN;
  origin: string = '';
  rawSourceType: string = '';
  resources: Array<string> = [];
}
