class MunicipalBillingSummary {
  final String periodStart, periodEnd, currency;
  final int valveCount;
  final double totalOperatingCostInr, usdToInrRate;
  final List<BillingValveCost> valves;
  const MunicipalBillingSummary({required this.periodStart, required this.periodEnd, required this.currency, required this.valveCount, required this.totalOperatingCostInr, required this.usdToInrRate, required this.valves});
  factory MunicipalBillingSummary.fromJson(Map<String, dynamic> json) => MunicipalBillingSummary(
    periodStart: '${json['period_start'] ?? ''}', periodEnd: '${json['period_end'] ?? ''}', currency: '${json['currency'] ?? 'INR'}',
    valveCount: (json['valve_count'] as num?)?.toInt() ?? 0, totalOperatingCostInr: (json['total_operating_cost_inr'] as num?)?.toDouble() ?? 0,
    usdToInrRate: (json['usd_to_inr_rate'] as num?)?.toDouble() ?? 0,
    valves: (json['valves'] as List? ?? const []).whereType<Map>().map((e) => BillingValveCost.fromJson(Map<String, dynamic>.from(e))).toList(growable: false),
  );
}

class BillingValveCost {
  final String valveId, wardId, zoneId;
  final double simCostInr, awsCostInr, totalInr;
  const BillingValveCost({required this.valveId, required this.wardId, required this.zoneId, required this.simCostInr, required this.awsCostInr, required this.totalInr});
  factory BillingValveCost.fromJson(Map<String, dynamic> json) => BillingValveCost(
    valveId: '${json['valve_id'] ?? ''}', wardId: '${json['ward_id'] ?? ''}', zoneId: '${json['zone_id'] ?? ''}',
    simCostInr: (json['sim_cost_inr'] as num?)?.toDouble() ?? 0, awsCostInr: (json['aws_cost_inr'] as num?)?.toDouble() ?? 0, totalInr: (json['total_inr'] as num?)?.toDouble() ?? 0,
  );
}