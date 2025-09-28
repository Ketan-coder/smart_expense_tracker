// main.dart - Debug version for testing SMS reception
import 'package:flutter/material.dart';

import '../../services/sms_service.dart';

class SmsDebugScreen extends StatefulWidget {
  @override
  _SmsDebugScreenState createState() => _SmsDebugScreenState();
}

class _SmsDebugScreenState extends State<SmsDebugScreen> {
  List<Map<String, dynamic>> allMessages = [];
  List<Map<String, dynamic>> transactions = [];
  bool isListening = false;
  bool permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeDebugMode();
  }

  Future<void> _initializeDebugMode() async {
    print("🚀 Starting SMS debug initialization...");

    try {
      bool hasPermissions = await SmsListener.initialize();

      setState(() {
        permissionsGranted = hasPermissions;
      });

      if (hasPermissions) {
        _startListening();
      } else {
        print("⚠️ Permissions not granted, waiting for user action...");
        _showSnackBar('Please grant SMS permissions', Colors.orange);
      }
    } catch (e) {
      print('❌ Error initializing: $e');
      _showSnackBar('Error initializing SMS listener', Colors.red);
    }
  }

  void _startListening() {
    print("🎧 Starting SMS listener...");

    SmsListener.startListening(_onSmsReceived);

    setState(() {
      isListening = true;
    });

    _showSnackBar('SMS listener started - Send yourself a test SMS!', Colors.green);
    print("✅ SMS listener is now active");
  }

  void _onSmsReceived(String sender, String message, int timestamp) {
    print("📨 === NEW SMS RECEIVED ===");
    print("📨 Sender: $sender");
    print("📨 Message: $message");
    print("📨 Timestamp: $timestamp");

    // Add to all messages list (for debugging)
    Map<String, dynamic> rawMessage = {
      'sender': sender,
      'message': message,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
      'rawTimestamp': timestamp,
    };

    setState(() {
      allMessages.insert(0, rawMessage);
    });

    // Try to parse as transaction
    Map<String, dynamic>? transaction = SmsListener.parseTransactionSms(sender, message, timestamp);

    if (transaction != null) {
      print("💰 Transaction detected!");
      setState(() {
        transactions.insert(0, transaction);
      });

      _showSnackBar(
        'Transaction: ${transaction['type']} ₹${transaction['amount']}',
        transaction['type'] == 'credit' ? Colors.green : Colors.red,
      );
    } else {
      print("📝 Regular SMS (not a transaction)");
      _showSnackBar('New SMS from $sender', Colors.blue);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 SMS Debug Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildStatusRow('Permissions', permissionsGranted ? '✅ Granted' : '❌ Denied'),
            _buildStatusRow('Listening', isListening ? '🎧 Active' : '⏸️ Inactive'),
            _buildStatusRow('Total SMS', '📨 ${allMessages.length}'),
            _buildStatusRow('Transactions', '💰 ${transactions.length}'),

            if (!permissionsGranted) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeDebugMode,
                child: Text('🔐 Request Permissions'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SMS Debug Test'),
        backgroundColor: isListening ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          _buildStatusCard(),

          // Tabs for All SMS vs Transactions
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('📨 All SMS (${allMessages.length})'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('💰 Transactions (${transactions.length})'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Messages List
          Expanded(
            child: _buildMessagesList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Test button to simulate SMS (for debugging)
          FloatingActionButton(
            heroTag: "test",
            onPressed: _simulateTestSms,
            child: Icon(Icons.bug_report),
            backgroundColor: Colors.purple,
            mini: true,
          ),
          SizedBox(height: 8),
          // Restart listener button
          FloatingActionButton(
            heroTag: "restart",
            onPressed: permissionsGranted && !isListening ? _startListening : null,
            child: Icon(Icons.refresh),
            backgroundColor: isListening ? Colors.grey : Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (allMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No SMS received yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Send yourself a test SMS to see if it\'s working',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showTestInstructions,
              icon: Icon(Icons.help_outline),
              label: Text('How to Test'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: allMessages.length,
      itemBuilder: (context, index) {
        final message = allMessages[index];
        final isTransaction = transactions.any((t) =>
        t['sender'] == message['sender'] &&
            t['rawTimestamp'] == message['rawTimestamp']);

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTransaction ? Colors.green : Colors.blue,
              child: Icon(
                isTransaction ? Icons.attach_money : Icons.message,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              message['sender'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['message'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  _formatDateTime(message['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isTransaction)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TRANSACTION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(height: 4),
                Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showMessageDetails(message, isTransaction),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showMessageDetails(Map<String, dynamic> message, bool isTransaction) {
    // Find the transaction if it exists
    Map<String, dynamic>? transaction;
    if (isTransaction) {
      transaction = transactions.firstWhere(
            (t) => t['sender'] == message['sender'] &&
            t['rawTimestamp'] == message['rawTimestamp'],
        orElse: () => <String, dynamic>{},
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTransaction ? '💰 Transaction Details' : '📨 SMS Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Sender', message['sender']),
              _buildDetailRow('Time', _formatDateTime(message['timestamp'])),

              if (isTransaction && transaction!.isNotEmpty) ...[
                Divider(),
                _buildDetailRow('Type', transaction['type'].toString().toUpperCase()),
                _buildDetailRow('Amount', '₹${transaction['amount']}'),
                _buildDetailRow('Bank/Service', transaction['bankName']),
                Divider(),
              ],

              SizedBox(height: 16),
              Text(
                'Original Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message['message'],
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _simulateTestSms() {
    // Simulate a test SMS for debugging
    _onSmsReceived(
      'TEST-BANK',
      'Your account has been debited by Rs. 500.00 on 28-Sep-25. Available balance: Rs. 10,000.00',
      DateTime.now().millisecondsSinceEpoch,
    );

    _showSnackBar('Test SMS simulated!', Colors.purple);
  }

  void _showTestInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔧 How to Test SMS Reception'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Make sure permissions are granted ✅',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text('2. Send yourself an SMS from another phone'),
              SizedBox(height: 8),
              Text('3. Or ask someone to send you a message'),
              SizedBox(height: 8),
              Text('4. Try a bank-style message like:'),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Your account debited Rs. 100 on 28-Sep-25',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Debug Steps:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text('• Check Android logs with: adb logcat | grep SmsReceiver'),
              Text('• Purple button simulates a test SMS'),
              Text('• All received SMS will appear in the list'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SmsListener.stopListening();
    super.dispose();
  }
}