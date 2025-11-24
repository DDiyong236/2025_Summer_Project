import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DatePickerSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final Function(int, int) onDateSelected;

  const DatePickerSheet({
    Key? key,
    required this.initialYear,
    required this.initialMonth,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  final List<int> _years = List.generate(10, (index) => 2020 + index);
  final List<int> _months = List.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;

    int yearIndex = _years.indexOf(_selectedYear);
    if (yearIndex == -1) yearIndex = 0;

    _yearController = FixedExtentScrollController(initialItem: yearIndex);
    _monthController = FixedExtentScrollController(
      initialItem: _months.indexOf(_selectedMonth),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  Widget _buildPicker(
      List<int> items,
      FixedExtentScrollController controller,
      int selectedValue,
      ValueChanged<int> onChanged,
      bool isMonth,
      ) {
    return Container(
      width: 70.w,
      height: 55.h,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 16.h,
        physics: const FixedExtentScrollPhysics(),
        controller: controller,
        onSelectedItemChanged: (index) {
          onChanged(items[index]);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final int item = items[index];
            final bool isSelected = item == selectedValue;
            return Center(
              child: Text(
                isMonth ? item.toString().padLeft(2, '0') : item.toString(),
                style: TextStyle(
                  fontSize: isSelected ? 15.sp : 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.grey[400],
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = 0.35.sh;
    return Container(
      height: sheetHeight,
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 10.0.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.0.r),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 12.0.w),
              child: const Text(
                '날짜 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('년',
                        style:
                        TextStyle(fontSize: 16.sp, color: Color(0xFF000000))),
                    SizedBox(height: 5.h),
                    _buildPicker(_years, _yearController, _selectedYear, (year) {
                      setState(() => _selectedYear = year);
                    }, false),
                  ],
                ),
                SizedBox(width: 40.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('월',
                        style:
                        TextStyle(fontSize: 16.sp, color: Color(0xFF000000))),
                    SizedBox(height: 10.h),
                    _buildPicker(_months, _monthController, _selectedMonth,
                            (month) {
                          setState(() => _selectedMonth = month);
                        }, true),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD8ED8A),
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 48.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0.r),
              ),
            ),
            onPressed: () {
              widget.onDateSelected(_selectedYear, _selectedMonth);
              Navigator.pop(context);
            },
            child: Text(
              '저장',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}