import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  
  int _totalUsers = 0;
  int _totalAppointments = 0;
  int _todayAppointments = 0;
  int _upcomingAppointments = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final appointmentsSnapshot = await _firestore.collection('appointments').get();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todaySnapshot = await _firestore
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    final upcomingSnapshot = await _firestore
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .get();
    
    setState(() {
      _totalUsers = usersSnapshot.docs.length;
      _totalAppointments = appointmentsSnapshot.docs.length;
      _todayAppointments = todaySnapshot.docs.length;
      _upcomingAppointments = upcomingSnapshot.docs.length;
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: isDesktop ? 48 : (isTablet ? 40 : 32), color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: isDesktop ? 32 : (isTablet ? 28 : 24), fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: isDesktop ? 16 : (isTablet ? 14 : 12), color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildDetailRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize))),
        Expanded(child: Text(value, style: TextStyle(fontSize: fontSize))),
      ]),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> data, BuildContext context, double fontSize) {
    final date = (data['date'] as Timestamp).toDate();
    final birthday = data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${data['firstName']} ${data['lastName']}', style: TextStyle(fontSize: fontSize + 4)),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _buildDetailRow('Age', '${data['age'] ?? ''}', fontSize),
            _buildDetailRow('Sex', data['sex'] ?? '', fontSize),
            _buildDetailRow('Birthday', birthday != null ? DateFormat('yyyy-MM-dd').format(birthday) : '', fontSize),
            _buildDetailRow('Address', data['address'] ?? '', fontSize),
            _buildDetailRow('Doctor', data['doctor'] ?? '', fontSize),
            _buildDetailRow('Date', DateFormat('yyyy-MM-dd').format(date), fontSize),
            _buildDetailRow('Time', data['time'] ?? '', fontSize),
            _buildDetailRow('Phone', data['phone'] ?? '', fontSize),
            _buildDetailRow('Reason', data['reason'] ?? '', fontSize),
            _buildDetailRow('Status', data['status'] ?? 'upcoming', fontSize),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(fontSize: fontSize)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontSize = ResponsiveHelper.getFontSize(context);
    final padding = ResponsiveHelper.getPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel', style: TextStyle(fontSize: isDesktop ? 24 : (isTablet ? 22 : 20))),
        backgroundColor: const Color(0xFF3bc1ff),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard, size: isDesktop ? 24 : 20), child: isDesktop ? const Text('Dashboard') : null),
            Tab(icon: Icon(Icons.calendar_month, size: isDesktop ? 24 : 20), child: isDesktop ? const Text('Appointments') : null),
            Tab(icon: Icon(Icons.people, size: isDesktop ? 24 : 20), child: isDesktop ? const Text('Users') : null),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          SingleChildScrollView(
            padding: padding,
            child: Column(children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isMobile ? 1.2 : 1.5,
                children: [
                  _buildStatCard(title: 'Total Users', value: '$_totalUsers', icon: Icons.people, color: Colors.blue, isDesktop: isDesktop, isTablet: isTablet),
                  _buildStatCard(title: 'Total Appointments', value: '$_totalAppointments', icon: Icons.calendar_month, color: Colors.green, isDesktop: isDesktop, isTablet: isTablet),
                  _buildStatCard(title: "Today's Appointments", value: '$_todayAppointments', icon: Icons.today, color: Colors.orange, isDesktop: isDesktop, isTablet: isTablet),
                  _buildStatCard(title: 'Upcoming', value: '$_upcomingAppointments', icon: Icons.upcoming, color: Colors.purple, isDesktop: isDesktop, isTablet: isTablet),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Recent Appointments',
                    style: TextStyle(fontSize: isDesktop ? 22 : (isTablet ? 20 : 18), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('appointments').orderBy('date', descending: true).limit(5).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final appointments = snapshot.data!.docs;
                      if (appointments.isEmpty) return Center(child: Text('No appointments', style: TextStyle(fontSize: fontSize)));
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final doc = appointments[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final date = (data['date'] as Timestamp).toDate();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3bc1ff),
                              radius: isDesktop ? 24 : (isTablet ? 20 : 16),
                              child: Text(
                                '${data['firstName']?[0] ?? ''}${data['lastName']?[0] ?? ''}',
                                style: TextStyle(color: Colors.white, fontSize: fontSize),
                              ),
                            ),
                            title: Text('${data['firstName']} ${data['lastName']}', style: TextStyle(fontSize: fontSize)),
                            subtitle: Text(
                              '${data['doctor']} - ${DateFormat('MMM dd').format(date)}',
                              style: TextStyle(fontSize: fontSize - 2),
                            ),
                            trailing: Chip(
                              label: Text(data['status'] ?? 'upcoming', style: TextStyle(fontSize: fontSize - 2)),
                              backgroundColor: data['status'] == 'cancelled' ? Colors.red.shade100 : Colors.green.shade100,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ]),
              ),
            ]),
          ),

          // Appointments Tab
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('appointments').orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final appointments = snapshot.data!.docs;
              if (appointments.isEmpty) return Center(child: Text('No appointments', style: TextStyle(fontSize: fontSize)));
              return ListView.builder(
                padding: padding,
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final doc = appointments[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  return Card(
                    margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['status'] == 'cancelled' ? Colors.red : const Color(0xFF3bc1ff),
                        radius: isDesktop ? 24 : (isTablet ? 20 : 16),
                        child: Text(
                          '${data['firstName']?[0] ?? ''}${data['lastName']?[0] ?? ''}',
                          style: TextStyle(color: Colors.white, fontSize: fontSize),
                        ),
                      ),
                      title: Text('${data['firstName']} ${data['lastName']}', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Doctor: ${data['doctor']}', style: TextStyle(fontSize: fontSize - 2)),
                        Text('Date: ${DateFormat('yyyy-MM-dd').format(date)} | Time: ${data['time']}', style: TextStyle(fontSize: fontSize - 2)),
                        Text('Phone: ${data['phone']}', style: TextStyle(fontSize: fontSize - 2)),
                      ]),
                      trailing: PopupMenuButton(
                        icon: Icon(Icons.more_vert, size: isDesktop ? 28 : 24),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Text('View Details', style: TextStyle(fontSize: fontSize)),
                          ),
                          if (data['status'] != 'cancelled')
                            PopupMenuItem(
                              value: 'cancel',
                              child: Text('Cancel', style: TextStyle(color: Colors.red, fontSize: fontSize)),
                            ),
                        ],
                        onSelected: (value) async {
                          if (value == 'cancel') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Cancel Appointment', style: TextStyle(fontSize: fontSize + 4)),
                                content: Text('Are you sure?', style: TextStyle(fontSize: fontSize)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('No', style: TextStyle(fontSize: fontSize)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: Text('Yes', style: TextStyle(fontSize: fontSize)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _firestore.collection('appointments').doc(doc.id).update({'status': 'cancelled'});
                            }
                          } else if (value == 'view') {
                            _showAppointmentDetails(data, context, fontSize);
                          }
                        },
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),

          // Users Tab
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.docs;
              if (users.isEmpty) return Center(child: Text('No users', style: TextStyle(fontSize: fontSize)));
              return ListView.builder(
                padding: padding,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['isAdmin'] == true ? Colors.amber : const Color(0xFF3bc1ff),
                        radius: isDesktop ? 24 : (isTablet ? 20 : 16),
                        child: Text(
                          '${data['firstName']?[0] ?? ''}${data['lastName']?[0] ?? ''}',
                          style: TextStyle(color: Colors.white, fontSize: fontSize),
                        ),
                      ),
                      title: Text('${data['firstName']} ${data['lastName']}', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['email'] ?? '', style: TextStyle(fontSize: fontSize - 2)),
                        Text('Phone: ${data['phone'] ?? ''}', style: TextStyle(fontSize: fontSize - 2)),
                      ]),
                      trailing: data['isAdmin'] == true
                        ? Chip(
                            label: Text('ADMIN', style: TextStyle(fontSize: fontSize - 2)),
                            backgroundColor: Colors.amber,
                          )
                        : null,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}