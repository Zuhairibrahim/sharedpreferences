import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/customer_model.dart';
import '../ads/ad_helper.dart';
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
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
          if (mounted) setState(() => _bannerLoaded = false);
        },
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
                child: PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop) Navigator.pop(context, true);
                  },
                  child: TabBarView(
                    children: [
                      CustomerOperationsScreen(customer: widget.customer, allCustomers: widget.allCustomers),
                      CustomerFullHistoryScreen(customer: widget.customer),
                    ],
                  ),
                ),
              ),
              if (_bannerLoaded && _bannerAd != null)
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