import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qadamcha_app/core/errors/failures.dart';
import 'package:qadamcha_app/features/child/domain/entities/child_entity.dart';
import 'package:qadamcha_app/features/child/domain/repositories/child_repository.dart';
import 'package:qadamcha_app/features/child/presentation/bloc/child_bloc.dart';

class MockChildRepository extends Mock implements ChildRepository {}

void main() {
  late ChildBloc childBloc;
  late MockChildRepository mockRepository;

  final tChild1 = Child(
    id: 'child-1',
    parentId: 'parent-1',
    name: 'Ali',
    age: 5,
    gender: 'male',
    limits: DailyLimits.defaultLimits(),
    todayUsage: const UsageStats(),
    settings: const ChildSettings(),
    createdAt: DateTime(2024, 1, 1),
  );

  final tChild2 = Child(
    id: 'child-2',
    parentId: 'parent-1',
    name: 'Zarina',
    age: 8,
    gender: 'female',
    limits: DailyLimits.defaultLimits(),
    todayUsage: const UsageStats(),
    settings: const ChildSettings(),
    createdAt: DateTime(2024, 2, 1),
  );

  final tChildren = [tChild1, tChild2];

  setUp(() {
    mockRepository = MockChildRepository();
    childBloc = ChildBloc(repository: mockRepository);
  });

  tearDown(() {
    childBloc.close();
  });

  test('initial state should have initial status', () {
    expect(childBloc.state.status, ChildStatus.initial);
    expect(childBloc.state.children, isEmpty);
    expect(childBloc.state.selectedChild, null);
  });

  // =====================================================
  // LoadChildrenEvent
  // =====================================================
  group('LoadChildrenEvent', () {
    blocTest<ChildBloc, ChildState>(
      'should emit loaded with children list',
      build: () {
        when(() => mockRepository.getChildren())
            .thenAnswer((_) async => Right(tChildren));
        return childBloc;
      },
      act: (bloc) => bloc.add(LoadChildrenEvent()),
      expect: () => [
        const ChildState(status: ChildStatus.loading),
        ChildState(
          status: ChildStatus.loaded,
          children: tChildren,
          selectedChild: tChild1,
        ),
      ],
    );

    blocTest<ChildBloc, ChildState>(
      'should emit error on failure',
      build: () {
        when(() => mockRepository.getChildren()).thenAnswer(
            (_) async => const Left(ServerFailure('Bolalar yuklanmadi')));
        return childBloc;
      },
      act: (bloc) => bloc.add(LoadChildrenEvent()),
      expect: () => [
        const ChildState(status: ChildStatus.loading),
        const ChildState(
          status: ChildStatus.error,
          errorMessage: 'Bolalar yuklanmadi',
        ),
      ],
    );

    blocTest<ChildBloc, ChildState>(
      'should handle empty children list',
      build: () {
        when(() => mockRepository.getChildren())
            .thenAnswer((_) async => const Right([]));
        return childBloc;
      },
      act: (bloc) => bloc.add(LoadChildrenEvent()),
      expect: () => [
        const ChildState(status: ChildStatus.loading),
        const ChildState(
          status: ChildStatus.loaded,
          children: [],
          selectedChild: null,
        ),
      ],
    );
  });

  // =====================================================
  // SelectChildEvent
  // =====================================================
  group('SelectChildEvent', () {
    blocTest<ChildBloc, ChildState>(
      'should select the correct child',
      build: () => childBloc,
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: tChildren,
        selectedChild: tChild1,
      ),
      act: (bloc) => bloc.add(const SelectChildEvent('child-2')),
      expect: () => [
        ChildState(
          status: ChildStatus.loaded,
          children: tChildren,
          selectedChild: tChild2,
        ),
      ],
    );
  });

  // =====================================================
  // AddChildEvent
  // =====================================================
  group('AddChildEvent', () {
    final tNewChild = Child(
      id: 'child-3',
      parentId: 'parent-1',
      name: 'Jasur',
      age: 4,
      gender: 'male',
      limits: DailyLimits.defaultLimits(),
      todayUsage: const UsageStats(),
      settings: const ChildSettings(),
      createdAt: DateTime(2024, 6, 1),
    );

    blocTest<ChildBloc, ChildState>(
      'should add child and select it',
      build: () {
        when(() => mockRepository.addChild(
              name: 'Jasur',
              age: 4,
              gender: 'male',
            )).thenAnswer((_) async => Right(tNewChild));
        return childBloc;
      },
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: tChildren,
        selectedChild: tChild1,
      ),
      act: (bloc) => bloc.add(const AddChildEvent(
        name: 'Jasur',
        age: 4,
        gender: 'male',
      )),
      expect: () => [
        ChildState(
          status: ChildStatus.loading,
          children: tChildren,
          selectedChild: tChild1,
        ),
        ChildState(
          status: ChildStatus.loaded,
          children: [...tChildren, tNewChild],
          selectedChild: tNewChild,
        ),
      ],
    );

    blocTest<ChildBloc, ChildState>(
      'should emit error when add fails',
      build: () {
        when(() => mockRepository.addChild(
              name: 'Jasur',
              age: 4,
              gender: 'male',
            )).thenAnswer(
            (_) async => const Left(ServerFailure('Maksimal 5 bola')));
        return childBloc;
      },
      act: (bloc) => bloc.add(const AddChildEvent(
        name: 'Jasur',
        age: 4,
        gender: 'male',
      )),
      expect: () => [
        const ChildState(status: ChildStatus.loading),
        const ChildState(
          status: ChildStatus.error,
          errorMessage: 'Maksimal 5 bola',
        ),
      ],
    );
  });

  // =====================================================
  // UpdateChildEvent
  // =====================================================
  group('UpdateChildEvent', () {
    final tUpdatedChild = Child(
      id: 'child-1',
      parentId: 'parent-1',
      name: 'Ali Updated',
      age: 6,
      gender: 'male',
      limits: DailyLimits.defaultLimits(),
      todayUsage: const UsageStats(),
      settings: const ChildSettings(),
      createdAt: DateTime(2024, 1, 1),
    );

    blocTest<ChildBloc, ChildState>(
      'should update child in the list',
      build: () {
        when(() => mockRepository.updateChild(
              childId: 'child-1',
              name: 'Ali Updated',
              age: 6,
            )).thenAnswer((_) async => Right(tUpdatedChild));
        return childBloc;
      },
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: tChildren,
        selectedChild: tChild1,
      ),
      act: (bloc) => bloc.add(const UpdateChildEvent(
        childId: 'child-1',
        name: 'Ali Updated',
        age: 6,
      )),
      expect: () => [
        ChildState(
          status: ChildStatus.loading,
          children: tChildren,
          selectedChild: tChild1,
        ),
        ChildState(
          status: ChildStatus.loaded,
          children: [tUpdatedChild, tChild2],
          selectedChild: tUpdatedChild,
        ),
      ],
    );
  });

  // =====================================================
  // DeleteChildEvent
  // =====================================================
  group('DeleteChildEvent', () {
    blocTest<ChildBloc, ChildState>(
      'should remove child and select next child',
      build: () {
        when(() => mockRepository.deleteChild('child-1'))
            .thenAnswer((_) async => const Right(null));
        return childBloc;
      },
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: tChildren,
        selectedChild: tChild1,
      ),
      act: (bloc) => bloc.add(const DeleteChildEvent('child-1')),
      expect: () => [
        ChildState(
          status: ChildStatus.loading,
          children: tChildren,
          selectedChild: tChild1,
        ),
        ChildState(
          status: ChildStatus.loaded,
          children: [tChild2],
          selectedChild: tChild2,
        ),
      ],
    );

    blocTest<ChildBloc, ChildState>(
      'should handle deleting last child',
      build: () {
        when(() => mockRepository.deleteChild('child-1'))
            .thenAnswer((_) async => const Right(null));
        return childBloc;
      },
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: [tChild1],
        selectedChild: tChild1,
      ),
      act: (bloc) => bloc.add(const DeleteChildEvent('child-1')),
      expect: () => [
        ChildState(
          status: ChildStatus.loading,
          children: [tChild1],
          selectedChild: tChild1,
        ),
        const ChildState(
          status: ChildStatus.loaded,
          children: [],
          selectedChild: null,
        ),
      ],
    );
  });

  // =====================================================
  // SetTimeLimitsEvent
  // =====================================================
  group('SetTimeLimitsEvent', () {
    final tLimitedChild = Child(
      id: 'child-1',
      parentId: 'parent-1',
      name: 'Ali',
      age: 5,
      gender: 'male',
      limits: const DailyLimits(weekdayMinutes: 30, weekendMinutes: 90),
      todayUsage: const UsageStats(),
      settings: const ChildSettings(),
      createdAt: DateTime(2024, 1, 1),
    );

    blocTest<ChildBloc, ChildState>(
      'should update time limits',
      build: () {
        when(() => mockRepository.setTimeLimits(
              childId: 'child-1',
              weekdayMinutes: 30,
              weekendMinutes: 90,
            )).thenAnswer((_) async => Right(tLimitedChild));
        return childBloc;
      },
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: tChildren,
        selectedChild: tChild1,
      ),
      act: (bloc) => bloc.add(const SetTimeLimitsEvent(
        childId: 'child-1',
        weekdayMinutes: 30,
        weekendMinutes: 90,
      )),
      expect: () => [
        ChildState(
          children: [tLimitedChild, tChild2],
          selectedChild: tLimitedChild,
          status: ChildStatus.loaded,
        ),
      ],
    );
  });

  // =====================================================
  // Child Entity Logic Tests
  // =====================================================
  group('Child Entity', () {
    test('ageGroup should return correct group', () {
      expect(tChild1.ageGroup, '3-5'); // age 5
      expect(tChild2.ageGroup, '6-8'); // age 8
    });

    test('hasTimeRemaining should be true when usage is zero', () {
      expect(tChild1.hasTimeRemaining, true);
    });

    test('remainingMinutes should calculate correctly', () {
      final weekday = DateTime.now().weekday;
      final expectedLimit = weekday >= 6 ? 120 : 60; // default limits
      expect(tChild1.remainingMinutes, expectedLimit);
    });
  });
}
