# Local Financial Profiles

## Overview

The app supports multiple independent financial profiles on one device. A profile represents a separate local ledger, such as **India (INR)** and **Europe (EUR)**. This is not an authentication system: profiles do not have passwords, remote identities, cloud synchronization, or shared access across devices.

## How it works

1. The profile registry and active profile ID are stored in `SharedPreferences`.
2. Each financial profile has its own Hive boxes. The default profile retains the legacy `expenses` box name; a second profile uses names such as `expenses__profile_p...`. The same naming scheme applies to incomes, wallets, categories, goals, habits, recurring records, loans, and daily progress.
3. `AppConstants` resolves a financial box name through `ProfileScope.activeProfileId`. Startup restores the selected profile, opens its boxes, then builds the app. Switching profiles opens that profile's boxes and rebuilds navigation.
4. A profile owns a currency code and symbol. The currency is presentation metadata; the app does **not** convert transaction amounts, synchronize exchange rates, or combine profiles into a cross-currency total.
5. AI reads the selected profile's ledger, wallet balances, and currency for each request. AI Overview cache entries are scoped by profile and a fingerprint of that profile's wallet and transaction data.
6. AI chat history, conversation summaries, and saved memories are stored under profile-specific preference keys. The default profile retains the existing keys so its data remains available. Other device-level preferences such as language and theme remain shared.

## Data migration and safety

- The `default` profile continues using the existing unscoped Hive box names. This keeps every existing record and key in place, avoiding a copy of Hive objects and preserving category, goal, loan, and transaction references.
- Newly created profiles use suffixed boxes, such as `expenses__profile_p...`; no existing box is renamed, cleared, or duplicated.
- First startup performs an in-place compatibility migration on default-profile transactions: legacy wallet links and loan/goal classifications are recorded in the newly optional fields.
- Legacy income and expense records are linked to a wallet only when their old method matches a wallet type. Where several old wallets match, migration preserves the old first-match behavior; all new transaction entry points use an explicit wallet key.
- The default profile's existing wallet balances are retained and marked with a balance snapshot date. New dated transactions change the current balance only when they are on or after that snapshot and are not future-dated. This avoids replaying old imports against a balance that already includes them.
- The migration is non-destructive and records completion in preferences. It updates legacy transaction metadata in place but does not delete existing records.
- Do not clear app storage while testing migration on a device. The migration and profile switch should be tested with the existing default profile intact.

## Accounting choices implemented

- Income and expense records keep positive transaction amounts. A stable `walletKey` identifies the cash account; `method` remains payment-rail/detail text and is not used as the account identity for new UI operations.
- Recurring payments store a wallet key and generate linked expenses on that account. Legacy recurring records without an account are assigned only when there is exactly one wallet; otherwise the scheduler skips them until an account is selected.
- Transaction writes adjust the selected wallet and store whether the balance effect was applied. Edits reverse the old account effect and apply the new one; deletes reverse only an effect that was previously applied.
- Unassigned SMS imports preserve the parsed transaction date and do not mutate any wallet. The parser ignores messages whose direction is absent or simultaneously appears debit and credit.
- Loan principal remains a cash movement but is excluded from regular income/expense reporting. Interest received on a lent-loan repayment and interest paid on a borrowed-loan payment are reportable; principal is not.
- Goal contributions only increase goal allocation/progress. They do not create synthetic income or change a wallet balance.
- Deleting a wallet referenced by transactions or recurring payments is blocked. A loan with linked cash transactions cannot be deleted, and loan-linked transactions cannot be deleted or have their amount, date, account, or method changed independently. The loan's principal, direction, or payment method is likewise locked once cash transactions are linked.

## Current boundaries and future work

- Profiles are local partitions, not separate device logins. Anyone with access to the app/device can switch between them.
- No cross-profile transfer or currency conversion is offered. To model a currency-exchange transaction, record it separately in each profile or add a dedicated transfer/exchange model later.
- SMS bank names are not treated as confirmed account mappings. Imported records remain unassigned until the user can review and assign an account.
- AI explicitly labels current wallet balance separately from reportable spending; a balance is never treated as an expense. Its financial snapshot uses the active profile currency and excludes future-dated transactions from historical totals.
- Profile currencies are separate, but language, theme, notification, and several other preferences are still device-wide.
- Hive writes across transaction, wallet, and related loan boxes cannot provide a true database transaction. The central income/expense helpers roll back the primary ledger and balance writes on failure; failure injection and full reconciliation tests remain desirable.
