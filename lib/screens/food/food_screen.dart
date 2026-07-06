import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_theme.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  bool isFutureDate(DateTime date) {
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.isAfter(cleanToday);
  }

  CollectionReference<Map<String, dynamic>> get foodLogsRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('foodLogs');
  }

  Future<void> saveFoodLog({
    required String breakfast,
    required String lunch,
    required String dinner,
    required String snacks,
    required int cravings,
    required String notes,
  }) async {
    final key = dateKey(selectedDay);

    await foodLogsRef.doc(key).set({
      'dateKey': key,
      'date': Timestamp.fromDate(
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
      ),
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'snacks': snacks,
      'cravings': cravings,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSelectedLog() async {
    await foodLogsRef.doc(dateKey(selectedDay)).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Food log deleted")),
    );
  }

  void openFoodForm({Map<String, dynamic>? existingLog}) {
    final breakfastController =
    TextEditingController(text: existingLog?['breakfast'] ?? '');
    final lunchController =
    TextEditingController(text: existingLog?['lunch'] ?? '');
    final dinnerController =
    TextEditingController(text: existingLog?['dinner'] ?? '');
    final snacksController =
    TextEditingController(text: existingLog?['snacks'] ?? '');
    final notesController =
    TextEditingController(text: existingLog?['notes'] ?? '');

    int cravings = existingLog?['cravings'] ?? 3;

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
                          ? "Food Check-in 🍓"
                          : "Edit Food Log ✨",
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

                    _textCard("🍳", "Breakfast", breakfastController),
                    _textCard("🍱", "Lunch", lunchController),
                    _textCard("🍲", "Dinner", dinnerController),
                    _textCard("🍪", "Snacks", snacksController),

                    _cravingsPicker(cravings, (value) {
                      setSheetState(() => cravings = value);
                    }),

                    _textCard("📝", "PCOS-friendly notes", notesController,
                        maxLines: 3),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await saveFoodLog(
                            breakfast: breakfastController.text.trim(),
                            lunch: lunchController.text.trim(),
                            dinner: dinnerController.text.trim(),
                            snacks: snacksController.text.trim(),
                            cravings: cravings,
                            notes: notesController.text.trim(),
                          );

                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Food log saved")),
                          );
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          "Save Food Log",
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
      stream: foodLogsRef.orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        final Map<String, Map<String, dynamic>> logs =
        snapshot.hasData ? docsToLogs(snapshot.data!) : {};

        final selectedLog = logs[dateKey(selectedDay)];

        return Scaffold(
          backgroundColor: AppColors.beige,
          appBar: AppBar(
            title: const Text("Food Tracker"),
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
                          "Logged Meals 🍓",
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
              "No food log yet for this day.",
              style: TextStyle(color: AppColors.greyText),
            )
          else
            Text(
              "Breakfast: ${log['breakfast'] == '' ? '-' : log['breakfast']}\n"
                  "Lunch: ${log['lunch'] == '' ? '-' : log['lunch']}\n"
                  "Dinner: ${log['dinner'] == '' ? '-' : log['dinner']}\n"
                  "Cravings ${log['cravings']}/5",
              style: const TextStyle(
                color: AppColors.greyText,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => openFoodForm(existingLog: log),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.petalRouge,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(log == null ? "Add Food Log" : "Edit Food Log"),
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

        openFoodForm(existingLog: log);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Text(
          "${DateFormat('d MMM yyyy').format(date)}\n"
              "Breakfast: ${log['breakfast'] == '' ? '-' : log['breakfast']} • "
              "Cravings ${log['cravings']}/5",
          style: const TextStyle(
            height: 1.4,
            color: AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _textCard(
      String emoji,
      String title,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: title,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cravingsPicker(int cravings, Function(int) onChanged) {
    final levels = ["😌", "🙂", "😐", "😣", "🍫"];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cravings level",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(levels.length, (index) {
              final selected = cravings == index + 1;

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
                    levels[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.petalFrost),
    );
  }
}