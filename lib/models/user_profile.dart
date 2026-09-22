enum UserRole {
  user,
  student, // preserved for backward compatibility
  admin;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'USER';
      case UserRole.student:
        return 'USER';
      case UserRole.admin:
        return 'ADMINISTRATOR';
    }
  }

  bool get isUser => this == UserRole.user || this == UserRole.student;
  bool get isStudent => this == UserRole.student || this == UserRole.user;
  bool get isAdmin => this == UserRole.admin;
}

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final String city;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional affiliation fields
  final String college;
  final String studentId;
  final String department;
  final bool sharePhone;
  final bool shareEmail;
  final bool shareStudentId;

  // Admin-specific fields
  final String designation;
  final String office;
  final String officeLocation;
  final String contactMethod;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.role = UserRole.user,
    this.profileImage,
    this.city = 'Bhubaneswar',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.college = '',
    this.studentId = '',
    this.department = '',
    this.sharePhone = true,
    this.shareEmail = true,
    this.shareStudentId = false,
    this.designation = 'Campus Property & Recovery Officer',
    this.office = 'Asset Recovery Office',
    this.officeLocation = 'Room G-04',
    this.contactMethod = 'Phone & Message',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isUser => role.isUser;
  bool get isStudent => role.isStudent;
  bool get isAdmin => role.isAdmin;

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? profileImage,
    String? city,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? college,
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
      profileImage: profileImage ?? this.profileImage,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      college: college ?? this.college,
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
      'profileImage': profileImage,
      'city': city,
      'isActive': isActive,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (college.isNotEmpty) 'college': college,
      if (studentId.isNotEmpty) 'studentId': studentId,
      if (department.isNotEmpty) 'department': department,
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
    final roleStr = json['role'] as String? ?? 'user';
    final parsedRole = roleStr == 'admin' ? UserRole.admin : UserRole.user;

    return UserProfile(
      userId: json['userId'] as String? ?? 'user_default',
      name: json['name'] as String? ?? 'Traceback User',
      email: json['email'] as String? ?? 'user@example.com',
      phone: json['phone'] as String? ?? '9876543210',
      role: parsedRole,
      profileImage: json['profileImage'] as String?,
      city: json['city'] as String? ?? 'Bhubaneswar',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now() : DateTime.now(),
      college: json['college'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      department: json['department'] as String? ?? '',
      sharePhone: json['sharePhone'] as bool? ?? true,
      shareEmail: json['shareEmail'] as bool? ?? true,
      shareStudentId: json['shareStudentId'] as bool? ?? false,
      designation: json['designation'] as String? ?? 'Property & Recovery Officer',
      office: json['office'] as String? ?? 'Asset Recovery Office',
      officeLocation: json['officeLocation'] as String? ?? 'Room G-04',
      contactMethod: json['contactMethod'] as String? ?? 'Phone & Message',
    );
  }

  static UserProfile defaultStudent({String? name, String? email, String? phone, String? studentId}) {
    return UserProfile(
      userId: 'student_current',
      name: name ?? 'Subhadeep',
      email: email ?? 'subhadeep@bgu.ac.in',
      phone: phone ?? '9876543210',
      role: UserRole.student,
      city: 'Bhubaneswar',
      studentId: studentId ?? 'BGU-2024-BTECH-042',
      sharePhone: true,
      shareEmail: true,
    );
  }

  static UserProfile defaultAdmin({
    String? name,
    String? email,
    String? phone,
    String? officeLocation,
  }) {
    return UserProfile(
      userId: 'admin_01',
      name: name ?? 'Traceback Admin Desk',
      email: email ?? 'admin@traceback.app',
      phone: phone ?? '9876543210',
      role: UserRole.admin,
      city: 'Bhubaneswar',
      designation: 'Central Property & Recovery Officer',
      office: 'Asset Recovery Office',
      officeLocation: officeLocation ?? 'Room G-04',
      contactMethod: 'Phone & Message',
    );
  }
}
