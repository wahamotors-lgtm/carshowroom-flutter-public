class JournalEntryModel {
  final String id;
  final int entryNumber;
  final String date;
  final String? time;
  final String description;
  final String debitAccountId;
  final String creditAccountId;
  final double amount;
  final String currency;
  final double? creditAmount;
  final String? creditCurrency;
  final double? exchangeRate;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final String? createdAt;

  JournalEntryModel({
    required this.id,
    required this.entryNumber,
    required this.date,
    this.time,
    required this.description,
    required this.debitAccountId,
    required this.creditAccountId,
    required this.amount,
    this.currency = 'USD',
    this.creditAmount,
    this.creditCurrency,
    this.exchangeRate,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.createdAt,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      entryNumber: json['entry_number'] ?? json['entryNumber'] ?? 0,
      date: json['date'] ?? '',
      time: json['time'],
      description: json['description'] ?? '',
      debitAccountId: json['debit_account_id']?.toString() ?? json['debitAccountId']?.toString() ?? '',
      creditAccountId: json['credit_account_id']?.toString() ?? json['creditAccountId']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      creditAmount: json['credit_amount'] != null ? (json['credit_amount']).toDouble() : null,
      creditCurrency: json['credit_currency'] ?? json['creditCurrency'],
      exchangeRate: json['exchange_rate'] != null ? (json['exchange_rate']).toDouble() : null,
      referenceType: json['reference_type'] ?? json['referenceType'],
      referenceId: json['reference_id']?.toString() ?? json['referenceId']?.toString(),
      notes: json['notes'],
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_number': entryNumber,
      'date': date,
      if (time != null) 'time': time,
      'description': description,
      'debit_account_id': debitAccountId,
      'credit_account_id': creditAccountId,
      'amount': amount,
      'currency': currency,
      if (creditAmount != null) 'credit_amount': creditAmount,
      if (creditCurrency != null) 'credit_currency': creditCurrency,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (referenceType != null) 'reference_type': referenceType,
      if (referenceId != null) 'reference_id': referenceId,
      if (notes != null) 'notes': notes,
    };
  }
}
