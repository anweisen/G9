import 'package:flutter/material.dart';

import '../api/kmapi.dart';

class KmApiProvider extends ChangeNotifier {

  AbiDates? _abiDates;
  bool _loadingFailed = false;
  bool _loading = false;

  AbiDates? get abiDates => _abiDates;
  bool get isLoading => _abiDates == null && !_loadingFailed;
  bool get hasError => _loadingFailed;

  void fetchDataIfNotPresent(int predictedYear) async {
    if (_loading) return;
    if (_loadingFailed) return;
    if (_abiDates != null) return;
    _loading = true;

    AbiDates? dates = await KmApi.fetchAbiDates(predictedYear);

    if (dates != null) {
      _abiDates = dates;
    } else {
      _loadingFailed = true;
    }

    _loading = false;
    notifyListeners();
  }

}
