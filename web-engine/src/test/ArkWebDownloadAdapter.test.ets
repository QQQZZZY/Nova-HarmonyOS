import { describe, it, expect } from '@ohos/hypium';
import { WebDownloadStatus } from '../main/ets/public/types/WebDownloadTypes';
import { createDownloadSnapshot, markDownloadProgress, markDownloadFinished } from '../main/ets/arkweb/ArkWebDownloadAdapter';

export default function arkWebDownloadAdapterTest() {
  describe('ArkWebDownloadAdapter', () => {
    it('should update snapshot progress and completion', 0, () => {
      const snapshot = createDownloadSnapshot('1', 'https://example.com/file.zip', 'file.zip', 'application/zip', 100);
      const inProgress = markDownloadProgress(snapshot, 40);
      const finished = markDownloadFinished(inProgress);
      expect(inProgress.status).assertEqual(WebDownloadStatus.IN_PROGRESS);
      expect(inProgress.receivedBytes).assertEqual(40);
      expect(inProgress.progress).assertEqual(40);
      expect(finished.status).assertEqual(WebDownloadStatus.FINISHED);
      expect(finished.progress).assertEqual(100);
    });
  });
}
