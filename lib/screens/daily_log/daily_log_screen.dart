import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_theme.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  bool isFutureDate(DateTime date) {
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.isAfter(cleanToday);
  }

  CollectionReference<Map<String, dynamic>> get dailyLogsRef {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyLogs');
  }

  Future<void> saveLog({
    required int mood,
    required int sleep,
    required int water,
    required double weight,
    required int stress,
    required int energy,
    required String notes,
  }) async {
    final key = dateKey(selectedDay);

    await dailyLogsRef.doc(key).set({
      'dateKey': key,
      'date': Timestamp.fromDate(
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
      ),
      'mood': mood,
      'sleep': sleep,
      'water': water,
      'weight': weight,
      'stress': stress,
      'energy': energy,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSelectedLog() async {
    await dailyLogsRef.doc(dateKey(selectedDay)).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Log deleted")),
    );
  }

  void openLogForm({Map<String, dynamic>? existingLog}) {
    int mood = existingLog?['mood'] ?? 3;
    int sleep = existingLog?['sleep'] ?? 7;
    int water = existingLog?['water'] ?? 6;
    double weight = (existingLog?['weight'] ?? 60.0).toDouble();
    int stress = existingLog?['stress'] ?? 3;
    int energy = existingLog?['energy'] ?? 6;

    final notesController = TextEditingController(
      text: existingLog?['notes'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(context).viewInsets.bottom + 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      existingLog == null
                          ? "Daily Check-in 💗"
                          : "Edit Daily Log ✨",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(selectedDay),
                      style: const TextStyle(color: AppColors.greyText),
                    ),
                    const SizedBox(height: 18),

                    _moodPicker(mood, (value) {
                      setSheetState(() => mood = value);
                    }),

                    _counter("🌙", "Sleep", sleep, "hrs", () {
                      if (sleep > 0) setSheetState(() => sleep--);
                    }, () {
                      setSheetState(() => sleep++);
                    }),

                    _counter("💧", "Water", water, "glasses", () {
                      if (water > 0) setSheetState(() => water--);
                    }, () {
                      setSheetState(() => water++);
                    }),

                    _weightCounter(weight, (value) {
                      setSheetState(() => weight = value);
                    }),

                    _counter("⚡", "Stress", stress, "/10", () {
                      if (stress > 0) setSheetState(() => stress--);
                    }, () {
                      if (stress < 10) setSheetState(() => stress++);
                    }),

                    _counter("🔋", "Energy", energy, "/10", () {
                      if (energy > 0) setSheetState(() => energy--);
                    }, () {
                      if (energy < 10) setSheetState(() => energy++);
                    }),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Notes",
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await saveLog(
                            mood: mood,
                            sleep: sleep,
                            water: water,
                            weight: weight,
                            stress: stress,
                            energy: energy,
                            notes: notesController.text,
                          );

                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Daily log saved")),
                          );
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          "Save Log",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.petalRouge,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, Map<String, dynamic>> docsToLogs(QuerySnapshot snapshot) {
    final Map<String, Map<String, dynamic>> logs = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      logs[doc.id] = data;
    }

    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: dailyLogsRef.orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        final Map<String, Map<String, dynamic>> logs =
        snapshot.hasData ? docsToLogs(snapshot.data!) : {};
        final selectedLog = logs[dateKey(selectedDay)];

        return Scaffold(
          backgroundColor: AppColors.beige,
          appBar: AppBar(
            title: const Text("Daily Log"),
            backgroundColor: AppColors.petalRouge,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _calendarCard(logs),
                      const SizedBox(height: 18),
                      _selectedDayCard(selectedLog),
                      const SizedBox(height: 18),

                      if (logs.isNotEmpty) ...[
                        const Text(
                          "Logged Days 💗",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...logs.values.map((log) => _historyTile(log)),
                      ],
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

  Widget _calendarCard(Map<String, Map<String, dynamic>> logs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.now(),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        enabledDayPredicate: (day) => !isFutureDate(day),
        eventLoader: (day) {
          return logs.containsKey(dateKey(day)) ? ['log'] : [];
        },
        onDaySelected: (selected, focused) {
          if (isFutureDate(selected)) return;

          setState(() {
            selectedDay = selected;
            focusedDay = focused;
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppColors.petalRouge,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.petalRouge.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.petalRouge,
            shape: BoxShape.circle,
          ),
          disabledTextStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _selectedDayCard(Map<String, dynamic>? log) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('d MMMM yyyy').format(selectedDay),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),

          if (log == null)
            const Text(
              "No log yet for this day.",
              style: TextStyle(color: AppColors.greyText),
            )
          else
            Text(
              "Mood ${log['mood']} • Sleep ${log['sleep']}h • Water ${log['water']} • Weight ${log['weight']}kg",
              style: const TextStyle(color: AppColors.greyText),
            ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => openLogForm(existingLog: log),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.petalRouge,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(log == null ? "Add Log" : "Edit Log"),
                ),
              ),
              if (log != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: deleteSelectedLog,
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.petalRouge,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> log) {
    final timestamp = log['date'] as Timestamp;
    final date = timestamp.toDate();

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDay = date;
          focusedDay = date;
        });

        openLogForm(existingLog: log);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Text(
          "${DateFormat('d MMM yyyy').format(date)}\nMood ${log['mood']} • Sleep ${log['sleep']}h • Water ${log['water']}",
          style: const TextStyle(
            height: 1.4,
            color: AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _moodPicker(int mood, Function(int) onChanged) {
    final moods = ["😫", "😔", "😐", "😊", "🤩"];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(moods.length, (index) {
          final selected = mood == index + 1;

          return GestureDetector(
            onTap: () => onChanged(index + 1),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.petalFrost : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.petalRouge),
              ),
              child: Text(
                moods[index],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _counter(
      String emoji,
      String title,
      int value,
      String unit,
      VoidCallback minus,
      VoidCallback plus,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(onPressed: minus, icon: const Icon(Icons.remove)),
          Text("$value"),
          IconButton(onPressed: plus, icon: const Icon(Icons.add)),
          Text(unit),
        ],
      ),
    );
  }

  Widget _weightCounter(double value, Function(double) onChanged) {
    return _counter("⚖️", "Weight", value.toInt(), "kg", () {
      if (value > 1) onChanged(value - 1);
    }, () {
      onChanged(value + 1);
    });
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.petalFrost),
    );
  }
}