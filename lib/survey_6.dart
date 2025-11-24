import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'loginscreen.dart';

class Survey6 extends StatefulWidget {
  final String nickname;
  final int characterIndex;
  final List<int> environmentIndices;
  final List<int> purposeIndices;
  final List<int> timeIndices;
  const Survey6(
      {Key? key,
        required this.nickname,
        required this.characterIndex,
        required this.environmentIndices,
        required this.purposeIndices,
        required this.timeIndices})
      : super(key: key);

  @override
  _Survey6State createState() => _Survey6State();
}

class _Survey6State extends State<Survey6> {
  final List<String> items = [
    '반려동물 산책 가능 장소',
    '포토 스팟',
    '벤치, 쉼터',
    '화장실 근처',
    '없음'
  ];
  List<int> _selectedIndices = [];

  void _saveSelectionAndNavigate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
          nickname: widget.nickname,
          characterIndex: widget.characterIndex,
          environmentIndices: widget.environmentIndices,
          purposeIndices: widget.purposeIndices,
          timeIndices: widget.timeIndices,
          featureIndices: _selectedIndices,
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
                  tween: Tween<double>(begin: 0.833, end: 1.0),
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
                  '산책 시 선호하는 요소를 골라주세요',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 48.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10.0.w,
                      runSpacing: 10.0.h,
                      children: [
                        _buildChoiceButton(context, items[0], 0),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.0.w,
                      runSpacing: 10.0.h,
                      children: items.sublist(1).map((item) {
                        int index = items.indexOf(item);
                        return _buildChoiceButton(context, item, index);
                      }).toList(),
                    ),
                  ],
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

  Widget _buildChoiceButton(BuildContext context, String item, int index) {
    final isSelected = _selectedIndices.contains(index);
    return GestureDetector(
      onTap: () {
        setState(() {
          final noneButtonIndex = 4;
          if (index == noneButtonIndex) {
            _selectedIndices.clear();
            if (!isSelected) {
              _selectedIndices.add(index);
            }
          } else {
            _selectedIndices.remove(noneButtonIndex);

            if (isSelected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.0.w, vertical: 10.0.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40.0.r),
          color:
          isSelected ? const Color(0x28BFE240) : const Color(0xFFFFFFFF),
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
  }
}