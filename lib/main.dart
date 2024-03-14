import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class LoanOffer {
  final String bankName;
  final double annualExpenseRate;
  final double interestRate;
  //final double amount;
  //final int maturity;

  LoanOffer({
    required this.bankName,
    required this.annualExpenseRate,
    required this.interestRate,
    //required this.amount,
    //required this.maturity,
  });

  factory LoanOffer.fromJson(Map<String, dynamic> json) {
  return LoanOffer(
    bankName: json['bank'],
    annualExpenseRate: json['annual_rate'],
    interestRate: json['interest_rate'],
    //amount: json['amount'],
    //maturity: json['maturity'],
  );
  }

}

class SearchFormScreen extends StatefulWidget {
  @override
  _SearchFormScreenState createState() => _SearchFormScreenState();
}

class _SearchFormScreenState extends State<SearchFormScreen> {
  double amountValue = 1000.0;
  double maturityValue = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arama Detayları'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kredi Tutarı: ${amountValue.toStringAsFixed(0)}'),
            Slider(
              value: amountValue,
              min: 1000,
              max: 300000,
              divisions: 100,
              label: amountValue.round().toString(),
              onChanged: (value) {
                setState(() {
                  amountValue = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text('Kredi Vadesi: ${maturityValue.toStringAsFixed(0)}'),
            Slider(
              value: maturityValue,
              min: 1,
              max: 36,
              divisions: 36,
              label: maturityValue.round().toString(),
              onChanged: (value) {
                setState(() {
                  maturityValue = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanListingScreen(
                      amount: amountValue.round().toString(),
                      maturity: maturityValue.round().toString(),
                    ),
                  ),
                );
              },
              child: Text('Hesapla'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoanListingScreen extends StatefulWidget {
  final String amount;
  final String maturity;

  const LoanListingScreen({
    required this.amount,
    required this.maturity,
  });

  @override
  _LoanListingScreenState createState() => _LoanListingScreenState();
}

class _LoanListingScreenState extends State<LoanListingScreen> {
  late Future<List<LoanOffer>> _futureLoanOffers;

  @override
  void initState() {
    super.initState();
    _futureLoanOffers = fetchLoanOffers(widget.amount, widget.maturity);
  }

  Future<List<LoanOffer>> fetchLoanOffers(String amount, String maturity) async {
    final response = await http.get(
      Uri.parse('https://api2.teklifimgelsin.com/api/getLoanOffers?kredi_tipi=0&vade=$maturity&tutar=$amount'),
    );

    if (response.statusCode == 200) {
      print(response.body);

      Map<String, dynamic> parsedData = jsonDecode(response.body);
      List<dynamic> activeOffers = parsedData['active_offers'];
      List<LoanOffer> _loanOffers = activeOffers.map((offer) => LoanOffer.fromJson(offer)).toList();
      return _loanOffers;
    } else {
      // Handle error
      throw Exception('Kredi teklifleri yüklenemedi.');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kredi Teklifleri'),
      ),
      body: FutureBuilder<List<LoanOffer>>(
        future: _futureLoanOffers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else {
            List<LoanOffer> _loanOffers = snapshot.data!;
            return ListView.builder(
              itemCount: _loanOffers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_loanOffers[index].bankName),
                  subtitle: Text('Faiz Oranı: ${_loanOffers[index].interestRate.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanDetailScreen(
                          loanOffer: _loanOffers[index],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class LoanDetailScreen extends StatelessWidget {
  final LoanOffer loanOffer;

  const LoanDetailScreen({required this.loanOffer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kredi Detayları'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Banka Adı: ${loanOffer.bankName}'),
            SizedBox(height: 10),
            Text('Yıllık Maliyet Oranı: ${loanOffer.annualExpenseRate.toStringAsFixed(2)}'),
            SizedBox(height: 10),
            Text('Faiz Oranı: ${loanOffer.interestRate.toStringAsFixed(2)}'),
            SizedBox(height: 10),
            //Text('Kredi Tutarı: ${loanOffer.amount}'),
            SizedBox(height: 10),
            //Text('Kredi Vadesi: ${loanOffer.maturity}'),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kredi Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SearchFormScreen(),
      debugShowCheckedModeBanner: false, 
    );
  }
}
