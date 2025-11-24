import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'survey_4.dart';

class Survey3 extends StatefulWidget {
  final String nickname;
  final int characterIndex;
  const Survey3(
      {Key? key, required this.nickname, required this.characterIndex})
      : super(key: key);

  @override
  _Survey3State createState() => _Survey3State();
}

class _Survey3State extends State<Survey3> {
  final List<String> items = [
    '녹지 or 공원',
    '조용하고 감성있는 골목',
    '강변, 호수, 하천 주변',
    '카페 많은 거리'
  ];
  List<int> _selectedIndices = [];

  void _saveSelectionAndNavigate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Survey4(
          nickname: widget.nickname,
          characterIndex: widget.characterIndex,
          environmentIndices: _selectedIndices,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var tween = Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.ease));
          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
              top: 0.08.sh,
              left: 0.03.sh,
              right: 0.03.sh,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(15.r)),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.334, end: 0.5),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 7.0.h,
                      backgroundColor: const Color(0xFFF5F5F5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFBFE240),
                      ),
                    );
                  },
                ),
              )),
          Positioned(
            top: 0.13.sh,
            left: 0.025.sh,
            right: 0.025.sh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),
                Text(
                  'STEP 3',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF707070),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '어떤 산책 환경에 관심이 있으신가요?',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  height: 0.5.sh,
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndices.contains(index);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final isSelected =
                                _selectedIndices.contains(index);
                                if (isSelected) {
                                  _selectedIndices.remove(index);
                                } else {
                                  _selectedIndices.add(index);
                                }
                              });
                            },
                            child: Container(
                              height: 40.h,
                              margin: EdgeInsets.symmetric(vertical: 7.h),
                              padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40.0.r),
                                color: isSelected
                                    ? const Color(0x33BFE240)
                                    : const Color(0xFFFFFFFF),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFBFE240)
                                      : const Color(0xFFDDD7D7),
                                  width: 1.4,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    items[index],
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 15.w),
                                  Image.asset(
                                    'assets/img/walk_icon_${index + 1}.png',
                                    width: 20.w,
                                    height: 20.w,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0.85.sh,
            right: 0.10.sw,
            child: FloatingActionButton(
              onPressed: _selectedIndices.isNotEmpty
                  ? () {
                _saveSelectionAndNavigate(context);
              }
                  : null,
              elevation: 0,
              backgroundColor: _selectedIndices.isNotEmpty
                  ? const Color(0xFFBFE240)
                  : const Color(0x80BFE240),
              shape: const CircleBorder(),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}