import 'package:dartz/dartz.dart';
import '../../models/result_model.dart';
import 'results_service.dart';

class ResultsRepository {
  final ResultsService _service;
  ResultsRepository({ResultsService? service})
      : _service = service ?? ResultsService();

  Future<Either<String, List<Result>>> getByAssignment(
      String assignmentId) async {
    try {
      return Right(await _service.getResultsByAssignment(assignmentId));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<Result>>> getByStudent(String studentId) async {
    try {
      return Right(await _service.getResultsByStudent(studentId));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Result>> create(Map<String, dynamic> data) async {
    try {
      return Right(await _service.createResult(data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Result>> update(
      String id, Map<String, dynamic> data) async {
    try {
      return Right(await _service.updateResult(id, data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Unit>> delete(String id) async {
    try {
      await _service.deleteResult(id);
      return const Right(unit);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
