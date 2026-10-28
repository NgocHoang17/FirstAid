import 'package:flutter/services.dart';
import '../domain/guided_flow.dart';

class GuidedFlowRepository {
  static const _assets = {
    'FA01': 'assets/flows/fa01_demo.json',
    'FA02': 'assets/flows/fa02_demo.json',
    'FA03': 'assets/flows/fa03_demo.json',
  };
  Future<GuidedFlow> load(String categoryCode) async {
    final asset = _assets[categoryCode];
    if (asset == null) throw const FormatException('Unsupported category');
    final flow = GuidedFlow.parse(await rootBundle.loadString(asset));
    if (flow.categoryCode != categoryCode) {
      throw const FormatException('Category mismatch');
    }
    return flow;
  }
}
