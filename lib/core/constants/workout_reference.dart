/// Approved workouts database organized by cycle phase
/// Learn, Plan, Track system for cycle-synced fitness
library;

class WorkoutReference {
  static const Map<String, List<Workout>> workoutsByPhase = {
    'Menstrual': [
      Workout(
        id: 'menstrual_yoga',
        name: 'Restorative Yoga',
        description: 'Gentle stretching and breathing',
        intensity: 'Low',
        durationMinutes: 30,
        benefits: 'Reduces cramps, promotes relaxation',
      ),
      Workout(
        id: 'menstrual_walk',
        name: 'Gentle Walk',
        description: 'Easy paced walking',
        intensity: 'Low',
        durationMinutes: 20,
        benefits: 'Improves circulation, mild cardio',
      ),
      Workout(
        id: 'menstrual_stretching',
        name: 'Stretching Routine',
        description: 'Full body stretching',
        intensity: 'Low',
        durationMinutes: 25,
        benefits: 'Relieves tension, improves flexibility',
      ),
      Workout(
        id: 'menstrual_pilates',
        name: 'Pilates Core Work',
        description: 'Low impact core strengthening',
        intensity: 'Medium',
        durationMinutes: 20,
        benefits: 'Strengthens core without strain',
      ),
    ],
    'Follicular': [
      Workout(
        id: 'follicular_hiit',
        name: 'HIIT Training',
        description: 'High intensity interval training',
        intensity: 'High',
        durationMinutes: 30,
        benefits: 'Builds endurance, high energy',
      ),
      Workout(
        id: 'follicular_running',
        name: 'Running',
        description: 'Steady state running',
        intensity: 'High',
        durationMinutes: 40,
        benefits: 'Cardiovascular fitness, mood boost',
      ),
      Workout(
        id: 'follicular_dance',
        name: 'Dance Class',
        description: 'High energy dance workout',
        intensity: 'High',
        durationMinutes: 45,
        benefits: 'Fun, burns calories, coordination',
      ),
      Workout(
        id: 'follicular_cycling',
        name: 'Cycling',
        description: 'Moderate to high intensity cycling',
        intensity: 'High',
        durationMinutes: 45,
        benefits: 'Builds leg strength, endurance',
      ),
      Workout(
        id: 'follicular_tennis',
        name: 'Tennis/Racquet Sports',
        description: 'Competitive racquet sports',
        intensity: 'High',
        durationMinutes: 60,
        benefits: 'Full body workout, coordination',
      ),
    ],
    'Ovulation': [
      Workout(
        id: 'ovulation_strength',
        name: 'Strength Training',
        description: 'Weight lifting and resistance',
        intensity: 'High',
        durationMinutes: 45,
        benefits: 'Peak strength building',
      ),
      Workout(
        id: 'ovulation_crossfit',
        name: 'CrossFit',
        description: 'Mixed functional fitness',
        intensity: 'High',
        durationMinutes: 50,
        benefits: 'Full body conditioning',
      ),
      Workout(
        id: 'ovulation_boxing',
        name: 'Boxing',
        description: 'Boxing cardio and strength',
        intensity: 'High',
        durationMinutes: 45,
        benefits: 'High calorie burn, stress relief',
      ),
      Workout(
        id: 'ovulation_swimming',
        name: 'Swimming',
        description: 'Full body water exercise',
        intensity: 'High',
        durationMinutes: 45,
        benefits: 'Low impact high intensity cardio',
      ),
      Workout(
        id: 'ovulation_team_sports',
        name: 'Team Sports',
        description: 'Soccer, volleyball, basketball',
        intensity: 'High',
        durationMinutes: 60,
        benefits: 'High energy, social, competitive',
      ),
    ],
    'Luteal': [
      Workout(
        id: 'luteal_strength',
        name: 'Strength Training',
        description: 'Moderate weight lifting',
        intensity: 'Medium',
        durationMinutes: 40,
        benefits: 'Sustained strength building',
      ),
      Workout(
        id: 'luteal_yoga',
        name: 'Vinyasa Yoga',
        description: 'Flow-based yoga',
        intensity: 'Medium',
        durationMinutes: 45,
        benefits: 'Balance, stability, flexibility',
      ),
      Workout(
        id: 'luteal_hiking',
        name: 'Hiking',
        description: 'Nature trail hiking',
        intensity: 'Medium',
        durationMinutes: 60,
        benefits: 'Cardio, stress relief, nature time',
      ),
      Workout(
        id: 'luteal_elliptical',
        name: 'Elliptical Training',
        description: 'Moderate cardio on elliptical',
        intensity: 'Medium',
        durationMinutes: 35,
        benefits: 'Low impact cardio',
      ),
      Workout(
        id: 'luteal_cycling_moderate',
        name: 'Casual Cycling',
        description: 'Moderate paced cycling',
        intensity: 'Medium',
        durationMinutes: 40,
        benefits: 'Enjoyable cardio, mood boost',
      ),
      Workout(
        id: 'luteal_pilates',
        name: 'Pilates Reformer',
        description: 'Controlled pilates workout',
        intensity: 'Medium',
        durationMinutes: 50,
        benefits: 'Core strength, body awareness',
      ),
    ],
  };

  /// Get all unique workouts across all phases
  static List<Workout> getAllWorkouts() {
    final uniqueWorkouts = <String, Workout>{};
    for (final phase in workoutsByPhase.values) {
      for (final workout in phase) {
        uniqueWorkouts[workout.id] = workout;
      }
    }
    return uniqueWorkouts.values.toList();
  }

  /// Get workouts for a specific phase
  static List<Workout> getWorkoutsForPhase(String phaseName) {
    return workoutsByPhase[phaseName] ?? [];
  }

  /// Get suggested workout for a phase (for the Learn card)
  static Workout? getSuggestedWorkout(String phaseName) {
    final workouts = getWorkoutsForPhase(phaseName);
    return workouts.isNotEmpty ? workouts.first : null;
  }
}

/// Workout model
class Workout {
  final String id;
  final String name;
  final String description;
  final String intensity;
  final int durationMinutes;
  final String benefits;

  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.intensity,
    required this.durationMinutes,
    required this.benefits,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      intensity: json['intensity'] as String? ?? 'Medium',
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      benefits: json['benefits'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'intensity': intensity,
        'durationMinutes': durationMinutes,
        'benefits': benefits,
      };
}
