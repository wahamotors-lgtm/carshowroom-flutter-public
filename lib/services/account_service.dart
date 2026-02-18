import '../config/api_config.dart';
import '../models/account_model.dart';
import '../models/journal_entry_model.dart';
import 'api_service.dart';

class AccountService {
  final ApiService _api;

  AccountService(this._api);

  // ── Accounts ──

  Future<List<AccountModel>> getAccounts(String token) async {
    final data = await _api.getList(ApiConfig.accounts, token: token);
    return data
        .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createAccount(
    String token,
    Map<String, dynamic> body,
  ) async {
    return await _api.post(ApiConfig.accounts, body, token: token);
  }

  Future<Map<String, dynamic>> updateAccount(
    String token,
    String accountId,
    Map<String, dynamic> body,
  ) async {
    return await _api.put(
      '${ApiConfig.accounts}/$accountId',
      body,
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteAccount(
    String token,
    String accountId,
  ) async {
    return await _api.delete(
      '${ApiConfig.accounts}/$accountId',
      token: token,
    );
  }

  // ── Account Types ──

  Future<List<AccountTypeModel>> getAccountTypes(String token) async {
    final data = await _api.getList(ApiConfig.accountTypes, token: token);
    return data
        .map((e) => AccountTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Journal Entries ──

  Future<List<JournalEntryModel>> getJournalEntries(String token) async {
    final data = await _api.getList(ApiConfig.journalEntries, token: token);
    return data
        .map((e) => JournalEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getNextEntryNumber(String token) async {
    final data = await _api.get(ApiConfig.nextEntryNumber, token: token);
    return data['entryNumber'] ?? data['entry_number'] ?? 1;
  }

  Future<Map<String, dynamic>> createJournalEntry(
    String token,
    Map<String, dynamic> body,
  ) async {
    return await _api.post(ApiConfig.journalEntries, body, token: token);
  }

  Future<Map<String, dynamic>> deleteJournalEntry(
    String token,
    String entryId,
  ) async {
    return await _api.delete(
      '${ApiConfig.journalEntries}/$entryId',
      token: token,
    );
  }
}
