import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'survey_6.dart';

class Survey5 extends StatefulWidget {
  final String nickname;
  final int characterIndex;
  final List<int> environmentIndices;
  final List<int> purposeIndices;
  const Survey5(
      {Key? key,
        required this.nickname,
        required this.characterIndex,
        required this.environmentIndices,
        required this.purposeIndices})
      : super(key: key);

  @override
  _Survey5State createState() => _Survey5State();
}

class _Survey5State extends State<Survey5> {
  final List<String> items = [
    '10분 이내',
    '10분 - 30분',
    '30분 - 1시간',
    '1시간 - 2시간',
    '2시간 - 3시간',
    '3시간 이상'
  ];
  List<int> _selectedIndices = [];

  void _saveSelectionAndNavigate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Survey6(
          nickname: widget.nickname,
          characterIndex: widget.characterIndex,
          environmentIndices: widget.environmentIndices,
          purposeIndices: widget.purposeIndices,
          timeIndices: _selectedIndices,
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
                  tween: Tween<double>(begin: 0.667, end: 0.833),
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
                  '적당한 산책 시간을 알려주세요',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 72.h),
                SizedBox(
                  height: 0.5.sh,
                  child: Wrap(
                    spacing: 10.0.w,
                    runSpacing: 15.0.h,
                    children: items.map((item) {
                      int index = items.indexOf(item);
                      final isSelected = _selectedIndices.contains(index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIndices.remove(index);
                            } else {
                              _selectedIndices.add(index);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 32.0.w, vertical: 10.0.h),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              backgroundColor: _selectedIndices.isNotEmpty
                  ? const Color(0xFFBFE240)
                  : const Color(0x80BFE240),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}