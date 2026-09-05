import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../boards/domain/board.dart';
import '../boards/domain/board_repository.dart';
import '../canvas/domain/canvas_repository.dart';
import 'in_memory_studio.dart';
import 'supabase_studio.dart';

class InMemoryBoardRepository implements BoardRepository {
  InMemoryBoardRepository(this.studio);
  final InMemoryStudio studio;

  @override
  Future<Result<List<Board>, AppFailure>> listMine() => studio.listMine();

  @override
  Future<Result<Board, AppFailure>> getById(String id) => studio.getById(id);

  @override
  Future<Result<Board, AppFailure>> create({required String title}) => studio.create(title: title);

  @override
  Future<Result<Board, AppFailure>> rename({required String id, required String title}) =>
      studio.rename(id: id, title: title);

  @override
  Future<Result<void, AppFailure>> delete(String id) => studio.delete(id);

  @override
  Future<Result<Board, AppFailure>> setRestricted({required String id, required bool restricted}) =>
      studio.setRestricted(id: id, restricted: restricted);
}

class InMemoryCanvasRepository implements CanvasRepository {
  InMemoryCanvasRepository(this.studio);
  final InMemoryStudio studio;

  @override
  Future<Result<List<BoardNode>, AppFailure>> listNodes(String boardId) => studio.listNodes(boardId);

  @override
  Future<Result<BoardNode, AppFailure>> upsert(BoardNode node) => studio.upsert(node);

  @override
  Future<Result<void, AppFailure>> delete(String nodeId) => studio.deleteNode(nodeId);
}

class SupabaseBoardRepository implements BoardRepository {
  SupabaseBoardRepository(this.studio);
  final SupabaseStudio studio;

  @override
  Future<Result<List<Board>, AppFailure>> listMine() => studio.listMine();

  @override
  Future<Result<Board, AppFailure>> getById(String id) => studio.getById(id);

  @override
  Future<Result<Board, AppFailure>> create({required String title}) => studio.create(title: title);

  @override
  Future<Result<Board, AppFailure>> rename({required String id, required String title}) =>
      studio.rename(id: id, title: title);

  @override
  Future<Result<void, AppFailure>> delete(String id) => studio.delete(id);

  @override
  Future<Result<Board, AppFailure>> setRestricted({required String id, required bool restricted}) =>
      studio.setRestricted(id: id, restricted: restricted);
}

class SupabaseCanvasRepository implements CanvasRepository {
  SupabaseCanvasRepository(this.studio);
  final SupabaseStudio studio;

  @override
  Future<Result<List<BoardNode>, AppFailure>> listNodes(String boardId) => studio.listNodes(boardId);

  @override
  Future<Result<BoardNode, AppFailure>> upsert(BoardNode node) => studio.upsert(node);

  @override
  Future<Result<void, AppFailure>> delete(String nodeId) => studio.deleteNode(nodeId);
}
