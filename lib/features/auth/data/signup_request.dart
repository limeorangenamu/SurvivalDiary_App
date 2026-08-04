class SignupRequest {
  const SignupRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    this.birthDate,
    this.gender,
    this.region,
    this.signupInterests = const [],
  });

  final String email;
  final String password;
  final String name;
  final String phone;
  final DateTime? birthDate;
  final String? gender;
  final String? region;
  final List<String> signupInterests;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'birthDate': birthDate?.toIso8601String().split('T').first,
      'gender': gender,
      'region': region,
      'signupInterests': signupInterests,
    };
  }
}
