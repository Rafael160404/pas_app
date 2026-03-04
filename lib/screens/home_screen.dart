import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/maps_service.dart';
import 'login_screen.dart';
import 'appointments_screen.dart';
import 'doctors_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import '../utils/responsive_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapsService _mapsService = MapsService();
  DateTime _selectedDate = DateTime.now();
  String? _userName;
  String? _userEmail;
  bool _isAdmin = false;
  
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initMap();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
          _userEmail = data['email'] ?? user.email;
          _isAdmin = data['isAdmin'] ?? false;
        });
      }
    }
  }

  Future<void> _initMap() async {
    final clinicLocation = _mapsService.getClinicLocation();
    
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('clinic'),
          position: clinicLocation,
          infoWindow: const InfoWindow(
            title: 'ICCT Taytay Colleges',
            snippet: 'Pagan Appointment System Clinic',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
      _isMapReady = true;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _openDirections() async {
    final clinicLocation = _mapsService.getClinicLocation();
    final url = _mapsService.getDirectionsUrl(clinicLocation);
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontSize = ResponsiveHelper.getFontSize(context);
    final padding = ResponsiveHelper.getPadding(context);

    return Scaffold(
      drawer: _buildDrawer(context, isMobile, isTablet, isDesktop, fontSize),
      appBar: AppBar(
        title: Text(
          'Pagan Appointment System',
          style: TextStyle(fontSize: isDesktop ? 24 : (isTablet ? 20 : 18)),
        ),
        backgroundColor: const Color(0xFF3bc1ff),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context, isMobile, isTablet, isDesktop),
            _buildUpcomingCard(context, isMobile, isTablet, isDesktop),
            Padding(
              padding: padding,
              child: isMobile
                  ? Column(
                      children: [
                        _buildCalendar(context, isMobile, isTablet, isDesktop),
                        const SizedBox(height: 16),
                        _buildRecentAppointments(context, isMobile, isTablet, isDesktop),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCalendar(context, isMobile, isTablet, isDesktop)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildRecentAppointments(context, isMobile, isTablet, isDesktop)),
                      ],
                    ),
            ),
            _buildInfoCards(context, isMobile, isTablet, isDesktop),
            _buildMapCard(context, isMobile, isTablet, isDesktop),
            _buildFooter(context, isMobile, isTablet, isDesktop),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen())),
        backgroundColor: const Color(0xFF3bc1ff),
        child: Icon(Icons.add, size: isDesktop ? 32 : (isTablet ? 28 : 24), color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isMobile, bool isTablet, bool isDesktop, double fontSize) {
    final user = _authService.getCurrentUser();
    
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Image.asset('assets/images/pagan.png', height: isDesktop ? 100 : (isTablet ? 80 : 60), errorBuilder: (_, __, ___) => const Text('Logo')),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(icon: Icons.dashboard, title: 'Dashboard', fontSize: fontSize, onTap: () => Navigator.pop(context)),
                  _buildDrawerItem(icon: Icons.calendar_month, title: 'Appointment', fontSize: fontSize, onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
                  }),
                  _buildDrawerItem(icon: Icons.medical_services, title: 'Doctors', fontSize: fontSize, onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsScreen()));
                  }),
                  if (_isAdmin) _buildDrawerItem(icon: Icons.admin_panel_settings, title: 'Admin Panel', fontSize: fontSize, onTap: () async {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: isDesktop ? 40 : (isTablet ? 35 : 30),
                    backgroundColor: const Color(0xFF3bc1ff),
                    child: Text(
                      _userName?.isNotEmpty == true ? _userName![0].toUpperCase() : 'U',
                      style: TextStyle(color: Colors.white, fontSize: isDesktop ? 32 : (isTablet ? 28 : 24), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_userName ?? 'Loading...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                  Text(_userEmail ?? user?.email ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: fontSize - 2)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        icon: Icon(Icons.edit, size: fontSize),
                        label: Text('Edit Profile', style: TextStyle(fontSize: fontSize - 2)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        icon: Icon(Icons.logout, size: fontSize),
                        label: Text('Logout', style: TextStyle(fontSize: fontSize - 2)),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required double fontSize, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: fontSize + 4),
      title: Text(title, style: TextStyle(fontSize: fontSize)),
      onTap: onTap,
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      height: isDesktop ? 300 : (isTablet ? 250 : 200),
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/doctors.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PAS, Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 48 : (isTablet ? 40 : 32),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your health, on schedule',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF53afff), Color(0xFF3c00ff)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Stay Informed! Upcoming Appointment Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen())),
            child: Text(
              'view details',
              style: TextStyle(color: Colors.white70, fontSize: isDesktop ? 18 : (isTablet ? 16 : 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    final now = DateTime.now();
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
              icon: Icon(Icons.chevron_left, size: isDesktop ? 32 : (isTablet ? 28 : 24)),
              onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1)),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: TextStyle(fontSize: isDesktop ? 20 : (isTablet ? 18 : 16), fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, size: isDesktop ? 32 : (isTablet ? 28 : 24)),
              onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1)),
            ),
          ]),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: isMobile ? 1 : 1.2,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekday + 2;
              if (dayNumber < 1 || dayNumber > daysInMonth) return Container();
              final isToday = dayNumber == now.day && _selectedDate.month == now.month && _selectedDate.year == now.year;
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: isToday ? const Color(0xFF3bc1ff) : null),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.black87,
                      fontWeight: isToday ? FontWeight.bold : null,
                      fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAppointments(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    final user = _authService.getCurrentUser();
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Recent Appointments',
          style: TextStyle(fontSize: isDesktop ? 20 : (isTablet ? 18 : 16), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (user != null)
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('appointments').where('userId', isEqualTo: user.uid).orderBy('date', descending: true).limit(3).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final appointments = snapshot.data!.docs;
              if (appointments.isEmpty) return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No appointments yet', style: TextStyle(fontSize: isDesktop ? 16 : 14)),
                ),
              );
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final data = appointments[index].data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${data['firstName']} ${data['lastName']}',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: isDesktop ? 16 : (isTablet ? 15 : 14)),
                      ),
                      const SizedBox(height: 4),
                      Text('Doctor: ${data['doctor']}', style: TextStyle(fontSize: isDesktop ? 14 : (isTablet ? 13 : 12))),
                      Text('Date: ${DateFormat('MMM dd, yyyy').format(date)}', style: TextStyle(fontSize: isDesktop ? 14 : (isTablet ? 13 : 12))),
                      Text('Time: ${data['time'] ?? ''}', style: TextStyle(fontSize: isDesktop ? 14 : (isTablet ? 13 : 12))),
                    ]),
                  );
                },
              );
            },
          ),
      ]),
    );
  }

  Widget _buildInfoCards(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.2 : 1.5,
        children: [
          _buildInfoCard(icon: Icons.location_on, title: 'Our Location', subtitle: 'ICCT Taytay Colleges', isDesktop: isDesktop, isTablet: isTablet),
          _buildInfoCard(icon: Icons.phone, title: 'Call Us', subtitle: '09123456789', isDesktop: isDesktop, isTablet: isTablet),
          _buildInfoCard(icon: Icons.email, title: 'Email', subtitle: 'pagan@gmail.com', isDesktop: isDesktop, isTablet: isTablet),
          _buildInfoCard(icon: Icons.calendar_today, title: 'Booking', subtitle: 'Make an Appointment!', isDesktop: isDesktop, isTablet: isTablet),
          _buildInfoCard(icon: Icons.access_time, title: 'Opening Hours', subtitle: 'Mon-Fri: 10:30 AM - 03:00 PM\nSat: 10:30 AM - 12:00 PM', isDesktop: isDesktop, isTablet: isTablet),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, required bool isDesktop, required bool isTablet}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: isDesktop ? 40 : (isTablet ? 36 : 32), color: const Color(0xFF3bc1ff)),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: isDesktop ? 16 : (isTablet ? 14 : 12)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: isDesktop ? 12 : (isTablet ? 11 : 10), color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildMapCard(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    final clinicLocation = _mapsService.getClinicLocation();

    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Find Us On Map',
                style: TextStyle(fontSize: isDesktop ? 24 : (isTablet ? 20 : 18), fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: _openDirections,
                icon: Icon(Icons.directions, size: isDesktop ? 20 : 16),
                label: Text('Get Directions', style: TextStyle(fontSize: isDesktop ? 16 : 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3bc1ff),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: isDesktop ? 400 : (isTablet ? 300 : 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: clinicLocation,
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationEnabled: false,  // Disabled since we removed location
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                  ),
                  if (!_isMapReady)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF53afff), Color(0xFF3c00ff)]),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'PAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient Appointment System',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isDesktop ? 14 : (isTablet ? 12 : 10),
                  ),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Quick Links',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isDesktop ? 14 : (isTablet ? 12 : 10),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Appointments',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isDesktop ? 14 : (isTablet ? 12 : 10),
                    ),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(
            '© 2026 PAS | All Rights Reserved',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isDesktop ? 14 : (isTablet ? 12 : 10),
            ),
          ),
        ],
      ),
    );
  }
}