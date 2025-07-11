import 'package:flutter/material.dart';
import '../core/design_system/app_design_system.dart';
import '../services/pricing_service.dart';

class PricingBreakdownWidget extends StatelessWidget {
  final double distance;
  final double weight;
  final String priority;
  final bool includeInsurance;
  final bool includeTracking;
  final bool isExpress;
  final bool isFragile;
  final PricingService pricingService;

  const PricingBreakdownWidget({
    super.key,
    required this.distance,
    required this.weight,
    required this.priority,
    required this.includeInsurance,
    required this.includeTracking,
    required this.isExpress,
    required this.isFragile,
    required this.pricingService,
  });

  @override
  Widget build(BuildContext context) {
    final pricing = pricingService.pricingRules;
    final baseFee = pricing['baseFee'] as double;
    final pricePerKm = pricing['pricePerKm'] as double;
    final pricePerKg = pricing['pricePerKg'] as double;
    final priorityMultipliers = pricing['priorityMultipliers'] as Map<String, dynamic>;
    final serviceFees = pricing['serviceFees'] as Map<String, dynamic>;
    
    final priorityMultiplier = priorityMultipliers[priority] as double? ?? 1.0;
    final distanceCost = distance * pricePerKm;
    final weightCost = weight * pricePerKg;
    final subtotal = baseFee + distanceCost + weightCost;
    final priorityAdjustment = subtotal * (priorityMultiplier - 1.0);
    
    final insuranceFee = includeInsurance ? (serviceFees['insurance'] as double) : 0.0;
    final trackingFee = includeTracking ? (serviceFees['tracking'] as double) : 0.0;
    final expressFee = isExpress ? (serviceFees['express'] as double) : 0.0;
    final fragileFee = isFragile ? (serviceFees['fragile'] as double) : 0.0;
    
    final totalServiceFees = insuranceFee + trackingFee + expressFee + fragileFee;
    final totalPrice = subtotal + priorityAdjustment + totalServiceFees;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pricing Breakdown',
                style: AppDesignSystem.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppDesignSystem.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Base Costs
          _buildBreakdownItem('Base Fee', '\$${baseFee.toStringAsFixed(2)}'),
          _buildBreakdownItem('Distance (${distance.toStringAsFixed(1)} km × \$${pricePerKm.toStringAsFixed(2)}/km)', '\$${distanceCost.toStringAsFixed(2)}'),
          _buildBreakdownItem('Weight (${weight.toStringAsFixed(1)} kg × \$${pricePerKg.toStringAsFixed(2)}/kg)', '\$${weightCost.toStringAsFixed(2)}'),
          
          const Divider(height: 24),
          _buildBreakdownItem('Subtotal', '\$${subtotal.toStringAsFixed(2)}', isSubtotal: true),
          
          // Priority Adjustment
          if (priorityMultiplier != 1.0) ...[
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'Priority Adjustment (${priority.toUpperCase()} ${(priorityMultiplier * 100).toStringAsFixed(0)}%)',
              '${priorityAdjustment >= 0 ? '+' : ''}\$${priorityAdjustment.toStringAsFixed(2)}',
              isAdjustment: priorityAdjustment != 0,
            ),
          ],
          
          // Service Fees
          if (totalServiceFees > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Service Fees:',
              style: AppDesignSystem.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppDesignSystem.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (includeInsurance) _buildBreakdownItem('Package Insurance', '\$${insuranceFee.toStringAsFixed(2)}'),
            if (includeTracking) _buildBreakdownItem('Real-time Tracking', '\$${trackingFee.toStringAsFixed(2)}'),
            if (isExpress) _buildBreakdownItem('Express Delivery', '\$${expressFee.toStringAsFixed(2)}'),
            if (isFragile) _buildBreakdownItem('Fragile Handling', '\$${fragileFee.toStringAsFixed(2)}'),
          ],
          
          const Divider(height: 24),
          
          // Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppDesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price',
                  style: AppDesignSystem.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: AppDesignSystem.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value, {bool isSubtotal = false, bool isAdjustment = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: isSubtotal ? AppDesignSystem.textPrimary : AppDesignSystem.textSecondary,
                fontWeight: isSubtotal ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: AppDesignSystem.bodyMedium.copyWith(
              color: isAdjustment 
                ? (value.startsWith('+') ? Colors.orange : Colors.green)
                : (isSubtotal ? AppDesignSystem.textPrimary : AppDesignSystem.textSecondary),
              fontWeight: isSubtotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
