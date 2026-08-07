class Transaction {
  final String title;
  final double amount;
  final double balanceAfter;
  final String date;
  final bool isAddition;

  Transaction({
    required this.title,
    required this.amount,
    required this.balanceAfter,
    required this.date,
    required this.isAddition,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'date': date,
      'isAddition': isAddition,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      balanceAfter: (map['balanceAfter'] as num).toDouble(),
      date: map['date'] ?? '',
      isAddition: map['isAddition'] ?? true,
    );
  }
}

class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  double totalDebt;
  double initialDebt;
  List<Transaction> history;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.totalDebt,
    required this.initialDebt,
    required this.history,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'totalDebt': totalDebt,
      'initialDebt': initialDebt,
      'history': history.map((x) => x.toMap()).toList(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'] ?? '',
      totalDebt: (map['totalDebt'] as num).toDouble(),
      initialDebt: (map['initialDebt'] as num).toDouble(),
      history: List<Transaction>.from(
        (map['history'] as List<dynamic>).map((x) => Transaction.fromMap(x as Map<String, dynamic>)),
      ),
    );
  }
}
