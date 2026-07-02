import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Human label + badge color for each ORDER_STATE_* value (ported from the web
/// Orders.tsx STATE_META). Unknown states fall back to the stripped raw value.
class OrderStateUi {
  const OrderStateUi(this.label, this.color);
  final String label;
  final Color color;

  static OrderStateUi of(String state) {
    switch (state) {
      case 'ORDER_STATE_CREATED':
        return const OrderStateUi('Created', AppColors.textSecondary);
      case 'ORDER_STATE_FROZEN':
        return const OrderStateUi('Frozen', AppColors.accentBlue);
      case 'ORDER_STATE_EXECUTING':
        return const OrderStateUi('Executing', AppColors.accentBlue);
      case 'ORDER_STATE_PENDING':
        return const OrderStateUi('Pending', AppColors.accentBlue);
      case 'ORDER_STATE_EXECUTED':
        return const OrderStateUi('Executed', AppColors.accentBlue);
      case 'ORDER_STATE_COMPLETED':
        return const OrderStateUi('Completed', AppColors.accentGreen);
      case 'ORDER_STATE_REJECTED':
        return const OrderStateUi('Rejected', AppColors.accentRed);
      case 'ORDER_STATE_FAILED':
        return const OrderStateUi('Failed', AppColors.accentRed);
      case 'ORDER_STATE_RELEASED':
        return const OrderStateUi('Refunded', AppColors.accentRed);
      default:
        final label = state.replaceFirst('ORDER_STATE_', '');
        return OrderStateUi(label.isEmpty ? 'Unknown' : label, AppColors.textSecondary);
    }
  }
}
