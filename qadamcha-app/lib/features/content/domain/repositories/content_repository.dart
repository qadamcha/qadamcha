import 'package:dartz/dartz.dart';
import 'package:qadamcha_app/core/errors/failures.dart';
import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';

abstract class ContentRepository {
  Future<Either<Failure, List<ContentEntity>>> getContents({
    String? type,
    String? category,
    int? age,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, ContentEntity>> getContentById(String id);
}
