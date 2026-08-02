//
//  TonnageTests.swift
//  TonnageTests
//
//  Created by Matt Bolaños on 7/25/26.
//

import Foundation
import SwiftData
import Testing
@testable import Tonnage

@MainActor
struct TonnageTests {
  @Test
  func volumeLoadFavorsMoreRepsWhenTheProductIsGreater() throws {
    let benchPress = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try Workout()
    let benchEntry = try workout.addExercise(benchPress)

    let twelveByForty = try benchEntry.addSet(
      reps: 12,
      weight: Decimal(40),
      weightUnit: .pounds
    )
    let fiveByFortyFive = try benchEntry.addSet(
      reps: 5,
      weight: Decimal(45),
      weightUnit: .pounds
    )

    #expect(twelveByForty.volumeLoad?.value == Decimal(480))
    #expect(fiveByFortyFive.volumeLoad?.value == Decimal(225))
    #expect(
      twelveByForty.volumeLoad?.value ?? .zero
        > fiveByFortyFive.volumeLoad?.value ?? .zero
    )
  }

  @Test
  func workoutLoadSumsWeightedWorkingSetsOnly() throws {
    let benchPress = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let pushUp = try Exercise(
      name: "Push-up",
      loadMode: .bodyweight
    )
    let workout = try Workout()
    let benchEntry = try workout.addExercise(benchPress)
    let pushUpEntry = try workout.addExercise(pushUp)

    try benchEntry.addSet(reps: 12, weight: 40, weightUnit: .pounds)
    try benchEntry.addSet(reps: 5, weight: 45, weightUnit: .pounds)
    try benchEntry.addSet(kind: .warmup, reps: 10, weight: 20, weightUnit: .pounds)
    try pushUpEntry.addSet(reps: 20)
    try pushUpEntry.addSet(reps: 5, weight: 10, weightUnit: .pounds)

    let load = workout.volumeLoad(in: .pounds)

    #expect(load == VolumeLoad(value: 755, unit: .pounds))
    #expect(workout.volumeLoad(for: benchPress.id, in: .pounds)?.value == 705)
    #expect(workout.volumeLoad(for: pushUp.id, in: .pounds)?.value == 50)
  }

  @Test
  func bodyweightOnlyWorkoutHasNoVolumeLoad() throws {
    let pushUp = try Exercise(name: "Push-up", loadMode: .bodyweight)
    let workout = try Workout()
    let entry = try workout.addExercise(pushUp)
    try entry.addSet(reps: 20)

    #expect(workout.volumeLoad(in: .pounds) == nil)
  }

  @Test
  func volumeLoadNormalizesMixedUnits() throws {
    let squat = try Exercise(name: "Squat", loadMode: .externalResistance)
    let workout = try Workout()
    let entry = try workout.addExercise(squat)
    try entry.addSet(reps: 10, weight: 100, weightUnit: .pounds)
    try entry.addSet(reps: 10, weight: 10, weightUnit: .kilograms)

    let expected = Decimal(1_000) + WeightUnit.kilograms.convert(100, to: .pounds)

    #expect(workout.volumeLoad(in: .pounds)?.value == expected)
  }

  @Test
  func invalidSetsAreRejectedBeforeJoiningTheWorkout() throws {
    let benchPress = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try Workout()
    let entry = try workout.addExercise(benchPress)

    #expect(throws: WorkoutModelError.missingWeight) {
      try entry.addSet(reps: 5)
    }
    #expect(throws: WorkoutModelError.invalidWeightPrecision) {
      try entry.addSet(reps: 5, weight: Decimal(string: "42.25"), weightUnit: .pounds)
    }
    #expect(entry.exerciseSets.isEmpty)
  }

  @Test
  func workoutLifecycleUsesTimestampsWithoutPersistingElapsedSeconds() throws {
    let start = Date(timeIntervalSince1970: 1_000)
    let workout = try Workout(startedAt: start, timeZoneIdentifier: "America/New_York")

    #expect(workout.elapsedDuration(at: start.addingTimeInterval(90)) == 90)
    #expect(throws: WorkoutModelError.workoutHasNoSets) {
      try workout.complete(at: start.addingTimeInterval(120))
    }

    let pushUp = try Exercise(name: "Push-up", loadMode: .bodyweight)
    let entry = try workout.addExercise(pushUp)
    try entry.addSet(reps: 10)
    try workout.complete(at: start.addingTimeInterval(120))

    #expect(workout.status == .completed)
    #expect(workout.elapsedDuration() == 120)
    #expect(throws: WorkoutModelError.workoutAlreadyCompleted) {
      try workout.complete()
    }
  }

  @Test
  func manualCompletedWorkoutMayHaveUnknownDuration() throws {
    let workout = try Workout(startedAt: .now)
    let pushUp = try Exercise(name: "Push-up", loadMode: .bodyweight)
    let entry = try workout.addExercise(pushUp)
    try entry.addSet(reps: 10, completedAt: nil)

    try workout.complete(at: nil)

    #expect(workout.status == .completed)
    #expect(workout.endedAt == nil)
    #expect(workout.elapsedDuration() == nil)
  }

  @Test
  func templateCreatesAnIndependentWorkoutSnapshot() throws {
    let benchPress = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let squat = try Exercise(name: "Squat", loadMode: .externalResistance)
    let template = try WorkoutTemplate(name: "Push Day")
    try template.addExercise(benchPress, plannedWorkingSetCount: 3)

    let workout = try template.makeWorkout()
    try template.addExercise(squat, plannedWorkingSetCount: 4)

    #expect(workout.sourceTemplate === template)
    #expect(workout.workoutExercises.count == 1)
    #expect(workout.orderedExercises.first?.exercise === benchPress)
    #expect(workout.orderedExercises.first?.plannedWorkingSetCount == 3)
    #expect(workout.workoutExercises.first?.exerciseSets.isEmpty == true)
  }

  @Test
  func workoutCanCreateATemplateWithoutCopyingSetValues() throws {
    let benchPress = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try Workout()
    let entry = try workout.addExercise(benchPress)
    try entry.addSet(reps: 12, weight: 40, weightUnit: .pounds)
    try entry.addSet(reps: 10, weight: 45, weightUnit: .pounds)
    try entry.addSet(kind: .warmup, reps: 10, weight: 20, weightUnit: .pounds)

    let template = try workout.makeTemplate(named: "Bench Day")

    #expect(template.templateExercises.count == 1)
    #expect(template.templateExercises.first?.plannedWorkingSetCount == 2)
  }

  @Test
  func storeEnforcesOneActiveWorkoutAndUniqueActiveNames() throws {
    let container = try makeContainer()
    let store = TrainingDataStore(modelContext: container.mainContext)

    try store.startWorkout()
    #expect(throws: WorkoutModelError.activeWorkoutExists) {
      try store.startWorkout()
    }

    try store.createExercise(name: "Bench Press", loadMode: .externalResistance)
    #expect(throws: WorkoutModelError.duplicateExerciseName) {
      try store.createExercise(name: "bench press", loadMode: .externalResistance)
    }

    try store.createTemplate(name: "Push Day")
    #expect(throws: WorkoutModelError.duplicateTemplateName) {
      try store.createTemplate(name: "push day")
    }
  }

  @Test
  func storeCreatesTemplateWithAnOrderedExercisePlan() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let squat = try store.createExercise(
      name: "Squat",
      loadMode: .externalResistance
    )
    let pullUp = try store.createExercise(
      name: "Pull-up",
      loadMode: .bodyweight
    )

    let template = try store.createTemplate(
      name: "Full Body",
      notes: "  Strength day  ",
      exercises: [
        TemplateExercisePlan(
          exercise: squat,
          plannedWorkingSetCount: 4
        ),
        TemplateExercisePlan(
          exercise: pullUp,
          plannedWorkingSetCount: 3
        ),
      ]
    )
    try context.save()

    #expect(template.name == "Full Body")
    #expect(template.notes == "Strength day")
    #expect(template.orderedExercises.map(\.position) == [0, 1])
    #expect(
      template.orderedExercises.compactMap { $0.exercise?.name }
        == ["Squat", "Pull-up"]
    )
    #expect(
      template.orderedExercises.map(\.plannedWorkingSetCount)
        == [4, 3]
    )
    #expect(try context.fetchCount(FetchDescriptor<TemplateExercise>()) == 2)
  }

  @Test
  func updatingTemplateReplacesItsExercisePlan() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let benchPress = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let row = try store.createExercise(
      name: "Barbell Row",
      loadMode: .externalResistance
    )
    let template = try store.createTemplate(
      name: "Upper Body",
      exercises: [
        TemplateExercisePlan(
          exercise: benchPress,
          plannedWorkingSetCount: 3
        ),
        TemplateExercisePlan(
          exercise: row,
          plannedWorkingSetCount: 4
        ),
      ]
    )
    try context.save()

    let updateDate = Date(timeIntervalSince1970: 4_000)
    try store.updateTemplate(
      template,
      name: "  Pull Day  ",
      notes: "  Keep reps controlled  ",
      exercises: [
        TemplateExercisePlan(
          exercise: row,
          plannedWorkingSetCount: 5
        ),
      ],
      at: updateDate
    )
    try context.save()

    #expect(template.name == "Pull Day")
    #expect(template.notes == "Keep reps controlled")
    #expect(template.updatedAt == updateDate)
    #expect(template.orderedExercises.count == 1)
    #expect(template.orderedExercises.first?.exercise === row)
    #expect(template.orderedExercises.first?.plannedWorkingSetCount == 5)
    #expect(try context.fetchCount(FetchDescriptor<TemplateExercise>()) == 1)
  }

  @Test
  func restoringTemplatePreservesUniqueActiveNames() throws {
    let container = try makeContainer()
    let store = TrainingDataStore(modelContext: container.mainContext)
    let archivedTemplate = try store.createTemplate(name: "Push Day")
    store.archive(archivedTemplate)
    _ = try store.createTemplate(name: "push day")

    #expect(throws: WorkoutModelError.duplicateTemplateName) {
      try store.restore(archivedTemplate)
    }
    #expect(archivedTemplate.isArchived)
  }

  @Test
  func templateRejectsDuplicateExercisesBeforeInsertion() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let squat = try store.createExercise(
      name: "Squat",
      loadMode: .externalResistance
    )
    let duplicatePlan = TemplateExercisePlan(
      exercise: squat,
      plannedWorkingSetCount: 3
    )

    #expect(throws: WorkoutModelError.duplicateExerciseInTemplate) {
      try store.createTemplate(
        name: "Leg Day",
        exercises: [duplicatePlan, duplicatePlan]
      )
    }
    #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 0)
  }

  @Test
  func referencedTemplateIsArchivedInsteadOfDeleted() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let exercise = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let template = try store.createTemplate(name: "Push Day")
    try template.addExercise(exercise, plannedWorkingSetCount: 3)
    let workout = try store.startWorkout(from: template)
    try context.save()

    store.remove(template)
    try context.save()

    #expect(template.isArchived)
    #expect(workout.sourceTemplate === template)
    #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 1)
  }

  @Test
  func deletingWorkoutCascadesToLoggedChildren() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let exercise = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try Workout()
    let workoutExercise = try workout.addExercise(exercise)
    try workoutExercise.addSet(reps: 12, weight: 40, weightUnit: .pounds)
    context.insert(exercise)
    context.insert(workout)
    try context.save()

    context.delete(workout)
    try context.save()

    #expect(try context.fetchCount(FetchDescriptor<Workout>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<WorkoutExercise>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ExerciseSet>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 1)
  }

  @Test
  func usedExerciseClassificationIsLocked() throws {
    let benchPress = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try Workout()
    let entry = try workout.addExercise(benchPress)
    try entry.addSet(reps: 12, weight: 40, weightUnit: .pounds)

    #expect(throws: WorkoutModelError.exerciseClassificationInUse) {
      try benchPress.updateClassification(
        loadMode: .bodyweight,
        repetitionMode: .standard
      )
    }
  }

  @Test
  func updatingExerciseRenamesAndChangesTracking() throws {
    let container = try makeContainer()
    let store = TrainingDataStore(modelContext: container.mainContext)
    let exercise = try store.createExercise(
      name: "Goblet Squat",
      loadMode: .externalResistance
    )
    let updateDate = Date(timeIntervalSince1970: 2_000)

    try store.updateExercise(
      exercise,
      name: "  Split Squat  ",
      loadMode: .bodyweight,
      repetitionMode: .perSide,
      at: updateDate
    )

    #expect(exercise.name == "Split Squat")
    #expect(exercise.loadMode == .bodyweight)
    #expect(exercise.repetitionMode == .perSide)
    #expect(exercise.updatedAt == updateDate)
  }

  @Test
  func duplicateExerciseRenameDoesNotPartiallyUpdate() throws {
    let container = try makeContainer()
    let store = TrainingDataStore(modelContext: container.mainContext)
    let benchPress = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    _ = try store.createExercise(
      name: "Push-up",
      loadMode: .bodyweight
    )

    #expect(throws: WorkoutModelError.duplicateExerciseName) {
      try store.updateExercise(
        benchPress,
        name: "push-up",
        loadMode: .bodyweight,
        repetitionMode: .perSide
      )
    }
    #expect(benchPress.name == "Bench Press")
    #expect(benchPress.loadMode == .externalResistance)
    #expect(benchPress.repetitionMode == .standard)
  }

  @Test
  func usedExerciseCanBeRenamedWithoutChangingTracking() throws {
    let container = try makeContainer()
    let store = TrainingDataStore(modelContext: container.mainContext)
    let exercise = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try store.startWorkout()
    let entry = try workout.addExercise(exercise)
    try entry.addSet(reps: 8, weight: 135, weightUnit: .pounds)

    #expect(throws: WorkoutModelError.exerciseClassificationInUse) {
      try store.updateExercise(
        exercise,
        name: "Barbell Bench Press",
        loadMode: .bodyweight,
        repetitionMode: .standard
      )
    }
    #expect(exercise.name == "Bench Press")

    try store.updateExercise(
      exercise,
      name: "Barbell Bench Press",
      loadMode: .externalResistance,
      repetitionMode: .standard
    )
    #expect(exercise.name == "Barbell Bench Press")
  }

  @Test
  func explicitlyArchivingUnusedExerciseDoesNotDeleteIt() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let exercise = try store.createExercise(
      name: "Cable Fly",
      loadMode: .externalResistance
    )
    try context.save()

    try store.archive(exercise)
    try context.save()

    #expect(exercise.isArchived)
    #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 1)
  }

  @Test
  func removingUsedExerciseArchivesWithoutDeletingHistory() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let exercise = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try store.startWorkout()
    let workoutEntry = try workout.addExercise(exercise)
    try workoutEntry.addSet(reps: 8, weight: 135, weightUnit: .pounds)
    try context.save()

    try store.remove(exercise)
    try context.save()

    #expect(exercise.isArchived)
    #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 1)
    #expect(try context.fetchCount(FetchDescriptor<WorkoutExercise>()) == 1)
    #expect(try context.fetchCount(FetchDescriptor<ExerciseSet>()) == 1)
  }

  @Test
  func deletingUsedExerciseRequiresExplicitAssociatedDataRemoval() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let exercise = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try store.startWorkout()
    let workoutEntry = try workout.addExercise(exercise)
    try workoutEntry.addSet(reps: 8, weight: 135, weightUnit: .pounds)
    let template = try store.createTemplate(name: "Push Day")
    try template.addExercise(exercise, plannedWorkingSetCount: 3)
    try context.save()

    #expect(
      store.deletionImpact(for: exercise)
        == ExerciseDeletionImpact(
          workoutEntryCount: 1,
          setCount: 1,
          templateEntryCount: 1
        )
    )
    #expect(throws: WorkoutModelError.exerciseHasAssociatedData) {
      try store.delete(exercise)
    }

    try store.delete(exercise, includingAssociatedData: true)
    try context.save()

    #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<WorkoutExercise>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ExerciseSet>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<TemplateExercise>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<Workout>()) == 1)
    #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 1)
  }

  @Test
  func preparingAWorkoutCreatesItsPlannedDraftSets() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let store = TrainingDataStore(modelContext: context)
    let benchPress = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try store.startWorkout()
    let entry = try workout.addExercise(
      benchPress,
      plannedWorkingSetCount: 3
    )

    try store.prepareForEditing(workout)
    try context.save()

    #expect(entry.orderedSets.count == 3)
    #expect(entry.orderedSets.map(\.position) == [0, 1, 2])
    #expect(entry.orderedSets.allSatisfy { $0.completedAt == nil })
  }

  @Test
  func addingAnExerciseToAnActiveWorkoutCreatesThreeWorkingSets() throws {
    let container = try makeContainer()
    let store = TrainingDataStore(modelContext: container.mainContext)
    let benchPress = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try store.startWorkout()

    let entry = try store.addExercise(benchPress, to: workout)

    #expect(entry.plannedWorkingSetCount == 3)
    #expect(entry.orderedSets.count == 3)
    #expect(entry.orderedSets.map(\.position) == [0, 1, 2])
    #expect(entry.orderedSets.allSatisfy { $0.kind == .working })
    #expect(entry.orderedSets.allSatisfy { $0.completedAt == nil })
  }

  @Test
  func changingAnActiveExerciseWeightUnitConvertsItsWeightedSets() throws {
    let benchPress = try Exercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let workout = try Workout()
    let entry = try workout.addExercise(benchPress)
    let emptySet = try entry.addDraftSet()
    let firstSet = try entry.addSet(
      reps: 8,
      weight: 100,
      weightUnit: .pounds
    )
    let secondSet = try entry.addSet(
      reps: 8,
      weight: 50,
      weightUnit: .pounds
    )

    entry.updateWeightUnit(to: .kilograms)

    #expect(entry.weightUnit == .kilograms)
    #expect(firstSet.weight == Decimal(string: "45.5"))
    #expect(secondSet.weight == Decimal(string: "22.5"))
    #expect(firstSet.weightUnit == .kilograms)
    #expect(secondSet.weightUnit == .kilograms)
    #expect(emptySet.weight == nil)
    #expect(emptySet.weightUnit == nil)
  }

  @Test
  func activeWorkoutAllowsDuplicateExercisesAndNormalizesReordering() throws {
    let container = try makeContainer()
    let store = TrainingDataStore(modelContext: container.mainContext)
    let benchPress = try store.createExercise(
      name: "Bench Press",
      loadMode: .externalResistance
    )
    let squat = try store.createExercise(
      name: "Squat",
      loadMode: .externalResistance
    )
    let workout = try store.startWorkout()
    let firstBench = try store.addExercise(benchPress, to: workout)
    let squatEntry = try store.addExercise(squat, to: workout)
    let secondBench = try store.addExercise(benchPress, to: workout)

    try store.reorderExercises(
      in: workout,
      to: [secondBench, firstBench, squatEntry]
    )

    #expect(
      workout.orderedExercises.map(\.id)
        == [secondBench.id, firstBench.id, squatEntry.id]
    )
    #expect(workout.orderedExercises.map(\.position) == [0, 1, 2])
  }

  @Test
  func anExerciseAlwaysKeepsAtLeastOneSet() throws {
    let pushUp = try Exercise(name: "Push-up", loadMode: .bodyweight)
    let workout = try Workout()
    let entry = try workout.addExercise(pushUp)
    let firstSet = try entry.addDraftSet()

    #expect(throws: WorkoutModelError.cannotRemoveLastSet) {
      try entry.removeSet(firstSet)
    }

    let secondSet = try entry.addDraftSet()
    try entry.removeSet(firstSet)

    #expect(entry.orderedSets.count == 1)
    #expect(entry.orderedSets.first === secondSet)
    #expect(entry.orderedSets.first?.position == 0)
  }

  private func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(
      schema: TonnageSchema.schema,
      isStoredInMemoryOnly: true
    )
    return try ModelContainer(
      for: TonnageSchema.schema,
      configurations: [configuration]
    )
  }
}
