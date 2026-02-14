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
  late MockChildRepository mockRepo;

  setUp(() {
    mockRepo = MockChildRepository();
  });

  final tChild = Child(
    id: '1',
    parentId: 'parent1',
    name: 'Ali',
    age: 5,
    gender: 'male',
    limits: DailyLimits.defaultLimits(),
    todayUsage: const UsageStats(),
    settings: const ChildSettings(),
    createdAt: DateTime(2024, 1, 1),
  );

  final tChild2 = Child(
    id: '2',
    parentId: 'parent1',
    name: 'Vali',
    age: 7,
    gender: 'male',
    limits: DailyLimits.defaultLimits(),
    todayUsage: const UsageStats(),
    settings: const ChildSettings(),
    createdAt: DateTime(2024, 1, 1),
  );

  group('LoadChildrenEvent', () {
    blocTest<ChildBloc, ChildState>(
      'bolalar ro\'yxatini yuklashi kerak',
      build: () {
        when(() => mockRepo.getChildren())
            .thenAnswer((_) async => Right([tChild, tChild2]));
        return ChildBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadChildrenEvent()),
      expect: () => [
        const ChildState(status: ChildStatus.loading),
        ChildState(
          status: ChildStatus.loaded,
          children: [tChild, tChild2],
          selectedChild: tChild,
        ),
      ],
    );

    blocTest<ChildBloc, ChildState>(
      'xatoda error holatiga o\'tishi kerak',
      build: () {
        when(() => mockRepo.getChildren())
            .thenAnswer((_) async => const Left(ServerFailure('Xato')));
        return ChildBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadChildrenEvent()),
      expect: () => [
        const ChildState(status: ChildStatus.loading),
        isA<ChildState>()
            .having((s) => s.status, 'status', ChildStatus.error)
            .having((s) => s.errorMessage, 'error', 'Xato'),
      ],
    );
  });

  group('AddChildEvent', () {
    blocTest<ChildBloc, ChildState>(
      'yangi bola qo\'shishi kerak',
      build: () {
        when(() => mockRepo.addChild(
          name: any(named: 'name'),
          age: any(named: 'age'),
          gender: any(named: 'gender'),
        )).thenAnswer((_) async => Right(tChild));
        return ChildBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const AddChildEvent(
        name: 'Ali',
        age: 5,
        gender: 'male',
      )),
      expect: () => [
        const ChildState(status: ChildStatus.loading),
        ChildState(
          status: ChildStatus.loaded,
          children: [tChild],
          selectedChild: tChild,
        ),
      ],
    );
  });

  group('DeleteChildEvent', () {
    blocTest<ChildBloc, ChildState>(
      'bolani o\'chirishi kerak',
      build: () {
        when(() => mockRepo.deleteChild(any()))
            .thenAnswer((_) async => const Right(null));
        return ChildBloc(repository: mockRepo);
      },
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: [tChild, tChild2],
        selectedChild: tChild,
      ),
      act: (bloc) => bloc.add(const DeleteChildEvent('1')),
      expect: () => [
        isA<ChildState>().having((s) => s.status, 'status', ChildStatus.loading),
        isA<ChildState>()
            .having((s) => s.status, 'status', ChildStatus.loaded)
            .having((s) => s.children.length, 'children count', 1)
            .having((s) => s.selectedChild?.id, 'selected', '2'),
      ],
    );
  });

  group('UpdateChildEvent', () {
    blocTest<ChildBloc, ChildState>(
      'bola ma\'lumotlarini yangilashi kerak',
      build: () {
        final updatedChild = Child(
          id: '1',
          parentId: 'parent1',
          name: 'Ali Updated',
          age: 6,
          gender: 'male',
          limits: DailyLimits.defaultLimits(),
          todayUsage: const UsageStats(),
          settings: const ChildSettings(),
          createdAt: DateTime(2024, 1, 1),
        );
        when(() => mockRepo.updateChild(
          childId: any(named: 'childId'),
          name: any(named: 'name'),
          age: any(named: 'age'),
          avatarUrl: any(named: 'avatarUrl'),
        )).thenAnswer((_) async => Right(updatedChild));
        return ChildBloc(repository: mockRepo);
      },
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: [tChild],
        selectedChild: tChild,
      ),
      act: (bloc) => bloc.add(const UpdateChildEvent(
        childId: '1',
        name: 'Ali Updated',
        age: 6,
      )),
      expect: () => [
        isA<ChildState>().having((s) => s.status, 'status', ChildStatus.loading),
        isA<ChildState>()
            .having((s) => s.status, 'status', ChildStatus.loaded)
            .having((s) => s.selectedChild?.name, 'name', 'Ali Updated'),
      ],
    );
  });

  group('SelectChildEvent', () {
    blocTest<ChildBloc, ChildState>(
      'bolani tanlashi kerak',
      build: () => ChildBloc(repository: mockRepo),
      seed: () => ChildState(
        status: ChildStatus.loaded,
        children: [tChild, tChild2],
        selectedChild: tChild,
      ),
      act: (bloc) => bloc.add(const SelectChildEvent('2')),
      expect: () => [
        isA<ChildState>()
            .having((s) => s.selectedChild?.id, 'selected', '2'),
      ],
    );
  });
}
