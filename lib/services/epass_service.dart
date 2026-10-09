/// ePass: hien chua co API cong khai de tra cuu so du the.
/// Giao dien nay de san de ban gan nguon du lieu that (VETC/ePass/ben thu ba
/// co hop dong) sau nay. Ban mac dinh tra ve null -> UI se an thong bao.
abstract class EpassService {
  /// So du tai khoan (VND) hoac null neu chua lien ket.
  Future<int?> balance();
}

class NoopEpassService implements EpassService {
  @override
  Future<int?> balance() async => null;
}
