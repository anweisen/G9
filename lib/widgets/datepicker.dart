import 'package:flutter/material.dart';

import '../util/dates.dart';

class DatePicker extends StatefulWidget {
  const DatePicker({super.key, this.date, required this.onDateChanged});

  final DateTime? date;
  final Function(DateTime) onDateChanged;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {

  late DateTime _selectedDate;
  late DateTime _monthBeginDate;

  @override
  void initState() {
    _selectedDate = widget.date ?? DateTime.now();
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _monthBeginDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    super.initState();
  }

  void _selectMonth(DateTime date) {
    setState(() {
      _monthBeginDate = DateTime(date.year, date.month, 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _monthBeginDate = DateTime(date.year, date.month, 1);
      _selectedDate = date;
    });
    widget.onDateChanged(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth > 400 ? 18 : 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.dividerColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 20), child: Icon(Icons.chevron_left_rounded, color: theme.primaryColor, size: 22)),
                        onTap: () => _selectMonth(DateTime(_monthBeginDate.year, _monthBeginDate.month - 1, 1))
                    ),
                    Text("${DateHelper.nameOfMonth(_monthBeginDate.month)} ${_monthBeginDate.year}", style: theme.textTheme.bodyMedium),
                    GestureDetector(
                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 20), child: Icon(Icons.chevron_right_rounded, color: theme.primaryColor, size: 22)),
                        onTap: () => _selectMonth(DateTime(_monthBeginDate.year, _monthBeginDate.month + 1, 1))
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              for (DateTime monthBegin in _getMonthBeginningDates(_monthBeginDate))
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (DateTime date in _getWeekDates(monthBegin))
                      _buildDate(date, constraints, theme),
                    ],
                  )
            ],
          ),
        );
      }
    );
  }

  List<DateTime> _getMonthBeginningDates(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    return List.generate(6, (index) => firstDayOfMonth.add(Duration(days: index * 7)));
  }

  List<DateTime> _getWeekDates(DateTime date) {
    final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => firstDayOfWeek.add(Duration(days: index)));
  }

  Widget _buildDate(DateTime date, BoxConstraints constraints, ThemeData theme) {
    return GestureDetector(
      onTap: () => date.month != _monthBeginDate.month ? _selectMonth(date) : _selectDate(date),
      child: Container(
        width: (constraints.maxWidth > 400 ? 18 : 16) * 2.5,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: _selectedDate == date ? BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).primaryColor,
        ) : null,
        child: Text("${date.day}", textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(
            color: date.month != _monthBeginDate.month ? theme.shadowColor : _selectedDate != date ? theme.primaryColor : theme.scaffoldBackgroundColor,
            fontSize: (constraints.maxWidth > 400 ? 18 : 16)
        ),),
      ),
    );
  }
}

