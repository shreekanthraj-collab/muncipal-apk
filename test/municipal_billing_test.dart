import 'package:flutter_test/flutter_test.dart';
import 'package:orb_valve_app/models/municipal_billing.dart';

void main() {
  test('parses municipal billing summary from server response', () {
    final summary = MunicipalBillingSummary.fromJson({
      'period_start': '2026-10-01',
      'period_end': '2026-10-31',
      'currency': 'INR',
      'valve_count': 1,
      'total_operating_cost_inr': 125.50,
      'usd_to_inr_rate': 90,
      'valves': [
        {
          'valve_id': 'V-001',
          'ward_id': 'W-01',
          'zone_id': 'Z-01',
          'sim_cost_inr': 25,
          'aws_cost_inr': 100.50,
          'total_inr': 125.50,
        },
      ],
    });

    expect(summary.currency, 'INR');
    expect(summary.valveCount, 1);
    expect(summary.totalOperatingCostInr, 125.50);
    expect(summary.valves.single.valveId, 'V-001');
  });
}
