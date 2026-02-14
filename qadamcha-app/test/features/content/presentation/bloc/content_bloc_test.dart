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
  late ContentBloc contentBloc;
  late MockContentRepository mockRepository;

  final tContentList = [
    const ContentEntity(
      id: 'c1',
      title: 'Multfilm 1',
      type: 'cartoon',
      category: 'educational',
      videoId: 'vid-001',
      thumbnailUrl: 'https://cdn.example.com/thumb1.jpg',
      duration: 600,
      views: 100,
      likes: 50,
      isFeatured: true,
    ),
    const ContentEntity(
      id: 'c2',
      title: 'O\'yin 1',
      type: 'game',
      category: 'fun',
      videoId: 'vid-002',
      thumbnailUrl: 'https://cdn.example.com/thumb2.jpg',
      duration: 300,
      views: 75,
      likes: 30,
      isFeatured: false,
    ),
  ];

  setUp(() {
    mockRepository = MockContentRepository();
    contentBloc = ContentBloc(repository: mockRepository);
  });

  tearDown(() {
    contentBloc.close();
  });

  test('initial state should have initial status', () {
    expect(contentBloc.state.status, ContentStatus.initial);
    expect(contentBloc.state.contents, isEmpty);
    expect(contentBloc.state.hasReachedMax, false);
  });

  // =====================================================
  // LoadContentEvent
  // =====================================================
  group('LoadContentEvent', () {
    blocTest<ContentBloc, ContentState>(
      'should emit loaded with contents on success',
      build: () {
        when(() => mockRepository.getContents(
              type: any(named: 'type'),
              category: any(named: 'category'),
              age: any(named: 'age'),
              page: 1,
              limit: 20,
            )).thenAnswer((_) async => Right(tContentList));
        return contentBloc;
      },
      act: (bloc) => bloc.add(const LoadContentEvent()),
      expect: () => [
        const ContentState(
          status: ContentStatus.loading,
          page: 1,
          hasReachedMax: false,
        ),
        ContentState(
          status: ContentStatus.loaded,
          contents: tContentList,
          hasReachedMax: true, // 2 < 20
          page: 1,
        ),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'should emit error on failure',
      build: () {
        when(() => mockRepository.getContents(
              type: any(named: 'type'),
              category: any(named: 'category'),
              age: any(named: 'age'),
              page: 1,
              limit: 20,
            )).thenAnswer(
            (_) async => const Left(ServerFailure('Kontent yuklanmadi')));
        return contentBloc;
      },
      act: (bloc) => bloc.add(const LoadContentEvent()),
      expect: () => [
        const ContentState(
          status: ContentStatus.loading,
          page: 1,
          hasReachedMax: false,
        ),
        const ContentState(
          status: ContentStatus.error,
          errorMessage: 'Kontent yuklanmadi',
        ),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'should clear contents on refresh',
      build: () {
        when(() => mockRepository.getContents(
              type: any(named: 'type'),
              category: any(named: 'category'),
              age: any(named: 'age'),
              page: 1,
              limit: 20,
            )).thenAnswer((_) async => Right(tContentList));
        return contentBloc;
      },
      act: (bloc) => bloc.add(const LoadContentEvent(refresh: true)),
      expect: () => [
        const ContentState(
          status: ContentStatus.loading,
          page: 1,
          hasReachedMax: false,
        ),
        ContentState(
          status: ContentStatus.loaded,
          contents: tContentList,
          hasReachedMax: true,
          page: 1,
        ),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'should filter by type',
      build: () {
        when(() => mockRepository.getContents(
              type: 'cartoon',
              category: any(named: 'category'),
              age: any(named: 'age'),
              page: 1,
              limit: 20,
            )).thenAnswer((_) async => Right([tContentList[0]]));
        return contentBloc;
      },
      act: (bloc) => bloc.add(const LoadContentEvent(type: 'cartoon')),
      verify: (_) {
        verify(() => mockRepository.getContents(
              type: 'cartoon',
              category: any(named: 'category'),
              age: any(named: 'age'),
              page: 1,
              limit: 20,
            )).called(1);
      },
    );
  });

  // =====================================================
  // LoadMoreContentEvent
  // =====================================================
  group('LoadMoreContentEvent', () {
    blocTest<ContentBloc, ContentState>(
      'should not load more when hasReachedMax is true',
      build: () => contentBloc,
      seed: () => ContentState(
        status: ContentStatus.loaded,
        contents: tContentList,
        hasReachedMax: true,
        page: 1,
      ),
      act: (bloc) => bloc.add(const LoadMoreContentEvent()),
      expect: () => [],
    );

    blocTest<ContentBloc, ContentState>(
      'should append new contents on page 2',
      build: () {
        final moreContents = [
          const ContentEntity(
            id: 'c3',
            title: 'Hikoya 1',
            type: 'story',
            category: 'bedtime',
            videoId: 'vid-003',
            duration: 900,
            views: 40,
            likes: 20,
            isFeatured: false,
          ),
        ];
        when(() => mockRepository.getContents(
              page: 2,
              limit: 20,
            )).thenAnswer((_) async => Right(moreContents));
        return contentBloc;
      },
      seed: () => ContentState(
        status: ContentStatus.loaded,
        contents: tContentList,
        hasReachedMax: false,
        page: 1,
      ),
      act: (bloc) => bloc.add(const LoadMoreContentEvent()),
      expect: () => [
        isA<ContentState>()
            .having((s) => s.contents.length, 'contents length', 3)
            .having((s) => s.page, 'page', 2)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'should set hasReachedMax when no more contents',
      build: () {
        when(() => mockRepository.getContents(
              page: 2,
              limit: 20,
            )).thenAnswer((_) async => const Right([]));
        return contentBloc;
      },
      seed: () => ContentState(
        status: ContentStatus.loaded,
        contents: tContentList,
        hasReachedMax: false,
        page: 1,
      ),
      act: (bloc) => bloc.add(const LoadMoreContentEvent()),
      expect: () => [
        ContentState(
          status: ContentStatus.loaded,
          contents: tContentList,
          hasReachedMax: true,
          page: 1,
        ),
      ],
    );
  });
}
