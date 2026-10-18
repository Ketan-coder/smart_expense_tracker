# Financial Logic Review

**Reviewed:** 2026-10-11  
**Scope:** Income and expense creation/edit/deletion, wallet balances, bank/SMS handling, reports, goals, and loan-linked transactions. This is a static review of the current source; no live account data or runtime reconciliation was available.

## Implementation follow-up

The urgent accounting and profile-isolation changes from this review have since been implemented. Transactions now reference explicit wallet keys, dated wallet effects track whether they were applied, loan principal is excluded from ordinary income/expense reporting, goal allocations no longer create income, and SMS imports preserve dates while remaining unassigned unless an account is explicitly selected. Multiple local financial profiles now have separate Hive ledgers and currency metadata; see [MULTI_PROFILE_ARCHITECTURE.md](./MULTI_PROFILE_ARCHITECTURE.md) for migration and design decisions.

Residual boundaries: SMS sender-to-bank mapping and transaction review UI are not implemented; future-dated transactions are retained but do not automatically affect balances when their date arrives; profile-specific preferences beyond currency and quick actions remain device-wide; and cross-box Hive writes are not fully transactional. Linked loans intentionally block deletion and changes to principal, direction, and payment method so their cash ledger cannot silently diverge.

## Executive summary

The basic arithmetic is directionally correct when a transaction is tied to exactly one wallet: income adds to a balance, an expense subtracts from it, deleting either reverses that change, and net cash flow is income minus expenses.

The main correctness problem is the relationship between a transaction and an account. Transactions store a free-text `method`, while wallets store a `type`; transaction code often matches those strings and selects the first matching wallet. Neither model stores a stable wallet/account ID. As a result, payment rail names, wallet types, and actual bank accounts are conflated. This can produce phantom wallets, update the wrong account, and make balances and reports disagree.

**Bottom line:** Do not treat the current wallet total or income/expense reports as reconciled account balances or reliable profit/savings figures. Fix transaction-to-account identity and the misclassified loan/goal flows before relying on those figures.

## What is correct today

| Area | Assessment | Evidence |
|---|---|---|
| Transaction amount convention | Income and expense models both store positive amounts; the transaction kind determines whether the amount is added or subtracted. This is a sound convention if consistently enforced. | [income.dart](../lib/data/model/income.dart#L20), [expense.dart](../lib/data/model/expense.dart#L20) |
| Basic create/delete arithmetic | Income creation adds to a matched wallet; expense creation subtracts. Expense deletion adds the amount back, and income deletion subtracts it. These inverse operations are correct **only if** the same intended wallet is resolved each time. | [universal_functions.dart](../lib/data/local/universal_functions.dart#L343), [universal_functions.dart](../lib/data/local/universal_functions.dart#L616), [universal_functions.dart](../lib/data/local/universal_functions.dart#L701), [universal_functions.dart](../lib/data/local/universal_functions.dart#L940) |
| Period net calculation | Home/report net is calculated as period income minus period expenses, a valid cash-flow calculation for the records currently classified as income and expense. | [home_page.dart](../lib/screens/home/home_page.dart#L274), [home_page.dart](../lib/screens/home/home_page.dart#L670), [reports_page.dart](../lib/screens/reports/reports_page.dart#L403) |
| Category separation | Category records have a transaction type, and the add forms show income categories for income and expense categories for expenses. This is a useful validation/presentation boundary. | [category.dart](../lib/data/model/category.dart#L1), [bottom_nav_bar.dart](../lib/screens/widgets/bottom_nav_bar.dart#L2856), [bottom_nav_bar.dart](../lib/screens/widgets/bottom_nav_bar.dart#L2992) |
| Loans retain links to generated transactions | Loan helpers store transaction keys on the loan and update wallet balances in the cash-flow direction. This is a good starting point for traceability, though the accounting classification and account links need work. | [loan.dart](../lib/data/model/loan.dart#L79), [loan_helpers.dart](../lib/services/loan_helpers.dart#L106), [loan_helpers.dart](../lib/services/loan_helpers.dart#L234) |

## Needs refinement

| Priority | Finding | Why it matters | Recommended refinement |
|---|---|---|---|
| High | `method` is used as if it identifies a wallet. Expense/income records have a nullable string `method`; a wallet has a separate `name`, `balance`, and `type`. The transaction helpers match `method` to `wallet.type`, not to a specific wallet. | `UPI`, `NEFT`, `IMPS`, `Cash`, `Card`, and `Bank` describe different kinds of payment details; they do not uniquely identify an account. A bank can have multiple accounts of the same type. | Store a stable `walletId`/wallet Hive key on each transaction. Keep payment method/rail as a separate optional field. Resolve and display the account by ID, never by a type string or list order. |
| High | Wallet opening/current balance semantics are undefined. Wallet balances are edited directly, while dated transactions immediately mutate the current balance regardless of transaction date. | Adding an old SMS/imported transaction after entering today's bank balance can apply the historic movement a second time. Changing a transaction date also does not recalculate/reconcile the balance. | Choose one source of truth: preferably an opening balance plus dated ledger entries, with balances derived by replaying entries; alternatively, define a balance snapshot timestamp and only apply later transactions to that snapshot. Make backdated imports/reconciliation explicit. |
| High | Bank is not a distinct account model. A wallet can have type `bank`, but the transaction has no bank/account reference. SMS parsing extracts a bank name, then the receiver only uses it in the description; the stored method is extracted separately. | A “Bank” wallet type cannot distinguish SBI from HDFC or two accounts at the same bank. Sender identity does not select an account. | Treat each bank account as its own wallet/account record with a stable ID and optional institution metadata. Provide a confirmed account mapping for SMS sender/account suffix; do not guess an account from a generic payment method. |
| Medium | The supported payment-method list and wallet types do not describe the same domain. The UI offers `UPI`, `Cash`, `NEFT`, `IMPS`, `RTGS`, `Card`, and `Online`; wallets use types such as `cash`, `bank`, `card`, `upi`, `credit`, and `other`. | Some entries happen to match a wallet type (`Cash`, `UPI`, `Card`), while others do not (`NEFT`, `IMPS`, `Online`). Unmatched values currently create wallets named after the method. | Separate payment method from account selection in the UI and make account selection explicit. Do not create an account implicitly just because a payment-method label is new. |
| Medium | Deleting a wallet is allowed without checking for transactions that refer to it. | Once transactions are tied to an account, deleting that account can orphan history. Even with today's method-based matching, removal can make reversals impossible or cause later transactions to resolve to a different same-type wallet. | Block deletion while referenced, or require an explicit archive/migrate action. Prefer archival so historical transactions remain understandable. |
| Medium | Error/rollback behavior is weaker than the “atomic” operation names imply. Cross-box Hive writes are not a single transaction; add rollback does not remove a newly created wallet, and update rollback uses an original balance of `0` as a proxy for “new wallet,” which can delete a pre-existing zero-balance wallet. | A failure at the wrong point can leave a transaction and balance inconsistent, or delete a legitimate account. | Track whether a wallet was newly created separately from its balance, retain its actual key, and make rollback restore/delete by that key. Add failure-path tests. |
| Medium | The reports call all recorded inflows “income” and outflows “expense,” and calculate “net savings” from those totals. Some loan/goal flows are included in these transaction boxes. | Cash movement is not always earned income or consumption. The current report labels can therefore suggest improved income/savings when a loan is received, or higher spending when principal is repaid. | Define separate cash-flow and income/expense (P&L) views. Label the existing arithmetic as net cash flow unless/until financing, transfers, refunds, and savings allocations have distinct types and report rules. |
| Medium | Recurring records are summed separately from transaction expenses. | The recurring total is a schedule/commitment amount, not necessarily cash already spent; mixing it into actual expense totals would double-count once an actual transaction is recorded. | Keep scheduled recurring obligations as forecasts. Add actual expense ledger entries only when a payment occurs; present forecast and actual in separate totals. |

## Wrong and needs immediate refinement

These can directly make balances, account attribution, or financial summaries incorrect.

### 1. Editing income can debit the wrong wallet

`updateIncome` receives the newly selected method, finds that wallet, subtracts the **old income amount** from it, and adds the new amount. It never resolves the old income's original method/account. If the user changes the source, the original wallet keeps the old credit and the new wallet is reduced by the old amount before receiving the new amount. For example, editing a 100 income from Cash to Bank for 120 leaves Cash overstated by 100 and increases Bank by only 20.

**Immediate fix:** resolve both old and new account IDs; reverse the old transaction against the old account and apply the new transaction to the new account, in one recoverable operation. Until fixed, changing the source of an existing income is unsafe.  
Evidence: [updateIncome](../lib/data/local/universal_functions.dart#L832), [income edit flow](../lib/screens/home/income_listing_page.dart#L802), [income edit save](../lib/screens/home/income_listing_page.dart#L896).

### 2. Bank identity and payment method are conflated

The SMS parser returns a bank name and a method, but the receiver discards the parsed date and does not pass the bank name/account identity into the income/expense model. The generic method is then used to find the first wallet with a matching type, or to create a new wallet. A parsed `BANK`, `NEFT`, `IMPS`, `CREDIT CARD`, or `OTHER` value is not a reliable reference to a particular account.

**Immediate fix:** do not silently mutate a guessed account. Persist an explicit account ID only after a configured mapping or user confirmation. Until then, keep the transaction unassigned/review-required and do not claim that a specific bank balance was updated.  
Evidence: [parseTransactionSms](../lib/services/sms_service.dart#L331), [SMS transaction receiver](../lib/screens/widgets/bottom_nav_bar.dart#L1523), [addExpense wallet lookup](../lib/data/local/universal_functions.dart#L343), [addIncome wallet lookup](../lib/data/local/universal_functions.dart#L701), [Wallet model](../lib/data/model/wallet.dart#L1).

### 3. Loan principal and repayments are categorized as ordinary income/expense

Borrowing creates an `Income`; lending creates an `Expense`. Later, receiving a lent principal repayment creates another `Income`, while repaying a borrowed loan creates an `Expense`. The regular reports sum these boxes as income and expense. Principal received/paid is financing movement, not earned income/consumption, so it distorts the report's income, spending, savings-rate, and category figures. The payment helper also records the full loan payment as one transaction even though it calculates a principal/interest split.

**Immediate fix:** represent loan principal drawdown/repayment as financing events (or typed transactions) and exclude principal from earned-income/consumption reports. Record interest separately as income/expense. Keep the full cash movement in account balances.  
Evidence: [loan creation transaction logic](../lib/services/loan_helpers.dart#L106), [loan payment split and transaction logic](../lib/services/loan_helpers.dart#L234), [report totals](../lib/screens/reports/reports_page.dart#L403).

### 4. A goal installment is recorded as income and increases wallet balance

`GoalService.addInstallment` increases the goal's progress, then calls `addIncome` for the installment amount. That credits the selected wallet and adds the amount to reported income. A contribution of existing money to a savings goal should not create new money or income; it should either earmark funds without changing account balance, or transfer funds between accounts when an actual account movement occurs.

**Immediate fix:** remove the synthetic income entry. Model a goal contribution as an allocation/transfer, and only change account balances for a real source-to-destination movement.  
Evidence: [goal installment logic](../lib/services/goal_service.dart#L55), [GoalService.addIncome call](../lib/services/goal_service.dart#L70).

### 5. SMS classification can turn ambiguous messages into expenses

The parser checks debit keywords before credit keywords, so a message containing both is classified as a debit. If neither is detected, it explicitly defaults an unknown transaction to debit. A refund/credit message with ambiguous wording can therefore become an expense and subtract from a wallet. The receiver then saves it without asking the user to confirm the direction.

**Immediate fix:** return an unknown/review state when direction is not unambiguous; do not create or mutate a wallet for it. Add fixtures for mixed debit/credit wording and bank-specific templates.  
Evidence: [SMS direction classification](../lib/services/sms_service.dart#L176), [parser debit-first/default behavior](../lib/services/sms_service.dart#L331), [SMS receiver](../lib/screens/widgets/bottom_nav_bar.dart#L1535).

## Additional correctness gaps to address

- **SMS date is parsed but not persisted.** `parseTransactionSms` returns a timestamp, but the receiver calls `addExpense`/`addIncome` without the optional `date`; those helpers default to `DateTime.now()`. Historical messages consequently appear as new transactions and cannot be reliably reconciled by date. Pass the parsed date through, after defining how backdated entries affect balances. See [SMS parser](../lib/services/sms_service.dart#L331) and [SMS receiver](../lib/screens/widgets/bottom_nav_bar.dart#L1523).
- **Income edit UI reports success without awaiting the operation.** The income listing invokes `updateIncome` without awaiting its result, then closes the form and shows a success message. Failures such as a missing record or invalid data can be hidden. Expense listing uses a similar non-awaited update call. Await the result and only show success when it is true. See [income edit save](../lib/screens/home/income_listing_page.dart#L896) and [expense edit save](../lib/screens/expenses/expense_listing_page.dart#L911).
- **Legacy/null methods are unsafe for income deletion.** `deleteIncome` rejects an empty method, and some loan-generated income records omit `method`; the income-list delete callback passes an empty string for those records. A transaction may therefore be undeletable through that path. Account references should be optional but deletion/reversal must be driven by the stored transaction and stable account ID, not a caller-supplied method. See [loan income creation](../lib/services/loan_helpers.dart#L123), [deleteIncome](../lib/data/local/universal_functions.dart#L940), and [income delete callback](../lib/screens/home/income_listing_page.dart#L720).

## Recommended order of work

1. **Stop incorrect account mutation:** add a stable account/wallet reference to transaction records and make the UI select an actual account separately from payment method. For imported SMS, require a known mapping or leave the account unresolved.
2. **Correct income update/delete invariants:** reverse against the transaction's original account, apply against the selected account, persist transaction changes, and report the actual operation result to the UI.
3. **Separate transaction kinds:** distinguish earned income, ordinary expense, loan principal drawdown/repayment, interest, refund, and transfer/goal allocation. Specify which kinds contribute to cash balance, income, spending, and savings-rate totals.
4. **Repair SMS ingestion:** preserve the parsed timestamp; do not default ambiguous direction to debit; require review for unknown direction/account; avoid applying a historical movement to a present-day balance without a defined opening-balance policy.
5. **Harden balance and account lifecycle:** clarify opening-balance semantics, protect referenced accounts from deletion, and fix rollback identity tracking.
6. **Add tests around invariants:** same-account and cross-account edits; add/edit/delete reversal; zero-opening-balance rollback; multiple bank accounts with the same type; SMS date/direction/account mapping; loan principal versus interest; and goal allocation not inventing income or increasing total assets.

## Accounting invariants to preserve

- Transaction amounts are finite and positive; transaction kind controls the sign.
- Every balance-affecting transaction changes exactly one identified account, or explicitly identifies both sides for a transfer.
- Editing a transaction is equivalent to reversing its old effect and applying its new effect.
- Deleting a transaction reverses only its recorded effect on its recorded account.
- Transfers and goal earmarks do not create income or expenses; an actual transfer changes account balances but not total assets.
- Loan principal changes cash and liability/receivable balances; only interest belongs in income/expense totals.
- Reports must state whether a figure is actual cash flow, earned income/consumption, forecast, or net worth; do not present these as interchangeable.
