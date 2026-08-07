import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/customer_model.dart';
import 'customer_operations_screen.dart';
import 'customer_history_screen.dart';

class CustomerDetailTabs extends StatefulWidget {
  final Customer customer;
  final List<Customer> allCustomers;

  const CustomerDetailTabs({super.key, required this.customer, required this.allCustomers});

  @override
  State<CustomerDetailTabs> createState() => _CustomerDetailTabsState();
}

class _CustomerDetailTabsState extends State<CustomerDetailTabs> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-1396394529471927/1800738227',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.customer.fullName),
            centerTitle: true,
            backgroundColor: const Color(0xff121212),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.white,
              tabs: [Tab(text: 'الحساب والعمليات'), Tab(text: 'سجل العمليات الكامل')],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: WillPopScope(
                  onWillPop: () async {
                    Navigator.pop(context, true);
                    return false;
                  },
                  child: TabBarView(
                    children: [
                      CustomerOperationsScreen(customer: widget.customer, allCustomers: widget.allCustomers),
                      CustomerFullHistoryScreen(customer: widget.customer),
                    ],
                  ),
                ),
              ),
              if (_bannerAd != null)
                SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}