class Address {
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  Address({
    this.address = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = '',
  });

  factory Address.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Address();
    return Address(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      postalCode,
      country,
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class Company {
  final String department;
  final String name;
  final String title;

  Company({this.department = '', this.name = '', this.title = ''});

  factory Company.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Company();
    return Company(
      department: json['department'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
    );
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String phone;
  final int age;
  final String birthDate;
  final String role;
  final String accessToken;
  final String refreshToken;
  final Address address;
  final Company company;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    this.phone = '',
    this.age = 0,
    this.birthDate = '',
    this.role = '',
    this.accessToken = '',
    this.refreshToken = '',
    Address? address,
    Company? company,
  }) : address = address ?? Address(),
       company = company ?? Company();

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      image: json['image'] ?? '', 
      phone: json['phone'] ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      birthDate: json['birthDate'] ?? '',
      role: json['role'] ?? '',
      accessToken: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      address: Address.fromJson(json['address']),
      company: Company.fromJson(json['company']),
    );
  }
}