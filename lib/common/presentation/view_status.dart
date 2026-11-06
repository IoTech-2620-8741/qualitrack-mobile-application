/// Common lifecycle of every remote screen.
enum ViewStatus { initial, loading, success, empty, failure }

extension ViewStatusX on ViewStatus {
  bool get isLoading => this == ViewStatus.loading || this == ViewStatus.initial;
}
