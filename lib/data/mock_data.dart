class MockData {
  // Cosmetic placeholder stats overlaid on character cards — not backed by
  // real data on the server yet.
  static Map<int, int> characterSceneCount = {
    1: 12,
    2: 8,
    3: 5,
  };

  static Map<int, String> characterStatus = {
    1: 'Đã duyệt',
    2: 'Đã duyệt',
    3: 'Chờ quay',
  };

  static Map<int, bool> characterStatusGreen = {
    1: true,
    2: true,
    3: false,
  };
}
