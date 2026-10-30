import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/security.dart';

class BookCounsellor extends StatefulWidget {
  final bool isAnonymous;
  final String? anonymousAlertReason;
  final String? preselectedCounsellorId;

  const BookCounsellor({
    super.key,
    this.isAnonymous = false,
    this.anonymousAlertReason,
    this.preselectedCounsellorId,
  });

  @override
  State<BookCounsellor> createState() => _BookCounsellorState();
}

class _BookCounsellorState extends State<BookCounsellor> {
  final _formKey = GlobalKey<FormState>();
  
  List<AppUser> _counsellors = [];
  AppUser? _selectedCounsellor;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCounsellors();
  }

  Future<void> _loadCounsellors() async {
    try {
      final list = await Services.db.getCounsellors();
      setState(() {
        _counsellors = list;
        if (list.isNotEmpty) {
          if (widget.preselectedCounsellorId != null) {
            _selectedCounsellor = list.firstWhere(
              (c) => c.uid == widget.preselectedCounsellorId,
              orElse: () => list[0],
            );
          } else {
            _selectedCounsellor = list[0];
          }
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedCounsellor == null) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final student = await Services.auth.getCurrentUser();
      if (student == null) throw Exception('User not logged in');

      final pseudonym = SecurityUtils.generatePseudonym(student.uid);

      final newAppt = Appointment(
        id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
        studentId: student.uid,
        studentPseudonym: widget.isAnonymous ? pseudonym : student.name,
        counsellorId: _selectedCounsellor!.uid,
        counsellorName: _selectedCounsellor!.name,
        status: 'pending',
        bookingDate: DateTime.now(),
        isAnonymous: widget.isAnonymous,
        anonymousAlertReason: widget.anonymousAlertReason,
      );

      await Services.db.bookAppointment(newAppt);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAnonymous 
                ? 'Confidential anonymous booking request submitted successfully.' 
                : 'Appointment request submitted. Wait for counsellor confirmation.',
          ),
          backgroundColor: AppTheme.alertSuccess,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: ${e.toString()}'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Counsellor'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isAnonymous) ...[
                      // Warning badge indicating this is an anonymous clinical referral
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.mintAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.mintAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.security_rounded, color: AppTheme.mintAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Confidential Booking Active: Your real name and profile details will be masked from the counsellor. Your session will appear as a clinical alert: "${widget.anonymousAlertReason}".',
                                style: const TextStyle(color: AppTheme.mintAccent, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Request an Offline Session',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please choose an available counsellor from our clinical support team. Once submitted, the counsellor will review your request, approve it, and set the meeting date and time.',
                      style: TextStyle(color: AppTheme.textMedium),
                    ),
                    const SizedBox(height: 32),

                    if (_counsellors.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassCardDecoration(),
                        child: const Text(
                          'No counsellors are registered in the portal at the moment. Please check back later.',
                          style: TextStyle(color: AppTheme.textLow),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select a Wellness Counsellor',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              
                              DropdownButtonFormField<AppUser>(
                                initialValue: _selectedCounsellor,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.medication_rounded, color: AppTheme.textLow),
                                ),
                                dropdownColor: AppTheme.slateCard,
                                items: _counsellors.map((c) {
                                  return DropdownMenuItem<AppUser>(
                                    value: c,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCounsellor = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitRequest,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(AppTheme.spaceDark),
                                          ),
                                        )
                                      : Text(widget.isAnonymous ? 'Confirm Anonymous Booking' : 'Submit Booking Request'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
