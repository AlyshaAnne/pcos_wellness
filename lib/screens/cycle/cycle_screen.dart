import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_theme.dart';

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String formatListOrText(dynamic value) {
    if (value == null) return '-';
    if (value is List) return value.isEmpty ? '-' : value.join(', ');
    if (value is String) return value.trim().isEmpty ? '-' : value;
    return value.toString();
  }

  List<String> toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String && value.trim().isNotEmpty) return [value];
    return [];
  }

  bool isFutureDate(DateTime date) {
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.isAfter(cleanToday);
  }

  CollectionReference<Map<String, dynamic>> get cycleLogsRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycleLogs');
  }

  Future<void> saveCycleLog({
    required String periodStatus,
    required String flow,
    required String pain,
    required String discharge,
    required List<String> symptoms,
    required List<String> medications,
    required String notes,
  }) async {
    final key = dateKey(selectedDay);

    await cycleLogsRef.doc(key).set({
      'dateKey': key,
      'date': Timestamp.fromDate(
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
      ),
      'periodStatus': periodStatus,
      'flow': flow,
      'pain': pain,
      'discharge': discharge,
      'symptoms': symptoms,
      'medications': medications,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSelectedLog() async {
    await cycleLogsRef.doc(dateKey(selectedDay)).delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cycle log deleted")),
    );
  }

  void openCycleForm({Map<String, dynamic>? existingLog}) {
    String periodStatus = existingLog?['periodStatus'] ?? 'No Bleeding';
    String flow = existingLog?['flow'] ?? 'None';
    String pain = existingLog?['pain'] ?? 'None';
    String discharge = existingLog?['discharge'] ?? 'None';

    List<String> symptoms = toStringList(existingLog?['symptoms']);
    List<String> medications = toStringList(existingLog?['medications']);

    final notesController =
    TextEditingController(text: existingLog?['notes'] ?? '');

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
                          ? "Cycle Check-in 🌸"
                          : "Edit Cycle Log ✨",
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

                    _choiceCard(
                      title: "Period Status",
                      options: const ["Period", "Spotting", "No Bleeding"],
                      selected: periodStatus,
                      onSelected: (value) {
                        setSheetState(() => periodStatus = value);
                      },
                    ),

                    _choiceCard(
                      title: "Flow",
                      options: const ["None", "Light", "Medium", "Heavy"],
                      selected: flow,
                      onSelected: (value) {
                        setSheetState(() => flow = value);
                      },
                    ),

                    _choiceCard(
                      title: "Pain Level",
                      options: const ["None", "Mild", "Moderate", "Severe"],
                      selected: pain,
                      onSelected: (value) {
                        setSheetState(() => pain = value);
                      },
                    ),

                    _choiceCard(
                      title: "Discharge",
                      options: const [
                        "None",
                        "Sticky",
                        "Creamy",
                        "Watery",
                        "Egg White",
                      ],
                      selected: discharge,
                      onSelected: (value) {
                        setSheetState(() => discharge = value);
                      },
                    ),

                    _multiChoiceCard(
                      title: "Symptoms",
                      options: const [
                        "Acne",
                        "Bloating",
                        "Cramps",
                        "Headache",
                        "Breast tenderness",
                        "Fatigue",
                        "Mood swings",
                        "Nausea",
                        "Back pain",
                        "Food cravings",
                      ],
                      selected: symptoms,
                      onChanged: (newList) {
                        setSheetState(() => symptoms = newList);
                      },
                    ),

                    _multiChoiceCard(
                      title: "Medication / Supplements",
                      options: const [
                        "Metformin",
                        "Birth Control",
                        "Painkillers",
                        "Inositol",
                        "Vitamin D",
                        "Iron",
                        "Magnesium",
                        "Other",
                      ],
                      selected: medications,
                      onChanged: (newList) {
                        setSheetState(() => medications = newList);
                      },
                    ),

                    _textCard("📝", "Notes", notesController, maxLines: 3),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await saveCycleLog(
                            periodStatus: periodStatus,
                            flow: flow,
                            pain: pain,
                            discharge: discharge,
                            symptoms: symptoms,
                            medications: medications,
                            notes: notesController.text.trim(),
                          );

                          if (!mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cycle log saved")),
                          );
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          "Save Cycle Log",
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
      stream: cycleLogsRef.orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        final Map<String, Map<String, dynamic>> logs =
        snapshot.hasData ? docsToLogs(snapshot.data!) : {};

        final selectedLog = logs[dateKey(selectedDay)];

        return Scaffold(
          backgroundColor: AppColors.beige,
          appBar: AppBar(
            title: const Text("Cycle Tracker"),
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
                          "Cycle History 🌸",
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
          disabledTextStyle: TextStyle(color: Colors.grey.shade400),
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
              "No cycle log yet for this day.",
              style: TextStyle(color: AppColors.greyText),
            )
          else
            Text(
              "Status: ${log['periodStatus'] ?? '-'}\n"
                  "Flow: ${log['flow'] ?? '-'} • Pain: ${log['pain'] ?? '-'}\n"
                  "Discharge: ${log['discharge'] ?? '-'}\n"
                  "Symptoms: ${formatListOrText(log['symptoms'])}\n"
                  "Medication: ${formatListOrText(log['medications'])}",
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
                  onPressed: () => openCycleForm(existingLog: log),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.petalRouge,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(log == null ? "Add Cycle Log" : "Edit Cycle Log"),
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

        openCycleForm(existingLog: log);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Text(
          "${DateFormat('d MMM yyyy').format(date)}\n"
              "Status: ${log['periodStatus'] ?? '-'} • "
              "Flow: ${log['flow'] ?? '-'} • Pain: ${log['pain'] ?? '-'}",
          style: const TextStyle(
            height: 1.4,
            color: AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = option == selected;

              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: AppColors.petalFrost,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.petalRouge : AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => onSelected(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _multiChoiceCard({
    required String title,
    required List<String> options,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected.contains(option);

              return FilterChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: AppColors.petalFrost,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.petalRouge : AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (value) {
                  final updated = List<String>.from(selected);

                  if (value) {
                    updated.add(option);
                  } else {
                    updated.remove(option);
                  }

                  onChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.petalFrost),
    );
  }
}