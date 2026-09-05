import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../boards/domain/board.dart';

abstract class CanvasRepository {
  Future<Result<List<BoardNode>, AppFailure>> listNodes(String boardId);
  Future<Result<BoardNode, AppFailure>> upsert(BoardNode node);
  Future<Result<void, AppFailure>> delete(String nodeId);
}
