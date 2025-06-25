import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/pages/Admin/leave_manage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Adminleavepage extends StatefulWidget {
  const Adminleavepage({super.key});

  @override
  State<Adminleavepage> createState() => _AdminleavepageState();
}

class _AdminleavepageState extends State<Adminleavepage> {
  bool _ascending = false; // false = Descending by default
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    Query leaveQuery = FirebaseFirestore.instance.collection('LeaveRequests');
    if (_statusFilter != 'All') {
      leaveQuery = leaveQuery.where('Status', isEqualTo: _statusFilter);
    }
    leaveQuery = leaveQuery.orderBy('RequestDate', descending: !_ascending);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: const Text(
          "Leave Request",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                if (value == 'Ascending') {
                  _ascending = true;
                } else if (value == 'Descending') {
                  _ascending = false;
                } else {
                  _statusFilter = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('All Status', style: TextStyle(fontFamily: 'NexaBold')),
              ),
              const PopupMenuItem(
                value: 'Pending',
                child: Text('Pending', style: TextStyle(fontFamily: 'NexaBold')),
              ),
              const PopupMenuItem(
                value: 'Approved',
                child: Text('Approved', style: TextStyle(fontFamily: 'NexaBold')),
              ),
              const PopupMenuItem(
                value: 'Rejected',
                child: Text('Rejected', style: TextStyle(fontFamily: 'NexaBold')),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Ascending',
                child: Text('Request Date Ascending', style: TextStyle(fontFamily: 'NexaBold')),
              ),
              const PopupMenuItem(
                value: 'Descending',
                child: Text('Request Date Descending', style: TextStyle(fontFamily: 'NexaBold')),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: leaveQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Leave Request Found!",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "NexaBold",
                  color: Colors.black,
                  letterSpacing: 0.7,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaveRequestDetailPage(
                        data: data,
                        docId: docs[index].id,
                      ),
                    ),
                  );
                },
                child: Card(
                  color: Colors.black,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              data['Status'] == 'Approved'
                                  ? FontAwesomeIcons.circleCheck
                                  : data['Status'] == 'Rejected'
                                      ? FontAwesomeIcons.circleXmark
                                      : FontAwesomeIcons.clock,
                              color: data['Status'] == 'Approved'
                                  ? Colors.green
                                  : data['Status'] == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              (data['Status'] ?? 'Pending').toString(),
                              style: TextStyle(
                                fontFamily: "NexaBold",
                                fontSize: 18,
                                color: data['Status'] == 'Approved'
                                    ? Colors.green
                                    : data['Status'] == 'Rejected'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "Name : ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${data['StudentName'] ?? ''}",
                              style: const TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "From : ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${data['StartDate'] ?? ''}",
                              style: const TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "To      : ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${data['EndDate'] ?? ''}",
                              style: const TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${data['RequestDate'] ?? ''}",
                              style: const TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
