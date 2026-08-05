class SignupRequest {
  const SignupRequest({
    required this.email,
    required this.password,
    required this.nickname,
    required this.phone,
    this.birthDate,
    this.gender,
    this.region,
    this.signupInterests = const [],
  });

  final String email;
  final String password;
  final String nickname;
  final String phone;
  final DateTime? birthDate;
  final String? gender;
  final String? region;
  final List<String> signupInterests;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nickname': nickname,
      'phone': phone,
      'birthDate': birthDate?.toIso8601String().split('T').first,
      'gender': gender,
      'region': region,
      'signupInterests': signupInterests,
    };
  }
}
