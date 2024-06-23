import 'package:flutter/material.dart';
import 'calendar_with_data_source_page.dart';

class CalendarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar Page'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FlexibleWorkingHoursPage()),
              );
            },
            child: Text('Flexible Working Hours'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CustomFirstDayOfWeekPage()),
              );
            },
            child: Text('Custom First Day of Week'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MonthAgendaViewPage()),
              );
            },
            child: Text('Month Agenda View'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarWithDataSourcePage()),
              );
            },
            child: Text('Calendar with Data Source'),
          ),
        ],
      ),
    );
  }
}

