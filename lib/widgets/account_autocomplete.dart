import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../data/database.dart';

class AccountAutocomplete extends ConsumerStatefulWidget {
  final String? initialValue;
  final ValueChanged<Account?> onAccountSelected;
  final String? labelText;
  final String? hintText;

  const AccountAutocomplete({
    super.key,
    this.initialValue,
    required this.onAccountSelected,
    this.labelText,
    this.hintText,
  });

  @override
  ConsumerState<AccountAutocomplete> createState() => _AccountAutocompleteState();
}

class _AccountAutocompleteState extends ConsumerState<AccountAutocomplete> {
  late TextEditingController _controller;
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    
    return accountsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Error: $error'),
      data: (accounts) {
        return Autocomplete<Account>(
          displayStringForOption: (Account option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return accounts.take(10); // Show first 10 accounts when empty
            }
            
            final filteredAccounts = accounts.where((Account account) {
              return account.name
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            }).toList();
            
            // Sort by relevance (starts with query first)
            filteredAccounts.sort((a, b) {
              final aStartsWith = a.name.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
              final bStartsWith = b.name.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
              
              if (aStartsWith && !bStartsWith) return -1;
              if (!aStartsWith && bStartsWith) return 1;
              
              return a.name.compareTo(b.name);
            });
            
            return filteredAccounts.take(20); // Limit to 20 results
          },
          onSelected: (Account selection) {
            setState(() {
              _selectedAccount = selection;
              _controller.text = selection.name;
            });
            widget.onAccountSelected(selection);
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Sync with our controller
            if (textEditingController.text != _controller.text) {
              textEditingController.text = _controller.text;
            }
            
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.labelText ?? 'Select Account',
                hintText: widget.hintText ?? 'Start typing to search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _selectedAccount != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedAccount = null;
                            textEditingController.clear();
                            _controller.clear();
                          });
                          widget.onAccountSelected(null);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _controller.text = value;
                // Clear selection if text doesn't match
                if (_selectedAccount != null && _selectedAccount!.name != value) {
                  setState(() {
                    _selectedAccount = null;
                  });
                  widget.onAccountSelected(null);
                }
              },
              onSubmitted: (value) {
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<Account> onSelected,
            Iterable<Account> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Account option = options.elementAt(index);
                      return Consumer(
                        builder: (context, ref, child) {
                          // Get account group info
                          final groupAsync = ref.watch(accountGroupProvider(option.groupId));
                          
                          return groupAsync.when(
                            loading: () => ListTile(
                              title: Text(option.name),
                              subtitle: const Text('Loading...'),
                              onTap: () => onSelected(option),
                            ),
                            error: (error, stackTrace) => ListTile(
                              title: Text(option.name),
                              subtitle: const Text('Error loading group'),
                              onTap: () => onSelected(option),
                            ),
                            data: (group) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getGroupColor(group.name).withOpacity(0.1),
                                child: Icon(
                                  _getGroupIcon(group.name),
                                  color: _getGroupColor(group.name),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                option.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                group.name,
                                style: TextStyle(
                                  color: _getGroupColor(group.name),
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => onSelected(option),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getGroupColor(String groupName) {
    switch (groupName) {
      case 'Assets':
        return Colors.green;
      case 'Liabilities':
        return Colors.red;
      case 'Equity':
        return Colors.blue;
      case 'Revenue':
        return Colors.purple;
      case 'Expenses':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getGroupIcon(String groupName) {
    switch (groupName) {
      case 'Assets':
        return Icons.account_balance_wallet;
      case 'Liabilities':
        return Icons.credit_card;
      case 'Equity':
        return Icons.person;
      case 'Revenue':
        return Icons.trending_up;
      case 'Expenses':
        return Icons.trending_down;
      default:
        return Icons.account_balance;
    }
  }
}
