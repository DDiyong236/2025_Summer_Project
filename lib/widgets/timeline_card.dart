import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TimelineCard extends StatelessWidget{
  final String day;
  final String title;
  final String startTime;
  final String stats;
  final String desc;
  final Color color;

  const TimelineCard({
    Key? key,
    required this.day,
    required this.title,
    required this.startTime,
    required this.stats,
    required this.desc,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Container(
      margin: EdgeInsets.only(bottom: 12.0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.0.w,
            margin: EdgeInsets.only(top: 10.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: const Color(0xFF000000),
                    height: 1.0,
                  ),
                ),
                Text(
                  "일",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: Container(
                padding: EdgeInsets.all(12.0.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Color(0xFF9E9E9E),
                    width: 1.0
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80.w,
                      height: 105.w,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000000),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            //시간
                            Row(
                              children: [
                                Icon(Icons.flag, size: 12.sp, color: Colors.red),
                                SizedBox(width: 4.w),
                                Text(
                                  startTime,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),

                            Row( // 통계
                              children: [
                                Icon(Icons.directions_walk,
                                    size: 12.sp, color: Colors.orange),
                                SizedBox(width: 4.w),
                                Text(
                                  stats,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            SizedBox(height: 8.h),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: const Color(0xFF707070),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ),
                  ]
                )
              )
          )
        ]
      )
    );
  }
}