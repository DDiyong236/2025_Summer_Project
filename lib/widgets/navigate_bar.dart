import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ActivePage { none, send, calendar, profile }

class NavigateBar extends StatelessWidget {
  final ActivePage activePage;
  const NavigateBar({
    Key? key,
    this.activePage = ActivePage.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFFD8ED8A);
    final Color inactiveColor = Colors.white;
    return BottomAppBar(
      height: 95.0.h,
      color: Colors.transparent,
      child: Padding(
        padding:
        EdgeInsets.only(left: 30.0.w, right: 40.0.w, top: 20.0.h, bottom: 10.0.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RawMaterialButton(
              onPressed: () {},
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFDDD7D7), width: 1.0),
              ),
              elevation: 0.0,
              fillColor: Colors.white,
              constraints: BoxConstraints.tightFor(
                width: 60.0.w,
                height: 60.0.w,
              ),
              child: Image.asset(
                'assets/img/plus.png',
                width: 20.0.w,
                height: 20.0.w,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 4.0.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0.r),
                border: Border.all(color: const Color(0xFFDDD7D7), width: 1.0),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          activePage == ActivePage.send
                              ? activeColor
                              : inactiveColor),
                    ),
                    icon: Image.asset(
                      'assets/img/send.png',
                      width: 36.0.w,
                      height: 28.0.h,
                    ),
                  ),
                  SizedBox(width: 8.0.w),
                  IconButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          activePage == ActivePage.calendar
                              ? activeColor
                              : inactiveColor),
                    ),
                    icon: Image.asset('assets/img/calendar.png',
                        width: 36.0.w, height: 28.0.h),
                  ),
                  SizedBox(width: 8.0.w),
                  IconButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          activePage == ActivePage.profile
                              ? activeColor
                              : inactiveColor),
                    ),
                    icon: Image.asset('assets/img/profile.png',
                        width: 36.0.w, height: 28.0.h),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}