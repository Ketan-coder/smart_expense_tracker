# Financial Workflows: User Guide and Reconciliation Manual

This guide describes how SmartSpend records money and how those records flow
through wallets, reports, loans, goals, recurring payments, SMS imports, and
financial profiles. The in-app version is available from **Settings → Financial
guide**.

## The core distinction

SmartSpend tracks two related but different things:

- **Transactions** explain income received and expenses spent during a date
  range. Their amounts are entered as positive numbers.
- **Wallet balances** represent the current available balance of cash, bank, or
  other accounts. A balance is not income, spending, or a report total.

Payment method (UPI, cash, card, NEFT, and so on) describes how a transaction
moved. The selected wallet/account identifies where the cash movement belongs.
These are not interchangeable.

## Income and expense entry

1. Enter the amount, date, description, categories, and payment method.
2. Select the wallet/account that paid or received the money when known.
3. The app stores the transaction with a positive amount and a classification.
4. A linked, eligible income increases its wallet; a linked, eligible expense
   decreases its wallet. Future-dated transactions and transactions before a
   wallet's balance snapshot do not change the current balance.
5. Reports add only the transaction's reportable amount for the selected
   reporting period.

When editing a linked transaction, the previous wallet effect is reversed and
the updated effect is applied. Deleting a transaction reverses its balance
effect only if that effect had previously been applied. Unassigned entries
remain in transaction history but do not silently create an account or change
a wallet.

## Wallets and bank accounts

A wallet is a cash account with a current balance and an optional balance
snapshot date. Adding an opening/current balance is not a new income
transaction. The app does not infer that the entire wallet balance was spent
when calculating spending.

To reconcile an account:

1. Compare the wallet's current balance with the account's actual available
   balance.
2. Check that the transaction points to the correct wallet, rather than only
   having the right payment method.
3. Check transaction dates against the wallet snapshot date.
4. Review unassigned SMS/manual entries and link only the correct account.

Deleting an account referenced by transactions or recurring payments is
blocked so transaction history does not lose its account reference.

## Reportable amounts and exclusions

Income and expense records retain the original cash movement. Their
`amountForReporting` value controls which portion appears in ordinary
income/expense totals:

- Ordinary income and ordinary expenses report their full amount.
- Loan principal is a cash movement but is excluded from ordinary income and
  expense totals.
- Recognized loan interest is reportable as income or expense according to
  the loan direction.
- Goal allocations do not create synthetic income.

This is why a wallet balance, cash movement, and reportable spending total can
all be different without being contradictory.

## Loans and repayments

Loan records track the direction, principal, outstanding amount, and
repayments. Linked cash transactions update the selected account and the loan
record together. The principal part changes cash and outstanding principal,
but is not counted as ordinary income or expense. Only recognized interest is
included in regular reports.

Do not independently edit or delete a linked loan transaction. Use the loan
workflow so its account movement and outstanding balance remain aligned.

## Savings goals

A goal contribution increases the amount allocated to the goal and its
progress. It is not additional income and does not debit the wallet a second
time. If cash actually moved, record that cash movement as its own
transaction; then record the contribution as goal allocation.

## Recurring payments

A recurring payment has an account assignment. When due, the scheduler creates
a linked expense and deducts the selected account if its balance covers the
payment. A legacy recurring record without a wallet is processed only when
there is exactly one wallet; otherwise it is skipped rather than guessed.

## SMS imports

SMS parsing proposes transactions from message text; it is not a bank feed or
confirmed account mapping. The user should review the parsed direction,
amount, description, and date, and assign the matching wallet when known.

- An unassigned SMS transaction does not change any wallet balance.
- A message with no clear debit/credit direction is ignored.
- A message that appears to indicate both debit and credit is ignored.
- A bank name in message text does not by itself prove which in-app account
  should be updated.

## Reports and date ranges

Reports use positive reportable amounts whose transaction dates fall in the
selected reporting period. Current balances are point-in-time account values
and are not summed into period spending. Future-dated transactions are not
included in the AI financial snapshot's historical totals.

When reconciling a total, verify the selected period, classification, and
reportable amount before comparing it with a current wallet balance.

## Financial profiles and currency

A profile is a separate local ledger, for example **India (INR)** and
**Europe (EUR)**. Each profile has separate transactions, wallets, categories,
loans, goals, and AI conversation data. The default profile retains existing
data and box names for compatibility.

Currency is the profile's display/entry currency. The app does not convert
transactions, retrieve exchange rates, or combine totals from different
profiles. Profiles are not logins: they are stored on the device and are not
protected by separate passwords or synchronized to another device.

## Troubleshooting checklist

If a total looks wrong, check these in order:

1. Is the correct financial profile active?
2. Is the dashboard/report using the expected date range?
3. Is the amount reportable, or is it excluded loan principal/goal allocation?
4. Is the transaction classified as income, expense, loan, or unassigned?
5. Is the wallet/account correct, and is the transaction on/after its balance
   snapshot date?
6. Is an SMS-imported transaction still unassigned or waiting for review?
7. Are you comparing a period flow (income/spending) with a current stock
   (wallet balance)?

For statements, taxes, lending decisions, or other consequential financial
decisions, verify app totals against the original bank or payment records.
