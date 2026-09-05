import '../../../core/errors.dart';
import '../../../core/result.dart';
import 'board.dart';

abstract class BoardRepository {
  Future<Result<List<Board>, AppFailure>> listMine();
  Future<Result<Board, AppFailure>> getById(String id);
  Future<Result<Board, AppFailure>> create({required String title});
  Future<Result<Board, AppFailure>> rename({
    required String id,
    required String title,
  });
  Future<Result<void, AppFailure>> delete(String id);
  Future<Result<Board, AppFailure>> setRestricted({
    required String id,
    required bool restricted,
  });
}
