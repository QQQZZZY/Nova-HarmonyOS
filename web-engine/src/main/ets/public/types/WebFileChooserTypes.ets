export class WebFileChooserRequest {
  title: string = '';
  mode: number = 0;
  acceptTypes: Array<string> = [];
  capture: boolean = false;
}

export class WebFileChooserResult {
  useDefaultChooser: boolean = false;
  selectedUris: Array<string> = [];
}
