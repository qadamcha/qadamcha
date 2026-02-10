import 'package:dartz/dartz.dart';
import 'package:qadamcha_app/core/errors/failures.dart';
import 'package:qadamcha_app/features/content/data/datasources/content_remote_data_source.dart';
import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';
import 'package:qadamcha_app/features/content/domain/repositories/content_repository.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentRemoteDataSource remoteDataSource;

  ContentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ContentEntity>>> getContents({
    String? type,
    String? category,
    int? age,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await remoteDataSource.getContents(
        type: type,
        category: category,
        age: age,
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      if (e is Failure) {
        return Left(e);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ContentEntity>> getContentById(String id) async {
    try {
      final result = await remoteDataSource.getContentById(id);
      return Right(result);
    } catch (e) {
      if (e is Failure) {
        return Left(e);
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
