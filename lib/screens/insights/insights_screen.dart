import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Future<Map<String, List<Map<String, dynamic>>>>? _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture = _loadInsightsData();
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  CollectionReference<Map<String, dynamic>> _collection(String name) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(name);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadInsightsData() async {
    final dailySnapshot = await _collection('dailyLogs')
        .orderBy('date', descending: false)
        .get();

    final foodSnapshot = await _collection('foodLogs')
        .orderBy('date', descending: false)
        .get();

    final cycleSnapshot = await _collection('cycleLogs')
        .orderBy('date', descending: false)
        .get();

    return {
      'dailyLogs': _snapshotToList(dailySnapshot),
      'foodLogs': _snapshotToList(foodSnapshot),
      'cycleLogs': _snapshotToList(cycleSnapshot),
    };
  }

  List<Map<String, dynamic>> _snapshotToList(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['documentId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _insightsFuture = _loadInsightsData();
    });
  }

  double _average(List<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _maxValue(List<num> values, double fallback) {
    if (values.isEmpty) return fallback;

    final max = values
        .map((value) => value.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return max <= 0 ? fallback : max;
  }

  int _wellnessScore({
    required double mood,
    required double sleep,
    required double water,
    required double stress,
    required double energy,
  }) {
    final moodScore = (mood / 5) * 20;
    final sleepScore = (sleep / 8).clamp(0, 1) * 20;
    final waterScore = (water / 8).clamp(0, 1) * 20;
    final stressScore = ((10 - stress) / 10).clamp(0, 1) * 20;
    final energyScore = (energy / 10).clamp(0, 1) * 20;

    return (moodScore + sleepScore + waterScore + stressScore + energyScore)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  String _formatListOrText(dynamic value) {
    if (value == null) return '-';
    if (value is List) return value.isEmpty ? '-' : value.join(', ');
    if (value is String) return value.trim().isEmpty ? '-' : value;
    return value.toString();
  }

  DateTime? _extractDate(Map<String, dynamic> log) {
    final rawDate = log['date'];

    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is DateTime) return rawDate;
    if (rawDate is String) return DateTime.tryParse(rawDate);

    final key = log['dateKey'];
    if (key is String) return DateTime.tryParse(key);

    final documentId = log['documentId'];
    if (documentId is String) return DateTime.tryParse(documentId);

    return null;
  }

  String _formatDate(Map<String, dynamic> log) {
    final date = _extractDate(log);
    if (date == null) return '-';
    return DateFormat('d MMM').format(date);
  }

  List<num> _numericValues(
      List<Map<String, dynamic>> logs,
      String field,
      ) {
    final values = <num>[];

    for (final log in logs) {
      final value = log[field];
      if (value is num) values.add(value);
    }

    return values;
  }

  List<FlSpot> _spotsFromLogs(
      List<Map<String, dynamic>> logs,
      String field,
      ) {
    final spots = <FlSpot>[];

    for (int i = 0; i < logs.length; i++) {
      final value = logs[i][field];
      if (value is num) {
        spots.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }

    return spots;
  }

  List<BarChartGroupData> _barGroupsFromLogs(
      List<Map<String, dynamic>> logs,
      String field,
      ) {
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < logs.length; i++) {
      final value = logs[i][field];

      if (value is num) {
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value.toDouble(),
                width: 14,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        );
      }
    }

    return groups;
  }

  int _countPeriodDays(List<Map<String, dynamic>> cycleLogs) {
    return cycleLogs.where((log) {
      final status = (log['periodStatus'] ?? '').toString().toLowerCase();
      final flow = (log['flow'] ?? '').toString().toLowerCase();
      return status == 'period' ||
          flow == 'light' ||
          flow == 'medium' ||
          flow == 'heavy';
    }).length;
  }

  String _mostCommonSymptom(List<Map<String, dynamic>> cycleLogs) {
    final counts = <String, int>{};

    for (final log in cycleLogs) {
      final symptoms = log['symptoms'];

      if (symptoms is List) {
        for (final symptom in symptoms) {
          final key = symptom.toString();
          counts[key] = (counts[key] ?? 0) + 1;
        }
      } else if (symptoms is String && symptoms.trim().isNotEmpty) {
        counts[symptoms] = (counts[symptoms] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return '-';

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  double _averageCravings(List<Map<String, dynamic>> foodLogs) {
    final values = _numericValues(foodLogs, 'cravings');
    return _average(values);
  }

  String _mostLoggedMealText(List<Map<String, dynamic>> foodLogs) {
    if (foodLogs.isEmpty) return '-';

    final words = <String, int>{};
    final mealFields = ['breakfast', 'lunch', 'dinner', 'snacks'];

    for (final log in foodLogs) {
      for (final field in mealFields) {
        final value = log[field];
        if (value is String && value.trim().isNotEmpty) {
          final cleaned = value.trim().toLowerCase();
          words[cleaned] = (words[cleaned] ?? 0) + 1;
        }
      }
    }

    if (words.isEmpty) return '-';

    final sorted = words.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  DateTime? _lastPeriodDate(List<Map<String, dynamic>> cycleLogs) {
    final periodDates = <DateTime>[];

    for (final log in cycleLogs) {
      final status = (log['periodStatus'] ?? '').toString().toLowerCase();
      final flow = (log['flow'] ?? '').toString().toLowerCase();

      if (status == 'period' ||
          flow == 'light' ||
          flow == 'medium' ||
          flow == 'heavy') {
        final date = _extractDate(log);
        if (date != null) periodDates.add(date);
      }
    }

    if (periodDates.isEmpty) return null;
    periodDates.sort();
    return periodDates.last;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data;

        final dailyLogs = data?['dailyLogs'] ?? [];
        final foodLogs = data?['foodLogs'] ?? [];
        final cycleLogs = data?['cycleLogs'] ?? [];

        final moodValues = _numericValues(dailyLogs, 'mood');
        final sleepValues = _numericValues(dailyLogs, 'sleep');
        final waterValues = _numericValues(dailyLogs, 'water');
        final stressValues = _numericValues(dailyLogs, 'stress');
        final energyValues = _numericValues(dailyLogs, 'energy');
        final weightValues = _numericValues(dailyLogs, 'weight');

        final avgMood = _average(moodValues);
        final avgSleep = _average(sleepValues);
        final avgWater = _average(waterValues);
        final avgStress = _average(stressValues);
        final avgEnergy = _average(energyValues);
        final avgWeight = _average(weightValues);
        final avgCravings = _averageCravings(foodLogs);

        final score = _wellnessScore(
          mood: avgMood,
          sleep: avgSleep,
          water: avgWater,
          stress: avgStress,
          energy: avgEnergy,
        );

        final lastPeriod = _lastPeriodDate(cycleLogs);
        final predictedNextPeriod = lastPeriod?.add(const Duration(days: 30));
        final predictedOvulation = lastPeriod?.add(const Duration(days: 16));

        final recentDailySummary = dailyLogs.take(7).map((log) {
          return "Date: ${_formatDate(log)}, Mood: ${log['mood'] ?? '-'}, Sleep: ${log['sleep'] ?? '-'}, Water: ${log['water'] ?? '-'}, Stress: ${log['stress'] ?? '-'}, Energy: ${log['energy'] ?? '-'}, Weight: ${log['weight'] ?? '-'}, Notes: ${log['notes'] ?? '-'}";
        }).join("\n");

        final recentFoodSummary = foodLogs.take(7).map((log) {
          return "Date: ${_formatDate(log)}, Breakfast: ${log['breakfast'] ?? '-'}, Lunch: ${log['lunch'] ?? '-'}, Dinner: ${log['dinner'] ?? '-'}, Snacks: ${log['snacks'] ?? '-'}, Cravings: ${log['cravings'] ?? '-'}, Notes: ${log['notes'] ?? '-'}";
        }).join("\n");

        final recentCycleSummary = cycleLogs.take(7).map((log) {
          return "Date: ${_formatDate(log)}, Period Status: ${log['periodStatus'] ?? '-'}, Flow: ${log['flow'] ?? '-'}, Pain: ${log['pain'] ?? '-'}, Discharge: ${log['discharge'] ?? '-'}, Symptoms: ${_formatListOrText(log['symptoms'])}, Medication: ${_formatListOrText(log['medication'])}, Notes: ${log['notes'] ?? '-'}";
        }).join("\n");

        final aiDataSummary = """
Recent daily logs:
$recentDailySummary
 
Recent food logs:
$recentFoodSummary
 
Recent cycle logs:
$recentCycleSummary
""";

        return Scaffold(
          backgroundColor: AppColors.beige,
          appBar: AppBar(
            title: const Text('Insights'),
            backgroundColor: AppColors.petalRouge,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: loading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.petalRouge,
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Wellness Insights 💖',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A summary based on your daily, food, and cycle logs.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _wellnessCard(score, dailyLogs.length),
                      const SizedBox(height: 18),

                      _statGrid(
                        avgMood: avgMood,
                        avgSleep: avgSleep,
                        avgWater: avgWater,
                        avgStress: avgStress,
                        avgEnergy: avgEnergy,
                        avgWeight: avgWeight,
                      ),

                      const SizedBox(height: 22),

                      _miniInsightCard(
                        score: score,
                        sleep: avgSleep,
                        water: avgWater,
                        stress: avgStress,
                        logsCount: dailyLogs.length,
                      ),

                      const SizedBox(height: 22),

                      _lineChartCard(
                        title: 'Mood Trend',
                        emoji: '😊',
                        values: moodValues,
                        maxY: 5,
                      ),
                      const SizedBox(height: 18),

                      _barChartCard(
                        title: 'Sleep Trend',
                        emoji: '😴',
                        values: sleepValues,
                        maxY: 12,
                      ),
                      const SizedBox(height: 18),

                      _barChartCard(
                        title: 'Water Intake',
                        emoji: '💧',
                        values: waterValues,
                        maxY: 12,
                      ),
                      const SizedBox(height: 18),

                      _lineChartCard(
                        title: 'Weight Trend',
                        emoji: '⚖️',
                        values: weightValues,
                        maxY: _maxValue(weightValues, 100) + 5,
                      ),
                      const SizedBox(height: 22),

                      _cycleSummaryCard(
                        cycleLogs: cycleLogs,
                        lastPeriod: lastPeriod,
                        predictedNextPeriod: predictedNextPeriod,
                        predictedOvulation: predictedOvulation,
                      ),
                      const SizedBox(height: 18),

                      _foodSummaryCard(
                        foodLogs: foodLogs,
                        averageCravings: avgCravings,
                      ),
                      const SizedBox(height: 18),

                      _aiCoachPlaceholder(
                        score: score,
                        sleep: avgSleep,
                        stress: avgStress,
                        water: avgWater,
                        cravings: avgCravings,
                        cycleLogs: cycleLogs,

                        avgMood: avgMood,
                        avgSleep: avgSleep,
                        avgWater: avgWater,
                        avgStress: avgStress,
                        avgEnergy: avgEnergy,
                        avgWeight: avgWeight,
                        aiDataSummary: aiDataSummary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statGrid({
    required double avgMood,
    required double avgSleep,
    required double avgWater,
    required double avgStress,
    required double avgEnergy,
    required double avgWeight,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                emoji: '😊',
                title: 'Mood',
                value: avgMood.toStringAsFixed(1),
                subtitle: '/5 average',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                emoji: '😴',
                title: 'Sleep',
                value: avgSleep.toStringAsFixed(1),
                subtitle: 'hours',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                emoji: '💧',
                title: 'Water',
                value: avgWater.toStringAsFixed(1),
                subtitle: 'glasses',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                emoji: '⚡',
                title: 'Energy',
                value: avgEnergy.toStringAsFixed(1),
                subtitle: '/10 average',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                emoji: '😣',
                title: 'Stress',
                value: avgStress.toStringAsFixed(1),
                subtitle: '/10 average',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                emoji: '⚖️',
                title: 'Weight',
                value: avgWeight.toStringAsFixed(1),
                subtitle: 'kg average',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _wellnessCard(int score, int logsCount) {
    String message;

    if (logsCount == 0) {
      message = 'Start logging your wellness to see insights.';
    } else if (score >= 80) {
      message = 'You are doing really well. Keep going.';
    } else if (score >= 60) {
      message = 'You are doing okay. Small improvements can help.';
    } else {
      message = 'Your body may need more rest and care.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: _cardDecoration(color: AppColors.petalFrost),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Wellness',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              logsCount == 0 ? '--' : '$score',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: AppColors.petalRouge,
              ),
            ),
          ),
          Center(
            child: Text(
              logsCount == 0 ? 'No data yet' : '/100',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.greyText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value == '0.0' ? '--' : value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.petalRouge,
            ),
          ),
          Text(
            value == '0.0' ? 'No data yet' : subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInsightCard({
    required int score,
    required double sleep,
    required double water,
    required double stress,
    required int logsCount,
  }) {
    String insight;

    if (logsCount == 0) {
      insight =
      'Log a few days of mood, sleep, water, stress and energy to unlock insights.';
    } else if (sleep < 6) {
      insight =
      'Your average sleep is quite low. Try improving sleep first because it can affect stress, cravings and energy.';
    } else if (water < 4) {
      insight =
      'Your water intake looks low. Increasing hydration may support your energy and general wellness.';
    } else if (stress > 7) {
      insight =
      'Your stress average is high. Consider adding rest, walks, journaling, or relaxation time.';
    } else if (score >= 80) {
      insight =
      'Your logs show a healthy pattern overall. Keep maintaining your sleep, hydration and energy habits.';
    } else {
      insight =
      'Your wellness pattern is forming. Keep logging daily so the app can find stronger trends.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mini Insight ✨',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineChartCard({
    required String title,
    required String emoji,
    required List<num> values,
    required double maxY,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $title',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 18),
          if (values.length < 2)
            const Text(
              'Add at least 2 logs to see this chart.',
              style: TextStyle(color: AppColors.greyText),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        values.length,
                            (index) => FlSpot(
                          index.toDouble(),
                          values[index].toDouble(),
                        ),
                      ),
                      isCurved: true,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barChartCard({
    required String title,
    required String emoji,
    required List<num> values,
    required double maxY,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $title',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 18),
          if (values.isEmpty)
            const Text(
              'Add logs to see this chart.',
              style: TextStyle(color: AppColors.greyText),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    values.length,
                        (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index].toDouble(),
                          width: 14,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cycleSummaryCard({
    required List<Map<String, dynamic>> cycleLogs,
    required DateTime? lastPeriod,
    required DateTime? predictedNextPeriod,
    required DateTime? predictedOvulation,
  }) {
    final periodDays = _countPeriodDays(cycleLogs);
    final commonSymptom = _mostCommonSymptom(cycleLogs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌸 Cycle Summary',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 14),
          _summaryLine(
            'Logged cycle days',
            cycleLogs.isEmpty ? 'No data yet' : '${cycleLogs.length}',
          ),
          _summaryLine(
            'Period days recorded',
            periodDays == 0 ? '-' : '$periodDays',
          ),
          _summaryLine('Most common symptom', commonSymptom),
          _summaryLine(
            'Last period day',
            lastPeriod == null ? '-' : DateFormat('d MMM yyyy').format(lastPeriod),
          ),
          _summaryLine(
            'Predicted next period',
            predictedNextPeriod == null
                ? '-'
                : DateFormat('d MMM yyyy').format(predictedNextPeriod),
          ),
          _summaryLine(
            'Estimated ovulation',
            predictedOvulation == null
                ? '-'
                : DateFormat('d MMM yyyy').format(predictedOvulation),
          ),
        ],
      ),
    );
  }

  Widget _foodSummaryCard({
    required List<Map<String, dynamic>> foodLogs,
    required double averageCravings,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🍓 Food Summary',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 14),
          _summaryLine(
            'Food logs recorded',
            foodLogs.isEmpty ? 'No data yet' : '${foodLogs.length}',
          ),
          _summaryLine(
            'Average cravings',
            averageCravings == 0 ? '-' : '${averageCravings.toStringAsFixed(1)}/5',
          ),
          _summaryLine('Most repeated meal text', _mostLoggedMealText(foodLogs)),
        ],
      ),
    );
  }

  Widget _aiCoachPlaceholder({
    required int score,
    required double sleep,
    required double stress,
    required double water,
    required double cravings,
    required List<Map<String, dynamic>> cycleLogs,

    required double avgMood,
    required double avgSleep,
    required double avgWater,
    required double avgStress,
    required double avgEnergy,
    required double avgWeight,
    required String aiDataSummary,
  }) {
    String recommendation;

    if (sleep > 0 && sleep < 6) {
      recommendation =
      'Your average sleep is low. The AI coach can later use Gemini to explain how sleep may relate to stress, cravings, and cycle symptoms.';
    } else if (stress > 7) {
      recommendation =
      'Your stress average is high. Later, Gemini can generate a personalized stress-reduction plan using your logs.';
    } else if (water > 0 && water < 4) {
      recommendation =
      'Your hydration appears low. The AI coach can later suggest daily water goals based on your patterns.';
    } else if (cravings > 3.5) {
      recommendation =
      'Cravings look elevated. Later, Gemini can compare cravings with sleep, stress, and cycle phase.';
    } else if (score >= 80) {
      recommendation =
      'Your wellness score looks strong. Later, Gemini can summarize what habits are helping you most.';
    } else {
      recommendation =
      'Keep logging consistently. Once more data is available, the AI coach can generate deeper PCOS wellness insights.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(color: AppColors.petalFrost),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 AI Wellness Coach',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),

          const SizedBox(height: 16),

          FutureBuilder<String>(
            future: AIService().generateWellnessInsight(
              mood: avgMood,
              sleep: avgSleep,
              water: avgWater,
              stress: avgStress,
              energy: avgEnergy,
              weight: avgWeight,

              cycleSummary: recommendation,

              foodSummary: aiDataSummary,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  "Unable to contact the AI Coach.",
                  style: TextStyle(
                    color: AppColors.greyText,
                  ),
                );
              }

              return Text(
                snapshot.data ?? "No AI insight available.",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.darkText,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({Color color = Colors.white}) {
    return BoxDecoration(
      color: color.withOpacity(0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.petalFrost),
    );
  }
}
