import 'package:flutter/material.dart';

import '../api/kmapi.dart';

class KmApiProvider extends ChangeNotifier {

  AbiDates? _abiDates;
  bool loadingFailed = false;

  AbiDates? get abiDates => _abiDates;
  bool get isLoading => _abiDates == null && !loadingFailed;
  bool get hasError => loadingFailed;

  KmApiProvider() {
    fetchData();
  }

  void fetchData() async {
    AbiDates? dates = await KmApi.fetchAbiDates();
    if (dates != null) {
      _abiDates = dates;
    } else {
      loadingFailed = true;
    }
    notifyListeners();
  }

}
