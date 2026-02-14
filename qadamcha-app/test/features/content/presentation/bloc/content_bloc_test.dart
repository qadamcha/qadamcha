import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qadamcha_app/core/errors/failures.dart';
import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';
import 'package:qadamcha_app/features/content/domain/repositories/content_repository.dart';
import 'package:qadamcha_app/features/content/presentation/bloc/content_bloc.dart';

class MockContentRepository extends Mock implements ContentRepository {}

void main() {
  late MockContentRepository mockRepo;

  setUp(() {
    mockRepo = MockContentRepository();
  });

  ContentEntity makeContent(String id) => ContentEntity(
        id: id,
        title: 'Content $id',
        type: 'cartoon',
        category: 'educational',
        videoId: 'vid_$id',
        duration: 300,
        views: 100,
        likes: 10,
        isFeatured: false,
      );

  final tContents = List.generate(20, (i) => makeContent('$i'));
  final tMoreContents = List.generate(5, (i) => makeContent('${i + 20}'));

  group('LoadContentEvent', () {
    blocTest<ContentBloc, ContentState>(
      'kontentlarni yuklashi kerak',
      build: () {
        when(() => mockRepo.getContents(
          type: any(named: 'type'),
          category: any(named: 'category'),
          age: any(named: 'age'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => Right(tContents));
        return ContentBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadContentEvent()),
      expect: () => [
        isA<ContentState>()
            .having((s) => s.status, 'status', ContentStatus.loading),
        isA<ContentState>()
            .having((s) => s.status, 'status', ContentStatus.loaded)
            .having((s) => s.contents.length, 'count', 20)
            .having((s) => s.hasReachedMax, 'hasReachedMax', false),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'filtr bilan yuklashi kerak',
      build: () {
        when(() => mockRepo.getContents(
          type: any(named: 'type'),
          category: any(named: 'category'),
          age: any(named: 'age'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => Right([makeContent('1')]));
        return ContentBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadContentEvent(type: 'cartoon')),
      expect: () => [
        isA<ContentState>()
            .having((s) => s.status, 'status', ContentStatus.loading),
        isA<ContentState>()
            .having((s) => s.status, 'status', ContentStatus.loaded)
            .having((s) => s.contents.length, 'count', 1)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'xatoda error holatiga o\'tishi kerak',
      build: () {
        when(() => mockRepo.getContents(
          type: any(named: 'type'),
          category: any(named: 'category'),
          age: any(named: 'age'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => const Left(NetworkFailure()));
        return ContentBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadContentEvent()),
      expect: () => [
        isA<ContentState>()
            .having((s) => s.status, 'status', ContentStatus.loading),
        isA<ContentState>()
            .having((s) => s.status, 'status', ContentStatus.error),
      ],
    );
  });

  group('LoadMoreContentEvent', () {
    blocTest<ContentBloc, ContentState>(
      'keyingi sahifani yuklashi kerak (pagination)',
      build: () {
        when(() => mockRepo.getContents(
          type: any(named: 'type'),
          category: any(named: 'category'),
          age: any(named: 'age'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => Right(tMoreContents));
        return ContentBloc(repository: mockRepo);
      },
      seed: () => ContentState(
        status: ContentStatus.loaded,
        contents: tContents,
        page: 1,
        hasReachedMax: false,
      ),
      act: (bloc) => bloc.add(LoadMoreContentEvent()),
      expect: () => [
        isA<ContentState>()
            .having((s) => s.status, 'status', ContentStatus.loaded)
            .having((s) => s.contents.length, 'count', 25)
            .having((s) => s.page, 'page', 2)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'hasReachedMax bo\'lsa yuklamamsligi kerak',
      build: () => ContentBloc(repository: mockRepo),
      seed: () => ContentState(
        status: ContentStatus.loaded,
        contents: tContents,
        page: 1,
        hasReachedMax: true,
      ),
      act: (bloc) => bloc.add(LoadMoreContentEvent()),
      expect: () => [],
    );

    blocTest<ContentBloc, ContentState>(
      'bo\'sh javobda hasReachedMax true bo\'lishi kerak',
      build: () {
        when(() => mockRepo.getContents(
          type: any(named: 'type'),
          category: any(named: 'category'),
          age: any(named: 'age'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => const Right([]));
        return ContentBloc(repository: mockRepo);
      },
      seed: () => ContentState(
        status: ContentStatus.loaded,
        contents: tContents,
        page: 1,
        hasReachedMax: false,
      ),
      act: (bloc) => bloc.add(LoadMoreContentEvent()),
      expect: () => [
        isA<ContentState>()
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );
  });
}
