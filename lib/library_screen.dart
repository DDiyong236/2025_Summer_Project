import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/navigate_bar.dart';
import 'widgets/screen_title.dart';
import 'widgets/date_picker_sheet.dart';
import 'widgets/timeline_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isGalleryView = true;
  String _currentSortOrder = '날짜'; // 우측 상단 필터 버튼 텍스트 (고정)
  String _currentHeaderDate = '2025.10'; // 타임라인 상단 고정 헤더 텍스트
  bool _isDatePickerOpen = false;


  final List<Map<String, dynamic>> _timelineData = [
    {
      "day": "30",
      "title": "우리집 - 00공원",
      "startTime": "오후 2:00 출발",
      "stats": "10,760 / 1.3km / 1시간 18분",
      "desc": "오늘 하늘이 이뻤는데 뭐 산책이 어쩌구 저쩌구 이런거 오늘 하늘이 이뻤는데 뭐 산책이 어쩌구 이런거",
      "color": const Color(0xFF9DDBE7), // 하늘색
    },
    {
      "day": "28",
      "title": "우리집 - 00공원",
      "startTime": "오후 2:00 출발",
      "stats": "10,760 / 1.3km / 1시간 18분",
      "desc": "오늘 하늘이 이뻤는데 뭐 산책이 어쩌구 저쩌구 이런거...",
      "color": const Color(0xFFEEDD96), // 노란색
    },
    {
      "day": "21",
      "title": "우리집 - 00공원",
      "startTime": "오후 2:00 출발",
      "stats": "10,760 / 1.3km / 1시간 18분",
      "desc": "오늘 하늘이 이뻤는데 뭐 산책이 어쩌구 저쩌구...",
      "color": const Color(0xFFEAA695), // 분홍색
    },
    {
      "day": "15",
      "title": "한강 공원 산책",
      "startTime": "오전 10:00 출발",
      "stats": "5,300 / 3.0km / 50분",
      "desc": "날씨가 너무 좋아서 기분이 좋았다.",
      "color": const Color(0xFFBFE240), // 연두색
    },
  ];

  // 상단 필터 바 (갤러리/타임라인 토글 + 날짜 필터)
  Widget _buildFilterBar() {
    final ButtonStyle activeStyle = TextButton.styleFrom(
      backgroundColor: const Color(0x33D8ED8A),
      foregroundColor: Colors.black,
      fixedSize: Size(75.0.w, 30.0.h),
      minimumSize: Size.zero,
      textStyle: TextStyle(fontSize: 10.0.sp),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: const BorderSide(
            color: Color(0xFFBFE240),
            width: 1.0,
          )),
    );

    final ButtonStyle inactiveStyle = TextButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[700],
      fixedSize: Size(75.0.w, 30.0.h),
      minimumSize: Size.zero,
      textStyle: TextStyle(fontSize: 10.0.sp),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: const BorderSide(
            color: Color(0xFFDDD7D7),
            width: 1.0,
          )),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 10.0.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isGalleryView = true;
                  });
                },
                child: const Text('갤러리'),
                style: _isGalleryView ? activeStyle : inactiveStyle,
              ),
              SizedBox(width: 8.w),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isGalleryView = false;
                  });
                },
                child: const Text('타임라인'),
                style: !_isGalleryView ? activeStyle : inactiveStyle,
              ),
            ],
          ),
          InkWell(
            onTap: () {
              _showDatePickerSheet(context);
            },
            borderRadius: BorderRadius.circular(20.0.r),
            child: Container(
              height: 30.0.h,
              padding: EdgeInsets.symmetric(horizontal: 12.0.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0.r),
                color: _isDatePickerOpen ? const Color(0x33D8ED8A) : Colors.white,
                border: Border.all(
                  color: _isDatePickerOpen ? const Color(0xFFBFE240) : const Color(0xFFDDD7D7),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentSortOrder,
                    style: TextStyle(
                      fontSize: 10.0.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 4.0.w),
                  Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[700], size: 18.0.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 선택 바텀 시트
  void _showDatePickerSheet(BuildContext context) {
    setState(() {
      _isDatePickerOpen = true;
    });
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0.r)),
          ),
          child: DatePickerSheet(
            initialYear: 2025,
            initialMonth: 10,
            onDateSelected: (year, month) {
              setState(() {
                _currentHeaderDate = "$year.${month.toString().padLeft(2, '0')}";
              });
              print("데이터 요청: $year년 $month월");
            },
          ),
        );
      },
    ).whenComplete((){
      setState(() {
        _isDatePickerOpen = false;
      });
    });
  }

  Widget _buildGalleryBody() {
    return Center(
      child: Text(
        '갤러리 뷰 (GridView)가 여기에 표시됩니다.',
        style: TextStyle(color: Colors.grey[700], fontSize: 14.sp),
      ),
    );
  }

  // ⭐️ 타임라인 뷰 바디 (헤더 고정 + 리스트)
  Widget _buildTimelineBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 고정된 날짜 헤더
        Padding(
          padding: EdgeInsets.fromLTRB(20.0.w, 10.0.h, 20.0.w, 10.0.h),
          child: Text(
            _currentHeaderDate, // 예: 2025.10
            style: TextStyle(
              fontSize: 18.sp,
              color: const Color(0xFF484848),
            ),
          ),
        ),

        // 2. 스크롤 되는 리스트 영역
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w),
            itemCount: _timelineData.length,
            itemBuilder: (context, index) {
              final item = _timelineData[index];
              // 외부 위젯(TimelineCard) 사용
              return TimelineCard(
                day: item['day'],
                title: item['title'],
                startTime: item['startTime'],
                stats: item['stats'],
                desc: item['desc'],
                color: item['color'],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: false , // 바텀 네비게이션 뒤로 내용이 비치게 하려면 true
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 화면 제목
          ScreenTitle(title: '라이브러리'),

          // 필터 바
          Padding(
            padding: EdgeInsets.only(top: 8.0.h),
            child: _buildFilterBar(),
          ),

          Expanded(
            child: _isGalleryView ? _buildGalleryBody() : _buildTimelineBody(),
          ),
        ],
      ),
      bottomNavigationBar: const NavigateBar(
        activePage: ActivePage.calendar,
      ),
    );
  }
}