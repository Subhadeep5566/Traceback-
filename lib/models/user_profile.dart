enum UserRole {
  student,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'STUDENT';
      case UserRole.admin:
        return 'COLLEGE ADMIN';
    }
  }

  bool get isStudent => this == UserRole.student;
  bool get isAdmin => this == UserRole.admin;
}

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String college;
  final String? profileImage;

  // Student-specific fields
  final String studentId;
  final String department;
  final bool sharePhone;
  final bool shareEmail;
  final bool shareStudentId;

  // College Admin-specific fields
  final String designation;
  final String office;
  final String officeLocation;
  final String contactMethod;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.college = 'Birla Global University',
    this.profileImage,
    this.studentId = 'BGU-2024-CS-042',
    this.department = 'School of Computer Science',
    this.sharePhone = true,
    this.shareEmail = true,
    this.shareStudentId = false,
    this.designation = 'Campus Security & Property Officer',
    this.office = 'BGU Asset Recovery Office',
    this.officeLocation = 'Administrative Block, Ground Floor, Room G-04',
    this.contactMethod = 'Phone & In-Person Verification',
  });

  bool get isStudent => role == UserRole.student;
  bool get isAdmin => role == UserRole.admin;

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? college,
    String? profileImage,
    String? studentId,
    String? department,
    bool? sharePhone,
    bool? shareEmail,
    bool? shareStudentId,
    String? designation,
    String? office,
    String? officeLocation,
    String? contactMethod,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      college: college ?? this.college,
      profileImage: profileImage ?? this.profileImage,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      sharePhone: sharePhone ?? this.sharePhone,
      shareEmail: shareEmail ?? this.shareEmail,
      shareStudentId: shareStudentId ?? this.shareStudentId,
      designation: designation ?? this.designation,
      office: office ?? this.office,
      officeLocation: officeLocation ?? this.officeLocation,
      contactMethod: contactMethod ?? this.contactMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'college': college,
      'profileImage': profileImage,
      'studentId': studentId,
      'department': department,
      'sharePhone': sharePhone,
      'shareEmail': shareEmail,
      'shareStudentId': shareStudentId,
      'designation': designation,
      'office': office,
      'officeLocation': officeLocation,
      'contactMethod': contactMethod,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? 'user_default',
      name: json['name'] as String? ?? 'BGU User',
      email: json['email'] as String? ?? 'student@bgu.ac.in',
      phone: json['phone'] as String? ?? '9876543210',
      role: (json['role'] as String?) == 'admin' ? UserRole.admin : UserRole.student,
      college: json['college'] as String? ?? 'Birla Global University',
      profileImage: json['profileImage'] as String?,
      studentId: json['studentId'] as String? ?? 'BGU-2024-CS-042',
      department: json['department'] as String? ?? 'School of Computer Science',
      sharePhone: json['sharePhone'] as bool? ?? true,
      shareEmail: json['shareEmail'] as bool? ?? true,
      shareStudentId: json['shareStudentId'] as bool? ?? false,
      designation: json['designation'] as String? ?? 'Campus Security & Property Officer',
      office: json['office'] as String? ?? 'BGU Asset Recovery Office',
      officeLocation: json['officeLocation'] as String? ?? 'Administrative Block, Ground Floor, Room G-04',
      contactMethod: json['contactMethod'] as String? ?? 'Phone & In-Person Verification',
    );
  }

  // Pre-configured default profiles for demonstration & testing
  static UserProfile defaultStudent({String? name, String? email, String? phone}) {
    return UserProfile(
      userId: 'student_current',
      name: name ?? 'Subhadeep',
      email: email ?? 'subhadeep@bgu.ac.in',
      phone: phone ?? '9876543210',
      role: UserRole.student,
      college: 'Birla Global University',
      studentId: 'BGU-2024-BTECH-042',
      department: 'School of Computer Science',
      sharePhone: true,
      shareEmail: true,
      shareStudentId: false,
    );
  }

  static UserProfile defaultAdmin({
    String? name,
    String? email,
    String? phone,
    String? officeLocation,
  }) {
    return UserProfile(
      userId: 'admin_bgu_01',
      name: name ?? 'Campus Security Desk',
      email: email ?? 'recovery.office@bgu.ac.in',
      phone: phone ?? '0674-7103001',
      role: UserRole.admin,
      college: 'Birla Global University',
      designation: 'Campus Property & Recovery Officer',
      office: 'BGU Asset Recovery Office',
      officeLocation: officeLocation ?? 'Administrative Block, Ground Floor, Room G-04',
      contactMethod: 'Phone & In-Person Desk',
    );
  }
}
