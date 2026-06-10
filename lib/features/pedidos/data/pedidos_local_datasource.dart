import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../productos/domain/product_order_costing_mode.dart';

class WorkOrderStatusCatalog {
  const WorkOrderStatusCatalog._();

  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String ready = 'ready';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static const List<String> activeStatuses = <String>[
    pending,
    inProgress,
    ready,
  ];

  static const List<String> allStatuses = <String>[
    pending,
    inProgress,
    ready,
    delivered,
    cancelled,
  ];

  static String label(String value) {
    switch (value.trim()) {
      case inProgress:
        return 'En producción';
      case ready:
        return 'Pendiente a entregar';
      case delivered:
        return 'Finalizado';
      case cancelled:
        return 'Cancelado';
      case pending:
      default:
        return 'Pendiente';
    }
  }
}

class WorkOrderPaymentStatusCatalog {
  const WorkOrderPaymentStatusCatalog._();

  static const String unpaid = 'unpaid';
  static const String paid = 'paid';

  static const List<String> all = <String>[unpaid, paid];

  static String label(String value) {
    switch (value.trim()) {
      case paid:
        return 'Cobrado';
      case unpaid:
      default:
        return 'Pendiente de cobro';
    }
  }
}

class WorkOrderRecordedPaymentLine {
  const WorkOrderRecordedPaymentLine({
    required this.methodCode,
    required this.methodLabel,
    required this.currencyCode,
    required this.enteredAmountCents,
    required this.paidAt,
    this.transactionId,
    this.note,
  });

  final String methodCode;
  final String methodLabel;
  final String currencyCode;
  final int enteredAmountCents;
  final DateTime paidAt;
  final String? transactionId;
  final String? note;

  factory WorkOrderRecordedPaymentLine.fromJson(Map<String, Object?> json) {
    return WorkOrderRecordedPaymentLine(
      methodCode: _string(json['methodCode'], fallback: 'cash'),
      methodLabel: _string(json['methodLabel'], fallback: 'Efectivo'),
      currencyCode: _string(json['currencyCode'], fallback: 'CUP'),
      enteredAmountCents: _intValue(json['enteredAmountCents'], fallback: 0),
      paidAt: _dateValue(json['paidAt']) ?? DateTime.now(),
      transactionId: _nullableString(json['transactionId']),
      note: _nullableString(json['note']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'methodCode': methodCode,
      'methodLabel': methodLabel,
      'currencyCode': currencyCode,
      'enteredAmountCents': enteredAmountCents,
      'paidAt': paidAt.toIso8601String(),
      'transactionId': transactionId,
      'note': note,
    };
  }
}

class WorkOrderPriorityCatalog {
  const WorkOrderPriorityCatalog._();

  static const String low = 'low';
  static const String normal = 'normal';
  static const String urgent = 'urgent';

  static const List<String> all = <String>[low, normal, urgent];

  static String label(String value) {
    switch (value.trim()) {
      case low:
        return 'Baja';
      case urgent:
        return 'Urgente';
      case normal:
      default:
        return 'Normal';
    }
  }
}

class WorkOrderDateFilterCriterion {
  const WorkOrderDateFilterCriterion._();

  static const String createdAt = 'created_at';
  static const String taskCreatedAt = 'task_created_at';
  static const String dueAt = 'due_at';

  static const List<String> all = <String>[
    createdAt,
    taskCreatedAt,
    dueAt,
  ];

  static String label(String value) {
    switch (value.trim()) {
      case taskCreatedAt:
        return 'Fecha del trabajo';
      case dueAt:
        return 'Fecha de entrega';
      case createdAt:
      default:
        return 'Fecha del pedido';
    }
  }
}

class WorkOrderCustomerOption {
  const WorkOrderCustomerOption({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.avatarPath,
  });

  final String id;
  final String code;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarPath;
}

class WorkOrderEmployeeOption {
  const WorkOrderEmployeeOption({
    required this.id,
    required this.code,
    required this.name,
    this.imagePath,
  });

  final String id;
  final String code;
  final String name;
  final String? imagePath;
}

class WorkOrderTaskTypeModel {
  const WorkOrderTaskTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;

  factory WorkOrderTaskTypeModel.fromJson(Map<String, Object?> json) {
    return WorkOrderTaskTypeModel(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      isSystem: json['isSystem'] == true,
      isActive: json['isActive'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
      'isSystem': isSystem,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  WorkOrderTaskTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSystem,
    bool? isActive,
    int? sortOrder,
  }) {
    return WorkOrderTaskTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class WorkOrderTaskWorkerRoleModel {
  const WorkOrderTaskWorkerRoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;

  factory WorkOrderTaskWorkerRoleModel.fromJson(Map<String, Object?> json) {
    return WorkOrderTaskWorkerRoleModel(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      isSystem: json['isSystem'] == true,
      isActive: json['isActive'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
      'isSystem': isSystem,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  WorkOrderTaskWorkerRoleModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSystem,
    bool? isActive,
    int? sortOrder,
  }) {
    return WorkOrderTaskWorkerRoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class WorkOrderProductOption {
  const WorkOrderProductOption({
    required this.id,
    required this.sku,
    required this.name,
    required this.unitMeasure,
    required this.currencyCode,
    this.imagePath,
  });

  final String id;
  final String sku;
  final String name;
  final String unitMeasure;
  final String currencyCode;
  final String? imagePath;
}

class WorkOrderTypeSummary {
  const WorkOrderTypeSummary({
    required this.workType,
    required this.total,
  });

  final String workType;
  final int total;
}

class WorkOrderEmployeeSummary {
  const WorkOrderEmployeeSummary({
    required this.employeeId,
    required this.employeeName,
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.ready,
  });

  final String? employeeId;
  final String employeeName;
  final int total;
  final int pending;
  final int inProgress;
  final int ready;
}

class WorkOrderMaterialConsumptionSummary {
  const WorkOrderMaterialConsumptionSummary({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
    required this.qty,
  });

  final String? productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  final double qty;
}

class WorkOrderDashboardSummary {
  const WorkOrderDashboardSummary({
    required this.pendingCount,
    required this.inProgressCount,
    required this.readyCount,
    required this.dueTodayCount,
    required this.paidCount,
    required this.unpaidCount,
    required this.withCustomerCount,
    required this.withoutCustomerCount,
    required this.withAssignmentsCount,
    required this.withoutAssignmentsCount,
    required this.dueIn3DaysCount,
    required this.dueIn7DaysCount,
    required this.dueIn15DaysCount,
    required this.materialUsageEntriesCount,
    required this.topConsumedMaterials,
    required this.byType,
    required this.byEmployee,
  });

  final int pendingCount;
  final int inProgressCount;
  final int readyCount;
  final int dueTodayCount;
  final int paidCount;
  final int unpaidCount;
  final int withCustomerCount;
  final int withoutCustomerCount;
  final int withAssignmentsCount;
  final int withoutAssignmentsCount;
  final int dueIn3DaysCount;
  final int dueIn7DaysCount;
  final int dueIn15DaysCount;
  final int materialUsageEntriesCount;
  final List<WorkOrderMaterialConsumptionSummary> topConsumedMaterials;
  final List<WorkOrderTypeSummary> byType;
  final List<WorkOrderEmployeeSummary> byEmployee;
}

class WorkOrderMaterialCostLine {
  const WorkOrderMaterialCostLine({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
    required this.currencyCode,
    required this.unitCostCents,
    required this.usedQty,
    required this.wasteQty,
    required this.totalQty,
    required this.usedCostCents,
    required this.wasteCostCents,
    required this.totalCostCents,
  });

  final String? productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  final String currencyCode;
  final int unitCostCents;
  final double usedQty;
  final double wasteQty;
  final double totalQty;
  final int usedCostCents;
  final int wasteCostCents;
  final int totalCostCents;
}

class WorkOrderCostTotal {
  const WorkOrderCostTotal({
    required this.currencyCode,
    required this.totalCostCents,
  });

  final String currencyCode;
  final int totalCostCents;

  factory WorkOrderCostTotal.fromJson(Map<String, Object?> json) {
    return WorkOrderCostTotal(
      currencyCode: _string(json['currencyCode'], fallback: 'USD'),
      totalCostCents: _intValue(json['totalCostCents'], fallback: 0),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'currencyCode': currencyCode,
      'totalCostCents': totalCostCents,
    };
  }
}

class WorkOrderRequestedCostLine {
  const WorkOrderRequestedCostLine({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
    required this.currencyCode,
    required this.unitCostCents,
    required this.orderedQty,
    required this.billedQty,
    required this.totalCostCents,
    required this.usesConsumedQty,
  });

  final String? productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  final String currencyCode;
  final int unitCostCents;
  final double orderedQty;
  final double billedQty;
  final int totalCostCents;
  final bool usesConsumedQty;

  factory WorkOrderRequestedCostLine.fromJson(Map<String, Object?> json) {
    return WorkOrderRequestedCostLine(
      productId: _nullableString(json['productId']),
      productName: _string(json['productName'], fallback: 'Producto'),
      productSku: _string(json['productSku'], fallback: '-'),
      unitLabel: _string(json['unitLabel'], fallback: 'ud'),
      currencyCode: _string(json['currencyCode'], fallback: 'USD'),
      unitCostCents: _intValue(json['unitCostCents'], fallback: 0),
      orderedQty: _doubleValue(json['orderedQty'], fallback: 0),
      billedQty: _doubleValue(json['billedQty'], fallback: 0),
      totalCostCents: _intValue(json['totalCostCents'], fallback: 0),
      usesConsumedQty: json['usesConsumedQty'] == true,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'unitLabel': unitLabel,
      'currencyCode': currencyCode,
      'unitCostCents': unitCostCents,
      'orderedQty': orderedQty,
      'billedQty': billedQty,
      'totalCostCents': totalCostCents,
      'usesConsumedQty': usesConsumedQty,
    };
  }
}

class WorkOrderPaymentValue {
  const WorkOrderPaymentValue({
    required this.label,
    required this.currencyCode,
    required this.amountCents,
  });

  final String label;
  final String currencyCode;
  final int amountCents;

  factory WorkOrderPaymentValue.fromJson(Map<String, Object?> json) {
    return WorkOrderPaymentValue(
      label: _string(json['label'], fallback: 'Valor'),
      currencyCode: _string(json['currencyCode'], fallback: 'USD'),
      amountCents: _intValue(json['amountCents'], fallback: 0),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'label': label,
      'currencyCode': currencyCode,
      'amountCents': amountCents,
    };
  }
}

class WorkOrderPricingSnapshot {
  const WorkOrderPricingSnapshot({
    required this.capturedAt,
    required this.primaryCurrencyCode,
    required this.localCurrencyCode,
    required this.foreignCurrencyCode,
    required this.localCashFixedSurcharge,
    required this.localTransferPercentSurcharge,
    required this.ratesByCode,
  });

  final DateTime capturedAt;
  final String primaryCurrencyCode;
  final String localCurrencyCode;
  final String foreignCurrencyCode;
  final double localCashFixedSurcharge;
  final double localTransferPercentSurcharge;
  final Map<String, double> ratesByCode;

  factory WorkOrderPricingSnapshot.fromJson(Map<String, Object?> json) {
    final Map<String, double> rates = <String, double>{};
    final Object? rawRates = json['ratesByCode'];
    if (rawRates is Map) {
      for (final MapEntry<Object?, Object?> entry in rawRates.entries) {
        final String code = (entry.key as String? ?? '').trim().toUpperCase();
        if (code.isEmpty) {
          continue;
        }
        rates[code] = _doubleValue(entry.value, fallback: 1);
      }
    }
    return WorkOrderPricingSnapshot(
      capturedAt: _dateValue(json['capturedAt']) ?? DateTime.now(),
      primaryCurrencyCode:
          _string(json['primaryCurrencyCode'], fallback: 'CUP'),
      localCurrencyCode: _string(json['localCurrencyCode'], fallback: 'CUP'),
      foreignCurrencyCode:
          _string(json['foreignCurrencyCode'], fallback: 'USD'),
      localCashFixedSurcharge:
          _doubleValue(json['localCashFixedSurcharge'], fallback: 0),
      localTransferPercentSurcharge:
          _doubleValue(json['localTransferPercentSurcharge'], fallback: 0),
      ratesByCode: rates,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'capturedAt': capturedAt.toIso8601String(),
      'primaryCurrencyCode': primaryCurrencyCode,
      'localCurrencyCode': localCurrencyCode,
      'foreignCurrencyCode': foreignCurrencyCode,
      'localCashFixedSurcharge': localCashFixedSurcharge,
      'localTransferPercentSurcharge': localTransferPercentSurcharge,
      'ratesByCode': ratesByCode,
    };
  }
}

class WorkOrderStatusHistoryEntry {
  const WorkOrderStatusHistoryEntry({
    required this.status,
    required this.label,
    required this.changedAt,
    required this.changedByUsername,
    required this.action,
    this.note,
  });

  final String status;
  final String label;
  final DateTime changedAt;
  final String? changedByUsername;
  final String action;
  final String? note;
}

class WorkOrderProductItem {
  const WorkOrderProductItem({
    this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
    required this.qty,
  });

  final String? productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  final double qty;

  factory WorkOrderProductItem.fromJson(Map<String, Object?> json) {
    return WorkOrderProductItem(
      productId: _nullableString(json['productId']),
      productName: _string(json['productName'], fallback: 'Producto'),
      productSku: _string(json['productSku'], fallback: '-'),
      unitLabel: _string(json['unitLabel'], fallback: 'ud'),
      qty: _doubleValue(json['qty'], fallback: 0),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'unitLabel': unitLabel,
      'qty': qty,
    };
  }
}

class WorkOrderAssignmentItem {
  const WorkOrderAssignmentItem({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.roleName,
    this.employeeImagePath,
  });

  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String roleName;
  final String? employeeImagePath;

  factory WorkOrderAssignmentItem.fromJson(Map<String, Object?> json) {
    return WorkOrderAssignmentItem(
      employeeId: _string(json['employeeId'], fallback: ''),
      employeeName: _string(json['employeeName'], fallback: 'Empleado'),
      employeeCode: _string(json['employeeCode'], fallback: '-'),
      roleName: _string(json['roleName'], fallback: 'Operario'),
      employeeImagePath: _nullableString(json['employeeImagePath']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'roleName': roleName,
      'employeeImagePath': employeeImagePath,
    };
  }
}

class WorkOrderTaskMaterialItem {
  const WorkOrderTaskMaterialItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
    required this.qty,
    this.widthMeters,
    this.heightMeters,
    this.areaSqm,
  });

  final String productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  final double qty;
  final double? widthMeters;
  final double? heightMeters;
  final double? areaSqm;

  factory WorkOrderTaskMaterialItem.fromJson(Map<String, Object?> json) {
    return WorkOrderTaskMaterialItem(
      productId: _string(json['productId'], fallback: ''),
      productName: _string(json['productName'], fallback: 'Material'),
      productSku: _string(json['productSku'], fallback: '-'),
      unitLabel: _string(json['unitLabel'], fallback: 'ud'),
      qty: _doubleValue(json['qty'], fallback: 0),
      widthMeters: _nullableDouble(json['widthMeters']),
      heightMeters: _nullableDouble(json['heightMeters']),
      areaSqm: _nullableDouble(json['areaSqm']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'unitLabel': unitLabel,
      'qty': qty,
      'widthMeters': widthMeters,
      'heightMeters': heightMeters,
      'areaSqm': areaSqm,
    };
  }
}

class WorkOrderTaskWorkerItem {
  const WorkOrderTaskWorkerItem({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.roleName,
    this.employeeImagePath,
  });

  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String roleName;
  final String? employeeImagePath;

  factory WorkOrderTaskWorkerItem.fromJson(Map<String, Object?> json) {
    return WorkOrderTaskWorkerItem(
      employeeId: _string(json['employeeId'], fallback: ''),
      employeeName: _string(json['employeeName'], fallback: 'Empleado'),
      employeeCode: _string(json['employeeCode'], fallback: '-'),
      roleName: _string(json['roleName'], fallback: 'Operario'),
      employeeImagePath: _nullableString(json['employeeImagePath']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'roleName': roleName,
      'employeeImagePath': employeeImagePath,
    };
  }
}

class WorkOrderTaskItem {
  const WorkOrderTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.materials,
    required this.wasteMaterials,
    required this.workers,
    required this.imagePaths,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final List<WorkOrderTaskMaterialItem> materials;
  final List<WorkOrderTaskMaterialItem> wasteMaterials;
  final List<WorkOrderTaskWorkerItem> workers;
  final List<String> imagePaths;

  factory WorkOrderTaskItem.fromJson(Map<String, Object?> json) {
    return WorkOrderTaskItem(
      id: _string(json['id'], fallback: const Uuid().v4()),
      title: _string(json['title'], fallback: 'Trabajo realizado'),
      description: _nullableString(json['description']),
      createdAt: _dateValue(json['createdAt']) ?? DateTime.now(),
      materials: _listOfMaps(json['materials'])
          .map(WorkOrderTaskMaterialItem.fromJson)
          .toList(growable: false),
      wasteMaterials: _listOfMaps(json['wasteMaterials'])
          .map(WorkOrderTaskMaterialItem.fromJson)
          .toList(growable: false),
      workers: _listOfMaps(json['workers'])
          .map(WorkOrderTaskWorkerItem.fromJson)
          .toList(growable: false),
      imagePaths: _listOfStrings(json['imagePaths']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'materials': materials
          .map((WorkOrderTaskMaterialItem item) => item.toJson())
          .toList(growable: false),
      'wasteMaterials': wasteMaterials
          .map((WorkOrderTaskMaterialItem item) => item.toJson())
          .toList(growable: false),
      'workers': workers
          .map((WorkOrderTaskWorkerItem item) => item.toJson())
          .toList(growable: false),
      'imagePaths': imagePaths,
    };
  }

  WorkOrderTaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    List<WorkOrderTaskMaterialItem>? materials,
    List<WorkOrderTaskMaterialItem>? wasteMaterials,
    List<WorkOrderTaskWorkerItem>? workers,
    List<String>? imagePaths,
  }) {
    return WorkOrderTaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      materials: materials ?? this.materials,
      wasteMaterials: wasteMaterials ?? this.wasteMaterials,
      workers: workers ?? this.workers,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}

class WorkOrderListItem {
  const WorkOrderListItem({
    required this.id,
    required this.folio,
    required this.title,
    required this.workType,
    required this.status,
    required this.priority,
    required this.customerName,
    required this.itemSummary,
    required this.assignmentSummary,
    required this.itemCount,
    required this.hasMaterialUsage,
    required this.orderTotalCosts,
    required this.paymentStatus,
    required this.paymentValues,
    required this.createdAt,
    required this.paymentLines,
    this.paidAt,
    this.dueAt,
  });

  final String id;
  final String folio;
  final String title;
  final String workType;
  final String status;
  final String priority;
  final String? customerName;
  final String itemSummary;
  final String assignmentSummary;
  final int itemCount;
  final bool hasMaterialUsage;
  final List<WorkOrderCostTotal> orderTotalCosts;
  final String paymentStatus;
  final List<WorkOrderPaymentValue> paymentValues;
  final DateTime createdAt;
  final List<WorkOrderRecordedPaymentLine> paymentLines;
  final DateTime? paidAt;
  final DateTime? dueAt;
}

class WorkOrderDetail {
  const WorkOrderDetail({
    required this.id,
    required this.folio,
    required this.title,
    required this.workType,
    required this.status,
    required this.priority,
    required this.description,
    required this.note,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.createdByUsername,
    required this.updatedByUsername,
    required this.createdAt,
    required this.updatedAt,
    required this.dueAt,
    required this.completedAt,
    required this.paymentStatus,
    required this.paymentValues,
    required this.pricingSnapshot,
    required this.paymentLines,
    required this.paidAt,
    required this.deliveredAt,
    required this.items,
    required this.assignments,
    required this.tasks,
    required this.materialCostLines,
    required this.materialTotalCosts,
    required this.requestedCostLines,
    required this.totalCosts,
  });

  final String id;
  final String folio;
  final String title;
  final String workType;
  final String status;
  final String priority;
  final String? description;
  final String? note;
  final String? customerId;
  final String? customerName;
  final String? customerCode;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String createdByUsername;
  final String? updatedByUsername;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String paymentStatus;
  final List<WorkOrderPaymentValue> paymentValues;
  final WorkOrderPricingSnapshot? pricingSnapshot;
  final List<WorkOrderRecordedPaymentLine> paymentLines;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final List<WorkOrderProductItem> items;
  final List<WorkOrderAssignmentItem> assignments;
  final List<WorkOrderTaskItem> tasks;
  final List<WorkOrderMaterialCostLine> materialCostLines;
  final List<WorkOrderCostTotal> materialTotalCosts;
  final List<WorkOrderRequestedCostLine> requestedCostLines;
  final List<WorkOrderCostTotal> totalCosts;
}

class WorkOrderUpsertInput {
  const WorkOrderUpsertInput({
    required this.title,
    required this.workType,
    required this.status,
    required this.priority,
    required this.items,
    required this.assignments,
    required this.createdAt,
    this.customerId,
    this.description,
    this.note,
    this.dueAt,
  });

  final String title;
  final String workType;
  final String status;
  final String priority;
  final List<WorkOrderProductItem> items;
  final List<WorkOrderAssignmentItem> assignments;
  final DateTime createdAt;
  final String? customerId;
  final String? description;
  final String? note;
  final DateTime? dueAt;
}

class WorkOrderTaskCreateInput {
  const WorkOrderTaskCreateInput({
    required this.title,
    required this.materials,
    required this.wasteMaterials,
    required this.workers,
    required this.imagePaths,
    this.description,
  });

  final String title;
  final String? description;
  final List<WorkOrderTaskMaterialItem> materials;
  final List<WorkOrderTaskMaterialItem> wasteMaterials;
  final List<WorkOrderTaskWorkerItem> workers;
  final List<String> imagePaths;
}

class WorkOrderPaymentUpdateInput {
  const WorkOrderPaymentUpdateInput({
    required this.paymentStatus,
    required this.pricingSnapshot,
    required this.paymentLines,
    this.paidAt,
  });

  final String paymentStatus;
  final WorkOrderPricingSnapshot pricingSnapshot;
  final List<WorkOrderRecordedPaymentLine> paymentLines;
  final DateTime? paidAt;
}

class PedidosLocalDataSource {
  PedidosLocalDataSource(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;
  static const String _taskTypesCatalogKey = 'work_order_task_types_catalog_v1';
  static const String _taskWorkerRolesCatalogKey =
      'work_order_task_worker_roles_catalog_v1';

  static const List<String> defaultWorkTypes = <String>[
    'Tarjetas',
    'Volantes',
    'Lonas',
    'Pegatinas',
    'Sellos',
    'Papeleria',
    'Fotocopias',
    'Diseño',
    'General',
  ];

  Future<void> _logAudit({
    required String userId,
    required String action,
    required String entityId,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return _db.into(_db.auditLogs).insert(
          AuditLogsCompanion.insert(
            id: _uuid.v4(),
            userId: Value(userId),
            action: action,
            entity: 'work_order',
            entityId: entityId,
            payloadJson: jsonEncode(payload),
          ),
        );
  }

  Future<WorkOrderDashboardSummary> loadDashboardSummary({
    DateTime? createdFrom,
    DateTime? createdTo,
    String dateCriterion = WorkOrderDateFilterCriterion.createdAt,
  }) async {
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    final List<WorkOrder> rows = await (_db.select(_db.workOrders)).get();

    int pendingCount = 0;
    int inProgressCount = 0;
    int readyCount = 0;
    int dueTodayCount = 0;
    int paidCount = 0;
    int unpaidCount = 0;
    int withCustomerCount = 0;
    int withoutCustomerCount = 0;
    int withAssignmentsCount = 0;
    int withoutAssignmentsCount = 0;
    int dueIn3DaysCount = 0;
    int dueIn7DaysCount = 0;
    int dueIn15DaysCount = 0;
    int materialUsageEntriesCount = 0;
    final Map<String, int> byType = <String, int>{};
    final Map<String, _EmployeeAccumulator> byEmployee =
        <String, _EmployeeAccumulator>{};
    final Map<String, _MaterialConsumptionAccumulator> materialUsage =
        <String, _MaterialConsumptionAccumulator>{};

    for (final WorkOrder row in rows) {
      final List<WorkOrderTaskItem> tasks = _parseTasks(row.tasksJson);
      if (!_matchesOrderDateRange(
        row,
        tasks: tasks,
        from: createdFrom,
        to: createdTo,
        criterion: dateCriterion,
      )) {
        continue;
      }
      final String status = _normalizeStatus(row.status);
      final String paymentStatus = _normalizePaymentStatus(row.paymentStatus);
      final bool isActiveStatus =
          WorkOrderStatusCatalog.activeStatuses.contains(status);
      final bool isCancelled = status == WorkOrderStatusCatalog.cancelled;
      if (isActiveStatus) {
        if (status == WorkOrderStatusCatalog.pending) {
          pendingCount += 1;
        } else if (status == WorkOrderStatusCatalog.inProgress) {
          inProgressCount += 1;
        } else if (status == WorkOrderStatusCatalog.ready) {
          readyCount += 1;
        }
      }
      if (!isCancelled) {
        if (paymentStatus == WorkOrderPaymentStatusCatalog.paid) {
          paidCount += 1;
        } else {
          unpaidCount += 1;
        }
      }

      final DateTime? dueAt = row.dueAt;
      if (isActiveStatus &&
          dueAt != null &&
          dueAt.year == today.year &&
          dueAt.month == today.month &&
          dueAt.day == today.day) {
        dueTodayCount += 1;
      }
      if ((row.customerId ?? '').trim().isEmpty &&
          (row.customerNameSnapshot ?? '').trim().isEmpty) {
        withoutCustomerCount += 1;
      } else {
        withCustomerCount += 1;
      }

      final String workType = _normalizeWorkType(row.workType);
      byType.update(workType, (int value) => value + 1, ifAbsent: () => 1);

      final List<WorkOrderAssignmentItem> assignments =
          _parseAssignments(row.assignmentsJson, fallback: row);
      if (assignments.isEmpty) {
        withoutAssignmentsCount += 1;
      } else {
        withAssignmentsCount += 1;
      }

      if (isActiveStatus && dueAt != null) {
        final DateTime dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);
        final int daysUntilDue = dueDate.difference(todayDate).inDays;
        if (daysUntilDue >= 0 && daysUntilDue <= 15) {
          dueIn15DaysCount += 1;
          if (daysUntilDue <= 7) {
            dueIn7DaysCount += 1;
            if (daysUntilDue <= 3) {
              dueIn3DaysCount += 1;
            }
          }
        }
      }

      final Set<String> uniqueEmployeeIds = <String>{};
      for (final WorkOrderAssignmentItem assignment in assignments) {
        final String employeeId = assignment.employeeId.trim();
        if (employeeId.isEmpty || uniqueEmployeeIds.contains(employeeId)) {
          continue;
        }
        uniqueEmployeeIds.add(employeeId);
        final _EmployeeAccumulator acc = byEmployee.putIfAbsent(
          employeeId,
          () => _EmployeeAccumulator(
            employeeId: employeeId,
            employeeName: assignment.employeeName,
          ),
        );
        acc.total += 1;
        if (status == WorkOrderStatusCatalog.pending) {
          acc.pending += 1;
        } else if (status == WorkOrderStatusCatalog.inProgress) {
          acc.inProgress += 1;
        } else if (status == WorkOrderStatusCatalog.ready) {
          acc.ready += 1;
        }
      }

      for (final WorkOrderTaskItem task in tasks) {
        for (final WorkOrderTaskMaterialItem item in task.materials) {
          final String key =
              '${item.productId}|${item.productName}|${item.unitLabel}';
          final _MaterialConsumptionAccumulator accumulator =
              materialUsage.putIfAbsent(
            key,
            () => _MaterialConsumptionAccumulator(
              productId: item.productId,
              productName: item.productName,
              productSku: item.productSku,
              unitLabel: item.unitLabel,
            ),
          );
          accumulator.qty = _roundTo2(accumulator.qty + item.qty);
          materialUsageEntriesCount += 1;
        }
      }
    }

    final List<WorkOrderTypeSummary> typeRows = byType.entries
        .map(
          (MapEntry<String, int> entry) => WorkOrderTypeSummary(
            workType: entry.key,
            total: entry.value,
          ),
        )
        .toList()
      ..sort((WorkOrderTypeSummary a, WorkOrderTypeSummary b) {
        final int cmp = b.total.compareTo(a.total);
        if (cmp != 0) {
          return cmp;
        }
        return a.workType.compareTo(b.workType);
      });

    final List<WorkOrderEmployeeSummary> employeeRows =
        byEmployee.values.map((acc) => acc.toSummary()).toList()
          ..sort((WorkOrderEmployeeSummary a, WorkOrderEmployeeSummary b) {
            final int cmp = b.total.compareTo(a.total);
            if (cmp != 0) {
              return cmp;
            }
            return a.employeeName.compareTo(b.employeeName);
          });

    final List<WorkOrderMaterialConsumptionSummary> topConsumedMaterials =
        materialUsage.values
            .map(
              (_MaterialConsumptionAccumulator row) =>
                  WorkOrderMaterialConsumptionSummary(
                productId: row.productId,
                productName: row.productName,
                productSku: row.productSku,
                unitLabel: row.unitLabel,
                qty: row.qty,
              ),
            )
            .toList()
          ..sort(
            (
              WorkOrderMaterialConsumptionSummary a,
              WorkOrderMaterialConsumptionSummary b,
            ) {
              final int qtyCompare = b.qty.compareTo(a.qty);
              if (qtyCompare != 0) {
                return qtyCompare;
              }
              return a.productName.compareTo(b.productName);
            },
          );

    return WorkOrderDashboardSummary(
      pendingCount: pendingCount,
      inProgressCount: inProgressCount,
      readyCount: readyCount,
      dueTodayCount: dueTodayCount,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
      withCustomerCount: withCustomerCount,
      withoutCustomerCount: withoutCustomerCount,
      withAssignmentsCount: withAssignmentsCount,
      withoutAssignmentsCount: withoutAssignmentsCount,
      dueIn3DaysCount: dueIn3DaysCount,
      dueIn7DaysCount: dueIn7DaysCount,
      dueIn15DaysCount: dueIn15DaysCount,
      materialUsageEntriesCount: materialUsageEntriesCount,
      topConsumedMaterials: topConsumedMaterials.take(4).toList(
            growable: false,
          ),
      byType: typeRows.take(8).toList(growable: false),
      byEmployee: employeeRows.take(8).toList(growable: false),
    );
  }

  Future<List<WorkOrderListItem>> listOrders({
    String searchQuery = '',
    String statusFilter = 'all',
    String typeFilter = 'all',
    DateTime? createdFrom,
    DateTime? createdTo,
    String dateCriterion = WorkOrderDateFilterCriterion.createdAt,
    int limit = 200,
  }) async {
    final String normalizedStatus = _normalizeStatusFilter(statusFilter);
    final String normalizedType = typeFilter.trim();
    final List<WorkOrder> rows = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) {
            Expression<bool> predicate = const Constant(true);
            if (normalizedStatus != 'all') {
              predicate = predicate & tbl.status.equals(normalizedStatus);
            }
            if (normalizedType.isNotEmpty &&
                normalizedType.toLowerCase() != 'all') {
              predicate = predicate & tbl.workType.equals(normalizedType);
            }
            return predicate;
          })
          ..orderBy(<OrderingTerm Function(WorkOrders)>[
            (WorkOrders tbl) => OrderingTerm.asc(tbl.status),
            (WorkOrders tbl) => OrderingTerm.asc(tbl.dueAt),
            (WorkOrders tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .get();

    final String search = searchQuery.trim().toLowerCase();
    final List<WorkOrderListItem> mapped = <WorkOrderListItem>[];
    for (final WorkOrder row in rows) {
      final List<WorkOrderProductItem> items = _parseItems(row.itemsJson, row);
      final List<WorkOrderAssignmentItem> assignments =
          _parseAssignments(row.assignmentsJson, fallback: row);
      final List<WorkOrderTaskItem> tasks = _parseTasks(row.tasksJson);
      final _RequestedOrderCostSummary requestedCostSummary =
          await _buildRequestedOrderCostSummary(
        items: items,
        tasks: tasks,
      );
      if (!_matchesOrderDateRange(
        row,
        tasks: tasks,
        from: createdFrom,
        to: createdTo,
        criterion: dateCriterion,
      )) {
        continue;
      }
      final String itemSummary = _buildItemSummary(items);
      final String assignmentSummary = _buildAssignmentSummary(assignments);
      final bool hasMaterialUsage = tasks.any(
        (WorkOrderTaskItem task) =>
            task.materials.isNotEmpty || task.wasteMaterials.isNotEmpty,
      );
      final List<WorkOrderCostTotal> quotedTotals =
          _parseCostTotalsJson(row.quotedTotalsJson);
      final List<WorkOrderPaymentValue> paymentValues =
          _parsePaymentValuesJson(row.quotedPaymentVariantsJson);
      final List<WorkOrderRecordedPaymentLine> paymentLines =
          _parsePaymentLinesJson(row.paymentLinesJson);
      final String title = _displayTitle(row.title, items);
      final String customerName = (row.customerNameSnapshot ?? '').trim();

      final String haystack = <String>[
        row.folio,
        title,
        row.workType,
        customerName,
        itemSummary,
        assignmentSummary,
        ...items.map((WorkOrderProductItem item) => item.productName),
        ...items.map((WorkOrderProductItem item) => item.productSku),
      ].join(' ').toLowerCase();
      if (search.isNotEmpty && !haystack.contains(search)) {
        continue;
      }

      mapped.add(
        WorkOrderListItem(
          id: row.id,
          folio: row.folio,
          title: title,
          workType: _normalizeWorkType(row.workType),
          status: _normalizeStatus(row.status),
          priority: _normalizePriority(row.priority),
          customerName: customerName.isEmpty ? null : customerName,
          itemSummary: itemSummary,
          assignmentSummary: assignmentSummary,
          itemCount: items.length,
          hasMaterialUsage: hasMaterialUsage,
          orderTotalCosts:
              quotedTotals.isEmpty ? requestedCostSummary.totals : quotedTotals,
          paymentStatus: _normalizePaymentStatus(row.paymentStatus),
          paymentValues: paymentValues,
          createdAt: row.createdAt,
          paymentLines: paymentLines,
          paidAt: row.paidAt,
          dueAt: row.dueAt,
        ),
      );
      if (mapped.length >= limit) {
        break;
      }
    }
    return mapped;
  }

  Future<WorkOrderDetail?> getOrderById(String orderId) async {
    final String cleanId = orderId.trim();
    if (cleanId.isEmpty) {
      return null;
    }
    final WorkOrder? dbRow = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(cleanId)))
        .getSingleOrNull();
    if (dbRow == null) {
      return null;
    }
    final Customer? customer = dbRow.customerId == null
        ? null
        : await (_db.select(_db.customers)
              ..where((Customers tbl) => tbl.id.equals(dbRow.customerId!)))
            .getSingleOrNull();
    final User? createdBy = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(dbRow.createdBy)))
        .getSingleOrNull();
    final User? updatedBy = dbRow.updatedBy == null
        ? null
        : await (_db.select(_db.users)
              ..where((Users tbl) => tbl.id.equals(dbRow.updatedBy!)))
            .getSingleOrNull();
    final List<WorkOrderProductItem> items =
        _parseItems(dbRow.itemsJson, dbRow);
    final List<WorkOrderAssignmentItem> assignments =
        _parseAssignments(dbRow.assignmentsJson, fallback: dbRow);
    final List<WorkOrderTaskItem> tasks = _parseTasks(dbRow.tasksJson);
    final _WorkOrderCostSummary materialCostSummary =
        await _buildMaterialCostSummary(tasks);
    final List<WorkOrderRequestedCostLine> quotedRequestedLines =
        _parseRequestedCostLinesJson(dbRow.quotedRequestedLinesJson);
    final List<WorkOrderCostTotal> quotedTotals =
        _parseCostTotalsJson(dbRow.quotedTotalsJson);
    final List<WorkOrderPaymentValue> paymentValues =
        _parsePaymentValuesJson(dbRow.quotedPaymentVariantsJson);
    final WorkOrderPricingSnapshot? pricingSnapshot =
        _parsePricingSnapshotJson(dbRow.pricingSnapshotJson);
    final List<WorkOrderRecordedPaymentLine> paymentLines =
        _parsePaymentLinesJson(dbRow.paymentLinesJson);
    final _RequestedOrderCostSummary requestedCostSummary =
        await _buildRequestedOrderCostSummary(
      items: items,
      tasks: tasks,
    );

    return WorkOrderDetail(
      id: dbRow.id,
      folio: dbRow.folio,
      title: _displayTitle(dbRow.title, items),
      workType: _normalizeWorkType(dbRow.workType),
      status: _normalizeStatus(dbRow.status),
      priority: _normalizePriority(dbRow.priority),
      description: _normalizeOptional(dbRow.description),
      note: _normalizeOptional(dbRow.note),
      customerId: _normalizeOptional(dbRow.customerId),
      customerName: _normalizeOptional(
        customer?.fullName ?? dbRow.customerNameSnapshot,
      ),
      customerCode: _normalizeOptional(customer?.code),
      customerPhone: _normalizeOptional(customer?.phone),
      customerEmail: _normalizeOptional(customer?.email),
      customerAddress: _normalizeOptional(customer?.address),
      createdByUsername: _string(
        createdBy?.username,
        fallback: 'Sin usuario',
      ),
      updatedByUsername: _normalizeOptional(updatedBy?.username),
      createdAt: dbRow.createdAt,
      updatedAt: dbRow.updatedAt,
      dueAt: dbRow.dueAt,
      completedAt: dbRow.completedAt,
      paymentStatus: _normalizePaymentStatus(dbRow.paymentStatus),
      paymentValues: paymentValues,
      pricingSnapshot: pricingSnapshot,
      paymentLines: paymentLines,
      paidAt: dbRow.paidAt,
      deliveredAt: dbRow.deliveredAt,
      items: items,
      assignments: assignments,
      tasks: tasks,
      materialCostLines: materialCostSummary.lines,
      materialTotalCosts: materialCostSummary.totals,
      requestedCostLines: quotedRequestedLines.isEmpty
          ? requestedCostSummary.lines
          : quotedRequestedLines,
      totalCosts:
          quotedTotals.isEmpty ? requestedCostSummary.totals : quotedTotals,
    );
  }

  Future<List<WorkOrderStatusHistoryEntry>> getOrderStatusHistory(
    String orderId,
  ) async {
    final String cleanId = orderId.trim();
    if (cleanId.isEmpty) {
      return const <WorkOrderStatusHistoryEntry>[];
    }
    final WorkOrder? dbRow = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(cleanId)))
        .getSingleOrNull();
    if (dbRow == null) {
      return const <WorkOrderStatusHistoryEntry>[];
    }

    final User? createdBy = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(dbRow.createdBy)))
        .getSingleOrNull();

    final List<WorkOrderStatusHistoryEntry> entries =
        <WorkOrderStatusHistoryEntry>[
      WorkOrderStatusHistoryEntry(
        status: WorkOrderStatusCatalog.pending,
        label: 'Pedido creado',
        changedAt: dbRow.createdAt,
        changedByUsername: _normalizeOptional(createdBy?.username),
        action: 'create',
        note: 'Estado inicial del pedido.',
      ),
    ];

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT a.action, a.payload_json, a.created_at, u.username AS username
      FROM audit_logs a
      LEFT JOIN users u ON u.id = a.user_id
      WHERE a.entity = 'work_order'
        AND a.entity_id = ?
        AND a.action IN ('update_status', 'delete')
      ORDER BY a.created_at ASC
      ''',
      variables: <Variable<Object>>[
        Variable<String>(cleanId),
      ],
    ).get();

    for (final QueryRow row in rows) {
      final String action =
          _string(row.readNullable<String>('action'), fallback: '').trim();
      final DateTime changedAt = row.readNullable<DateTime>('created_at') ??
          dbRow.updatedAt ??
          dbRow.createdAt;
      final String? username = _normalizeOptional(
        row.readNullable<String>('username'),
      );
      final Map<String, Object?> payload = _decodeJsonMap(
        row.readNullable<String>('payload_json'),
      );

      if (action == 'update_status') {
        final String status = _normalizeStatus(
          _string(payload['status'], fallback: WorkOrderStatusCatalog.pending),
        );
        final String? fromStatus = _normalizeOptional(
          _string(payload['fromStatus'], fallback: '').trim(),
        );
        entries.add(
          WorkOrderStatusHistoryEntry(
            status: status,
            label: 'Estado actualizado',
            changedAt: changedAt,
            changedByUsername: username,
            action: action,
            note: fromStatus == null
                ? null
                : 'De ${WorkOrderStatusCatalog.label(fromStatus)} a ${WorkOrderStatusCatalog.label(status)}.',
          ),
        );
      } else if (action == 'delete') {
        entries.add(
          WorkOrderStatusHistoryEntry(
            status: WorkOrderStatusCatalog.cancelled,
            label: 'Pedido eliminado',
            changedAt: changedAt,
            changedByUsername: username,
            action: action,
            note: 'El pedido fue eliminado definitivamente.',
          ),
        );
      }
    }

    return entries;
  }

  Future<List<WorkOrderCustomerOption>> listCustomerOptions() async {
    final List<Customer> rows = await (_db.select(_db.customers)
          ..where((Customers tbl) => tbl.isActive.equals(true))
          ..orderBy(<OrderingTerm Function(Customers)>[
            (Customers tbl) => OrderingTerm.asc(tbl.fullName),
          ]))
        .get();
    return rows
        .map(
          (Customer row) => WorkOrderCustomerOption(
            id: row.id,
            code: row.code,
            name: row.fullName,
            phone: row.phone,
            email: row.email,
            avatarPath: row.avatarPath,
          ),
        )
        .toList(growable: false);
  }

  Future<List<WorkOrderEmployeeOption>> listEmployeeOptions() async {
    final List<Employee> rows = await (_db.select(_db.employees)
          ..where((Employees tbl) => tbl.isActive.equals(true))
          ..orderBy(<OrderingTerm Function(Employees)>[
            (Employees tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
    return rows
        .map(
          (Employee row) => WorkOrderEmployeeOption(
            id: row.id,
            code: row.code,
            name: row.name,
            imagePath: row.imagePath,
          ),
        )
        .toList(growable: false);
  }

  Future<List<WorkOrderTaskTypeModel>> loadTaskTypesCatalog() async {
    final AppSetting? setting = await (_db.select(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.equals(_taskTypesCatalogKey)))
        .getSingleOrNull();

    List<WorkOrderTaskTypeModel> catalog;
    if (setting == null) {
      catalog = _defaultTaskTypes();
      await _saveTaskTypesCatalog(catalog);
    } else {
      try {
        final Object? decoded = jsonDecode(setting.value);
        if (decoded is List) {
          catalog = decoded
              .whereType<Map>()
              .map(
                (Map row) => WorkOrderTaskTypeModel.fromJson(
                  row.cast<String, Object?>(),
                ),
              )
              .toList(growable: false);
        } else {
          catalog = _defaultTaskTypes();
        }
      } catch (_) {
        catalog = _defaultTaskTypes();
      }
      catalog = _mergeDefaultTaskTypes(catalog);
      await _saveTaskTypesCatalog(catalog);
    }
    return _normalizeTaskTypes(catalog);
  }

  Future<List<String>> listActiveTaskTypeOptions() async {
    final List<WorkOrderTaskTypeModel> catalog = await loadTaskTypesCatalog();
    return catalog
        .where((WorkOrderTaskTypeModel row) => row.isActive)
        .map((WorkOrderTaskTypeModel row) => row.name)
        .toList(growable: false);
  }

  Future<List<WorkOrderTaskWorkerRoleModel>>
      loadTaskWorkerRolesCatalog() async {
    final AppSetting? setting = await (_db.select(_db.appSettings)
          ..where(
            (AppSettings tbl) => tbl.key.equals(_taskWorkerRolesCatalogKey),
          ))
        .getSingleOrNull();

    List<WorkOrderTaskWorkerRoleModel> catalog;
    if (setting == null) {
      catalog = _defaultTaskWorkerRoles();
      await _saveTaskWorkerRolesCatalog(catalog);
    } else {
      try {
        final Object? decoded = jsonDecode(setting.value);
        if (decoded is List) {
          catalog = decoded
              .whereType<Map>()
              .map(
                (Map row) => WorkOrderTaskWorkerRoleModel.fromJson(
                  row.cast<String, Object?>(),
                ),
              )
              .toList(growable: false);
        } else {
          catalog = _defaultTaskWorkerRoles();
        }
      } catch (_) {
        catalog = _defaultTaskWorkerRoles();
      }
      catalog = _mergeDefaultTaskWorkerRoles(catalog);
      await _saveTaskWorkerRolesCatalog(catalog);
    }
    return _normalizeTaskWorkerRoles(catalog);
  }

  Future<List<String>> listActiveTaskWorkerRoleOptions() async {
    final List<WorkOrderTaskWorkerRoleModel> catalog =
        await loadTaskWorkerRolesCatalog();
    return catalog
        .where((WorkOrderTaskWorkerRoleModel row) => row.isActive)
        .map((WorkOrderTaskWorkerRoleModel row) => row.name)
        .toList(growable: false);
  }

  Future<void> upsertTaskType({
    String? typeId,
    required String name,
    String? description,
    bool? isActive,
  }) async {
    final List<WorkOrderTaskTypeModel> catalog =
        await loadTaskTypesCatalog().then(
      (List<WorkOrderTaskTypeModel> value) => value.toList(growable: true),
    );
    final String cleanName = _normalizeCatalogValue(name);
    final String cleanDescription = (description ?? '').trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre del tipo de trabajo es obligatorio.');
    }

    final String? editingId = typeId?.trim().isEmpty ?? true ? null : typeId;
    for (final WorkOrderTaskTypeModel row in catalog) {
      if (editingId != null && row.id == editingId) {
        continue;
      }
      if (row.name.trim().toLowerCase() == cleanName.toLowerCase()) {
        throw Exception('Ya existe un tipo de trabajo con ese nombre.');
      }
    }

    if (editingId == null) {
      final int nextSort = catalog.isEmpty
          ? 0
          : catalog
                  .map((WorkOrderTaskTypeModel row) => row.sortOrder)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;
      catalog.add(
        WorkOrderTaskTypeModel(
          id: _uuid.v4(),
          name: cleanName,
          description: cleanDescription,
          isSystem: false,
          isActive: isActive ?? true,
          sortOrder: nextSort,
        ),
      );
    } else {
      final int index = catalog.indexWhere(
        (WorkOrderTaskTypeModel row) => row.id == editingId,
      );
      if (index < 0) {
        throw Exception('El tipo de trabajo seleccionado no existe.');
      }
      final WorkOrderTaskTypeModel current = catalog[index];
      catalog[index] = current.copyWith(
        name: cleanName,
        description: cleanDescription,
        isActive: isActive ?? current.isActive,
      );
    }

    await _saveTaskTypesCatalog(_normalizeTaskTypes(catalog));
  }

  Future<void> setTaskTypeActive({
    required String typeId,
    required bool isActive,
  }) async {
    final List<WorkOrderTaskTypeModel> catalog =
        await loadTaskTypesCatalog().then(
      (List<WorkOrderTaskTypeModel> value) => value.toList(growable: true),
    );
    final int index = catalog.indexWhere(
      (WorkOrderTaskTypeModel row) => row.id == typeId,
    );
    if (index < 0) {
      throw Exception('El tipo de trabajo no existe.');
    }
    catalog[index] = catalog[index].copyWith(isActive: isActive);
    await _saveTaskTypesCatalog(_normalizeTaskTypes(catalog));
  }

  Future<void> upsertTaskWorkerRole({
    String? roleId,
    required String name,
    String? description,
    bool? isActive,
  }) async {
    final List<WorkOrderTaskWorkerRoleModel> catalog =
        await loadTaskWorkerRolesCatalog().then(
      (List<WorkOrderTaskWorkerRoleModel> value) =>
          value.toList(growable: true),
    );
    final String cleanName = _normalizeCatalogValue(name);
    final String cleanDescription = (description ?? '').trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre del rol es obligatorio.');
    }

    final String? editingId = roleId?.trim().isEmpty ?? true ? null : roleId;
    for (final WorkOrderTaskWorkerRoleModel row in catalog) {
      if (editingId != null && row.id == editingId) {
        continue;
      }
      if (row.name.trim().toLowerCase() == cleanName.toLowerCase()) {
        throw Exception('Ya existe un rol con ese nombre.');
      }
    }

    if (editingId == null) {
      final int nextSort = catalog.isEmpty
          ? 0
          : catalog
                  .map((WorkOrderTaskWorkerRoleModel row) => row.sortOrder)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;
      catalog.add(
        WorkOrderTaskWorkerRoleModel(
          id: _uuid.v4(),
          name: cleanName,
          description: cleanDescription,
          isSystem: false,
          isActive: isActive ?? true,
          sortOrder: nextSort,
        ),
      );
    } else {
      final int index = catalog.indexWhere(
        (WorkOrderTaskWorkerRoleModel row) => row.id == editingId,
      );
      if (index < 0) {
        throw Exception('El rol seleccionado no existe.');
      }
      final WorkOrderTaskWorkerRoleModel current = catalog[index];
      catalog[index] = current.copyWith(
        name: cleanName,
        description: cleanDescription,
        isActive: isActive ?? current.isActive,
      );
    }

    await _saveTaskWorkerRolesCatalog(_normalizeTaskWorkerRoles(catalog));
  }

  Future<void> setTaskWorkerRoleActive({
    required String roleId,
    required bool isActive,
  }) async {
    final List<WorkOrderTaskWorkerRoleModel> catalog =
        await loadTaskWorkerRolesCatalog().then(
      (List<WorkOrderTaskWorkerRoleModel> value) =>
          value.toList(growable: true),
    );
    final int index = catalog.indexWhere(
      (WorkOrderTaskWorkerRoleModel row) => row.id == roleId,
    );
    if (index < 0) {
      throw Exception('El rol no existe.');
    }
    catalog[index] = catalog[index].copyWith(isActive: isActive);
    await _saveTaskWorkerRolesCatalog(_normalizeTaskWorkerRoles(catalog));
  }

  Future<List<WorkOrderProductOption>> listProductOptions() async {
    final List<Product> rows = await (_db.select(_db.products)
          ..where((Products tbl) => tbl.isActive.equals(true))
          ..orderBy(<OrderingTerm Function(Products)>[
            (Products tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
    return rows
        .map(
          (Product row) => WorkOrderProductOption(
            id: row.id,
            sku: row.sku,
            name: row.name,
            unitMeasure: row.unitMeasure,
            currencyCode: row.currencyCode,
            imagePath: row.imagePath,
          ),
        )
        .toList(growable: false);
  }

  Future<List<String>> listKnownWorkTypes() async {
    final Set<String> values = <String>{...defaultWorkTypes};
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT DISTINCT COALESCE(NULLIF(TRIM(work_type), ''), 'General') AS work_type
      FROM work_orders
      ORDER BY work_type ASC
      ''',
    ).get();
    for (final QueryRow row in rows) {
      values.add(
          _string(row.readNullable<String>('work_type'), fallback: 'General'));
    }
    final List<String> ordered = values.toList(growable: false)..sort();
    return ordered;
  }

  Future<String> createOrder({
    required WorkOrderUpsertInput input,
    required String userId,
  }) async {
    final List<WorkOrderProductItem> items = _sanitizeItems(input.items);
    if (items.isEmpty) {
      throw Exception('Debes agregar al menos un producto al pedido.');
    }
    final List<WorkOrderAssignmentItem> assignments =
        _sanitizeAssignments(input.assignments);
    final DateTime now = DateTime.now();
    final DateTime createdAt = input.createdAt;
    final String id = _uuid.v4();
    final String folio = await _nextFolio(createdAt);
    final String? customerName = await _resolveCustomerName(input.customerId);
    final _HeaderSnapshot header = _headerFromCollections(
      title: input.title,
      items: items,
      assignments: assignments,
    );
    final _WorkOrderQuoteSnapshot quoteSnapshot = await _buildQuoteSnapshot(
      items: items,
      tasks: const <WorkOrderTaskItem>[],
    );

    await _db.into(_db.workOrders).insert(
          WorkOrdersCompanion.insert(
            id: id,
            folio: folio,
            customerId: Value(_normalizeOptional(input.customerId)),
            customerNameSnapshot: Value(customerName),
            assignedEmployeeId: Value(header.primaryEmployeeId),
            assignedEmployeeNameSnapshot: Value(header.primaryEmployeeName),
            workType: Value(_normalizeWorkType(input.workType)),
            title: header.title,
            description: Value(_normalizeOptional(input.description)),
            itemsJson: Value(_encodeItems(items)),
            assignmentsJson: Value(_encodeAssignments(assignments)),
            tasksJson: const Value('[]'),
            qty: Value(header.qty),
            unitLabel: Value(header.unitLabel),
            status: Value(_normalizeStatus(input.status)),
            paymentStatus: const Value(WorkOrderPaymentStatusCatalog.unpaid),
            priority: Value(_normalizePriority(input.priority)),
            createdAt: Value(createdAt),
            dueAt: Value(input.dueAt),
            note: Value(_normalizeOptional(input.note)),
            quotedTotalsJson: Value(_encodeCostTotals(quoteSnapshot.totals)),
            quotedRequestedLinesJson:
                Value(_encodeRequestedCostLines(quoteSnapshot.lines)),
            quotedPaymentVariantsJson:
                Value(_encodePaymentValues(quoteSnapshot.paymentValues)),
            pricingSnapshotJson:
                Value(jsonEncode(quoteSnapshot.pricingSnapshot.toJson())),
            paymentLinesJson: const Value('[]'),
            createdBy: userId,
            updatedBy: Value(userId),
            updatedAt: Value(now),
            completedAt: Value(
              _statusCompletedAt(_normalizeStatus(input.status), now),
            ),
            deliveredAt: Value(
              _statusDeliveredAt(_normalizeStatus(input.status), now),
            ),
          ),
        );

    await _logAudit(
      userId: userId,
      action: 'create',
      entityId: id,
      payload: <String, Object?>{
        'folio': folio,
        'items': items.length,
        'assignments': assignments.length,
        'status': _normalizeStatus(input.status),
        'paymentStatus': WorkOrderPaymentStatusCatalog.unpaid,
        'createdAt': createdAt.toIso8601String(),
      },
    );
    return id;
  }

  Future<void> updateOrder({
    required String orderId,
    required WorkOrderUpsertInput input,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final List<WorkOrderProductItem> items = _sanitizeItems(input.items);
    if (items.isEmpty) {
      throw Exception('Debes agregar al menos un producto al pedido.');
    }
    final List<WorkOrderAssignmentItem> assignments =
        _sanitizeAssignments(input.assignments);
    final DateTime now = DateTime.now();
    final String normalizedStatus = _normalizeStatus(input.status);
    final String? customerName = await _resolveCustomerName(input.customerId);
    final _HeaderSnapshot header = _headerFromCollections(
      title: input.title,
      items: items,
      assignments: assignments,
    );
    final List<WorkOrderTaskItem> currentTasks =
        _parseTasks(existing.tasksJson);
    final String nextItemsJson = _encodeItems(items);
    final WorkOrderPricingSnapshot? existingPricingSnapshot =
        _parsePricingSnapshotJson(existing.pricingSnapshotJson);
    final bool shouldRefreshQuote = nextItemsJson !=
            _encodeItems(_parseItems(existing.itemsJson, existing)) ||
        _parseCostTotalsJson(existing.quotedTotalsJson).isEmpty;
    _WorkOrderQuoteSnapshot? quoteSnapshot;
    if (shouldRefreshQuote) {
      quoteSnapshot = existingPricingSnapshot == null
          ? await _buildQuoteSnapshot(
              items: items,
              tasks: currentTasks,
            )
          : await _buildQuoteSnapshotWithPricingSnapshot(
              items: items,
              tasks: currentTasks,
              pricingSnapshot: existingPricingSnapshot,
            );
    }

    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        customerId: Value(_normalizeOptional(input.customerId)),
        customerNameSnapshot: Value(customerName),
        assignedEmployeeId: Value(header.primaryEmployeeId),
        assignedEmployeeNameSnapshot: Value(header.primaryEmployeeName),
        workType: Value(_normalizeWorkType(input.workType)),
        title: Value(header.title),
        description: Value(_normalizeOptional(input.description)),
        itemsJson: Value(nextItemsJson),
        assignmentsJson: Value(_encodeAssignments(assignments)),
        qty: Value(header.qty),
        unitLabel: Value(header.unitLabel),
        status: Value(normalizedStatus),
        priority: Value(_normalizePriority(input.priority)),
        createdAt: Value(input.createdAt),
        dueAt: Value(input.dueAt),
        note: Value(_normalizeOptional(input.note)),
        quotedTotalsJson: quoteSnapshot == null
            ? const Value.absent()
            : Value(_encodeCostTotals(quoteSnapshot.totals)),
        quotedRequestedLinesJson: quoteSnapshot == null
            ? const Value.absent()
            : Value(_encodeRequestedCostLines(quoteSnapshot.lines)),
        quotedPaymentVariantsJson: quoteSnapshot == null
            ? const Value.absent()
            : Value(_encodePaymentValues(quoteSnapshot.paymentValues)),
        pricingSnapshotJson: quoteSnapshot == null
            ? const Value.absent()
            : Value(jsonEncode(quoteSnapshot.pricingSnapshot.toJson())),
        updatedBy: Value(userId),
        updatedAt: Value(now),
        completedAt: Value(
          _statusCompletedAt(
            normalizedStatus,
            now,
            previousValue: existing.completedAt,
          ),
        ),
        deliveredAt: Value(
          _statusDeliveredAt(
            normalizedStatus,
            now,
            previousValue: existing.deliveredAt,
          ),
        ),
      ),
    );

    await _logAudit(
      userId: userId,
      action: 'update',
      entityId: orderId,
      payload: <String, Object?>{
        'status': normalizedStatus,
        'createdAt': input.createdAt.toIso8601String(),
        'items': items.length,
        'assignments': assignments.length,
        'paymentStatus': _normalizePaymentStatus(existing.paymentStatus),
        'quoteRefreshed': shouldRefreshQuote,
      },
    );
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final DateTime now = DateTime.now();
    final String normalizedStatus = _normalizeStatus(status);
    final String previousStatus = _normalizeStatus(existing.status);

    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        status: Value(normalizedStatus),
        updatedBy: Value(userId),
        updatedAt: Value(now),
        completedAt: Value(
          _statusCompletedAt(
            normalizedStatus,
            now,
            previousValue: existing.completedAt,
          ),
        ),
        deliveredAt: Value(
          _statusDeliveredAt(
            normalizedStatus,
            now,
            previousValue: existing.deliveredAt,
          ),
        ),
      ),
    );

    await _logAudit(
      userId: userId,
      action: 'update_status',
      entityId: orderId,
      payload: <String, Object?>{
        'status': normalizedStatus,
        'fromStatus': previousStatus,
      },
    );
  }

  Future<void> updateOrderPaymentStatus({
    required String orderId,
    required String paymentStatus,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final DateTime now = DateTime.now();
    final String normalized = _normalizePaymentStatus(paymentStatus);
    final String previous = _normalizePaymentStatus(existing.paymentStatus);
    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        paymentStatus: Value(normalized),
        paidAt: Value(
          normalized == WorkOrderPaymentStatusCatalog.paid
              ? (existing.paidAt ?? now)
              : null,
        ),
        updatedBy: Value(userId),
        updatedAt: Value(now),
      ),
    );
    await _logAudit(
      userId: userId,
      action: 'update_payment_status',
      entityId: orderId,
      payload: <String, Object?>{
        'paymentStatus': normalized,
        'fromPaymentStatus': previous,
      },
    );
  }

  Future<void> deleteOrder({
    required String orderId,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }

    final List<WorkOrderTaskItem> tasks = _parseTasks(existing.tasksJson);
    await _deleteOrderTaskImages(tasks);

    await (_db.delete(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .go();

    await _logAudit(
      userId: userId,
      action: 'delete',
      entityId: orderId,
      payload: <String, Object?>{
        'folio': existing.folio,
        'status': existing.status,
        'tasks': tasks.length,
      },
    );
  }

  Future<void> addTaskToOrder({
    required String orderId,
    required WorkOrderTaskCreateInput input,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final String title = input.title.trim();
    if (title.isEmpty) {
      throw Exception('El trabajo realizado debe tener un titulo.');
    }
    final List<WorkOrderTaskMaterialItem> materials =
        _sanitizeTaskMaterials(input.materials);
    final List<WorkOrderTaskMaterialItem> wasteMaterials =
        _sanitizeTaskMaterials(input.wasteMaterials);
    final List<WorkOrderTaskWorkerItem> workers =
        _sanitizeTaskWorkers(input.workers);
    final List<String> imagePaths = _sanitizeTaskImagePaths(input.imagePaths);
    final List<WorkOrderTaskItem> tasks =
        _parseTasks(existing.tasksJson).toList(growable: true);
    tasks.add(
      WorkOrderTaskItem(
        id: _uuid.v4(),
        title: title,
        description: _normalizeOptional(input.description),
        createdAt: DateTime.now(),
        materials: materials,
        wasteMaterials: wasteMaterials,
        workers: workers,
        imagePaths: imagePaths,
      ),
    );
    final WorkOrdersCompanion quoteCompanion =
        await _buildQuoteCompanionForOrder(
      existing: existing,
      items: _parseItems(existing.itemsJson, existing),
      tasks: tasks,
    );

    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        tasksJson: Value(_encodeTasks(tasks)),
        quotedTotalsJson: quoteCompanion.quotedTotalsJson,
        quotedRequestedLinesJson: quoteCompanion.quotedRequestedLinesJson,
        quotedPaymentVariantsJson: quoteCompanion.quotedPaymentVariantsJson,
        pricingSnapshotJson: quoteCompanion.pricingSnapshotJson,
        updatedBy: Value(userId),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _logAudit(
      userId: userId,
      action: 'add_task',
      entityId: orderId,
      payload: <String, Object?>{
        'taskTitle': title,
        'materials': materials.length,
        'waste': wasteMaterials.length,
        'workers': workers.length,
        'images': imagePaths.length,
      },
    );
  }

  Future<void> updateTaskInOrder({
    required String orderId,
    required String taskId,
    required WorkOrderTaskCreateInput input,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final String title = input.title.trim();
    if (title.isEmpty) {
      throw Exception('El trabajo realizado debe tener un titulo.');
    }
    final List<WorkOrderTaskMaterialItem> materials =
        _sanitizeTaskMaterials(input.materials);
    final List<WorkOrderTaskMaterialItem> wasteMaterials =
        _sanitizeTaskMaterials(input.wasteMaterials);
    final List<WorkOrderTaskWorkerItem> workers =
        _sanitizeTaskWorkers(input.workers);
    final List<String> imagePaths = _sanitizeTaskImagePaths(input.imagePaths);
    final List<WorkOrderTaskItem> tasks =
        _parseTasks(existing.tasksJson).toList(growable: true);
    final int index =
        tasks.indexWhere((WorkOrderTaskItem task) => task.id == taskId);
    if (index < 0) {
      throw Exception('El trabajo realizado no existe.');
    }
    tasks[index] = tasks[index].copyWith(
      title: title,
      description: _normalizeOptional(input.description),
      materials: materials,
      wasteMaterials: wasteMaterials,
      workers: workers,
      imagePaths: imagePaths,
    );
    final WorkOrdersCompanion quoteCompanion =
        await _buildQuoteCompanionForOrder(
      existing: existing,
      items: _parseItems(existing.itemsJson, existing),
      tasks: tasks,
    );

    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        tasksJson: Value(_encodeTasks(tasks)),
        quotedTotalsJson: quoteCompanion.quotedTotalsJson,
        quotedRequestedLinesJson: quoteCompanion.quotedRequestedLinesJson,
        quotedPaymentVariantsJson: quoteCompanion.quotedPaymentVariantsJson,
        pricingSnapshotJson: quoteCompanion.pricingSnapshotJson,
        updatedBy: Value(userId),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _logAudit(
      userId: userId,
      action: 'update_task',
      entityId: orderId,
      payload: <String, Object?>{
        'taskId': taskId,
        'taskTitle': title,
        'materials': materials.length,
        'waste': wasteMaterials.length,
        'workers': workers.length,
        'images': imagePaths.length,
      },
    );
  }

  Future<void> deleteTaskFromOrder({
    required String orderId,
    required String taskId,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final List<WorkOrderTaskItem> tasks =
        _parseTasks(existing.tasksJson).toList(growable: true);
    final int index =
        tasks.indexWhere((WorkOrderTaskItem task) => task.id == taskId);
    if (index < 0) {
      throw Exception('El trabajo realizado no existe.');
    }
    tasks.removeAt(index);
    final WorkOrdersCompanion quoteCompanion =
        await _buildQuoteCompanionForOrder(
      existing: existing,
      items: _parseItems(existing.itemsJson, existing),
      tasks: tasks,
    );

    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        tasksJson: Value(_encodeTasks(tasks)),
        quotedTotalsJson: quoteCompanion.quotedTotalsJson,
        quotedRequestedLinesJson: quoteCompanion.quotedRequestedLinesJson,
        quotedPaymentVariantsJson: quoteCompanion.quotedPaymentVariantsJson,
        pricingSnapshotJson: quoteCompanion.pricingSnapshotJson,
        updatedBy: Value(userId),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _logAudit(
      userId: userId,
      action: 'delete_task',
      entityId: orderId,
      payload: <String, Object?>{
        'taskId': taskId,
      },
    );
  }

  Future<void> updateTaskImages({
    required String orderId,
    required String taskId,
    required List<String> imagePaths,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final List<WorkOrderTaskItem> tasks =
        _parseTasks(existing.tasksJson).toList(growable: true);
    final int index =
        tasks.indexWhere((WorkOrderTaskItem task) => task.id == taskId);
    if (index < 0) {
      throw Exception('El trabajo realizado no existe.');
    }
    final List<String> sanitized = _sanitizeTaskImagePaths(imagePaths);
    tasks[index] = tasks[index].copyWith(imagePaths: sanitized);
    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        tasksJson: Value(_encodeTasks(tasks)),
        updatedBy: Value(userId),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _logAudit(
      userId: userId,
      action: 'update_task_images',
      entityId: orderId,
      payload: <String, Object?>{
        'taskId': taskId,
        'images': sanitized.length,
      },
    );
  }

  Future<void> _deleteOrderTaskImages(List<WorkOrderTaskItem> tasks) async {
    final Set<String> allPaths = tasks
        .expand((WorkOrderTaskItem task) => task.imagePaths)
        .map((String path) => path.trim())
        .where((String path) => path.isNotEmpty)
        .toSet();

    for (final String path in allPaths) {
      try {
        final File file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best effort cleanup; the order deletion should not fail because of
        // leftover local evidence files.
      }
    }
  }

  List<WorkOrderProductItem> _sanitizeItems(List<WorkOrderProductItem> raw) {
    final List<WorkOrderProductItem> items = <WorkOrderProductItem>[];
    for (final WorkOrderProductItem item in raw) {
      final String name = item.productName.trim();
      final String unit = item.unitLabel.trim();
      if (name.isEmpty || unit.isEmpty || item.qty <= 0) {
        continue;
      }
      items.add(
        WorkOrderProductItem(
          productId: _normalizeOptional(item.productId),
          productName: name,
          productSku:
              item.productSku.trim().isEmpty ? '-' : item.productSku.trim(),
          unitLabel: unit,
          qty: item.qty,
        ),
      );
    }

    return items;
  }

  Future<void> updateOrderPaymentDetails({
    required String orderId,
    required WorkOrderPaymentUpdateInput input,
    required String userId,
  }) async {
    final WorkOrder? existing = await (_db.select(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El pedido no existe.');
    }
    final DateTime now = DateTime.now();
    final List<WorkOrderRecordedPaymentLine> lines =
        _sanitizePaymentLines(input.paymentLines);
    final String normalizedStatus = lines.isEmpty
        ? WorkOrderPaymentStatusCatalog.unpaid
        : WorkOrderPaymentStatusCatalog.paid;
    final WorkOrderPricingSnapshot pricingSnapshot =
        _normalizePricingSnapshot(input.pricingSnapshot);
    final List<WorkOrderCostTotal> quotedTotals =
        _parseCostTotalsJson(existing.quotedTotalsJson);
    final List<WorkOrderTaskItem> currentTasks =
        _parseTasks(existing.tasksJson);
    final List<WorkOrderProductItem> items =
        _parseItems(existing.itemsJson, existing);
    final _RequestedOrderCostSummary requestedCostSummary = quotedTotals.isEmpty
        ? await _buildRequestedOrderCostSummary(
            items: items,
            tasks: currentTasks,
          )
        : const _RequestedOrderCostSummary(
            lines: <WorkOrderRequestedCostLine>[],
            totals: <WorkOrderCostTotal>[],
          );
    final List<WorkOrderCostTotal> sourceTotals =
        quotedTotals.isEmpty ? requestedCostSummary.totals : quotedTotals;
    final List<WorkOrderPaymentValue> paymentValues =
        _buildPaymentValuesFromSnapshot(
      totals: sourceTotals,
      pricingSnapshot: pricingSnapshot,
    );
    final DateTime? paidAt =
        lines.isEmpty ? null : (input.paidAt ?? lines.last.paidAt);

    await (_db.update(_db.workOrders)
          ..where((WorkOrders tbl) => tbl.id.equals(orderId)))
        .write(
      WorkOrdersCompanion(
        paymentStatus: Value(normalizedStatus),
        pricingSnapshotJson: Value(jsonEncode(pricingSnapshot.toJson())),
        quotedPaymentVariantsJson: Value(_encodePaymentValues(paymentValues)),
        paymentLinesJson: Value(_encodePaymentLines(lines)),
        paidAt: Value(paidAt),
        updatedBy: Value(userId),
        updatedAt: Value(now),
      ),
    );

    await _logAudit(
      userId: userId,
      action: 'update_payment_details',
      entityId: orderId,
      payload: <String, Object?>{
        'paymentStatus': normalizedStatus,
        'fromPaymentStatus': _normalizePaymentStatus(existing.paymentStatus),
        'paidAt': paidAt?.toIso8601String(),
        'paymentLines': lines.length,
        'pricingSnapshot': pricingSnapshot.toJson(),
      },
    );
  }

  List<WorkOrderAssignmentItem> _sanitizeAssignments(
    List<WorkOrderAssignmentItem> raw,
  ) {
    final List<WorkOrderAssignmentItem> values = <WorkOrderAssignmentItem>[];
    final Set<String> employeeIds = <String>{};
    for (final WorkOrderAssignmentItem item in raw) {
      final String employeeId = item.employeeId.trim();
      final String role = item.roleName.trim();
      if (employeeId.isEmpty ||
          role.isEmpty ||
          employeeIds.contains(employeeId)) {
        continue;
      }
      employeeIds.add(employeeId);
      values.add(
        WorkOrderAssignmentItem(
          employeeId: employeeId,
          employeeName: item.employeeName.trim().isEmpty
              ? 'Empleado'
              : item.employeeName.trim(),
          employeeCode:
              item.employeeCode.trim().isEmpty ? '-' : item.employeeCode.trim(),
          roleName: role,
          employeeImagePath: _normalizeOptional(item.employeeImagePath),
        ),
      );
    }
    return values;
  }

  List<WorkOrderTaskMaterialItem> _sanitizeTaskMaterials(
    List<WorkOrderTaskMaterialItem> raw,
  ) {
    final List<WorkOrderTaskMaterialItem> values =
        <WorkOrderTaskMaterialItem>[];
    for (final WorkOrderTaskMaterialItem item in raw) {
      final String productId = item.productId.trim();
      final String name = item.productName.trim();
      final String unit = item.unitLabel.trim();
      if (productId.isEmpty || name.isEmpty || unit.isEmpty || item.qty <= 0) {
        continue;
      }
      values.add(
        WorkOrderTaskMaterialItem(
          productId: productId,
          productName: name,
          productSku:
              item.productSku.trim().isEmpty ? '-' : item.productSku.trim(),
          unitLabel: unit,
          qty: item.qty,
          widthMeters: item.widthMeters,
          heightMeters: item.heightMeters,
          areaSqm: item.areaSqm,
        ),
      );
    }
    return values;
  }

  List<WorkOrderTaskWorkerItem> _sanitizeTaskWorkers(
    List<WorkOrderTaskWorkerItem> raw,
  ) {
    final List<WorkOrderTaskWorkerItem> values = <WorkOrderTaskWorkerItem>[];
    final Set<String> employeeIds = <String>{};
    for (final WorkOrderTaskWorkerItem item in raw) {
      final String employeeId = item.employeeId.trim();
      final String role = item.roleName.trim();
      if (employeeId.isEmpty ||
          role.isEmpty ||
          employeeIds.contains(employeeId)) {
        continue;
      }
      employeeIds.add(employeeId);
      values.add(
        WorkOrderTaskWorkerItem(
          employeeId: employeeId,
          employeeName: item.employeeName.trim().isEmpty
              ? 'Empleado'
              : item.employeeName.trim(),
          employeeCode:
              item.employeeCode.trim().isEmpty ? '-' : item.employeeCode.trim(),
          roleName: role,
          employeeImagePath: _normalizeOptional(item.employeeImagePath),
        ),
      );
    }
    return values;
  }

  List<String> _sanitizeTaskImagePaths(List<String> raw) {
    final Set<String> unique = <String>{};
    for (final String path in raw) {
      final String normalized = path.trim();
      if (normalized.isNotEmpty) {
        unique.add(normalized);
      }
    }
    return unique.toList(growable: false);
  }

  List<WorkOrderProductItem> _parseItems(String raw, WorkOrder fallback) {
    final List<Map<String, Object?>> maps = _decodeList(raw);
    if (maps.isNotEmpty) {
      return maps
          .map(WorkOrderProductItem.fromJson)
          .where(
              (WorkOrderProductItem item) => item.productName.trim().isNotEmpty)
          .toList(growable: false);
    }
    final String title = fallback.title.trim();
    if (title.isEmpty) {
      return const <WorkOrderProductItem>[];
    }
    return <WorkOrderProductItem>[
      WorkOrderProductItem(
        productId: null,
        productName: title,
        productSku: '-',
        unitLabel: fallback.unitLabel,
        qty: fallback.qty,
      ),
    ];
  }

  List<WorkOrderAssignmentItem> _parseAssignments(
    String raw, {
    required WorkOrder fallback,
  }) {
    final List<Map<String, Object?>> maps = _decodeList(raw);
    if (maps.isNotEmpty) {
      return maps
          .map(WorkOrderAssignmentItem.fromJson)
          .where((WorkOrderAssignmentItem item) =>
              item.employeeId.trim().isNotEmpty)
          .toList(growable: false);
    }
    final String employeeId = (fallback.assignedEmployeeId ?? '').trim();
    final String employeeName =
        (fallback.assignedEmployeeNameSnapshot ?? '').trim();
    if (employeeId.isEmpty && employeeName.isEmpty) {
      return const <WorkOrderAssignmentItem>[];
    }
    return <WorkOrderAssignmentItem>[
      WorkOrderAssignmentItem(
        employeeId: employeeId,
        employeeName: employeeName.isEmpty ? 'Empleado' : employeeName,
        employeeCode: '-',
        roleName: 'Responsable',
      ),
    ];
  }

  List<WorkOrderTaskItem> _parseTasks(String raw) {
    final List<Map<String, Object?>> maps = _decodeList(raw);
    return maps.map(WorkOrderTaskItem.fromJson).toList(growable: true);
  }

  List<Map<String, Object?>> _decodeList(String raw) {
    final String clean = raw.trim();
    if (clean.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    try {
      final Object? decoded = jsonDecode(clean);
      return _listOfMaps(decoded);
    } catch (_) {
      return const <Map<String, Object?>>[];
    }
  }

  String _encodeItems(List<WorkOrderProductItem> items) {
    return jsonEncode(
      items.map((WorkOrderProductItem item) => item.toJson()).toList(),
    );
  }

  String _encodeAssignments(List<WorkOrderAssignmentItem> assignments) {
    return jsonEncode(
      assignments.map((WorkOrderAssignmentItem item) => item.toJson()).toList(),
    );
  }

  String _encodeTasks(List<WorkOrderTaskItem> tasks) {
    return jsonEncode(
      tasks.map((WorkOrderTaskItem item) => item.toJson()).toList(),
    );
  }

  List<WorkOrderTaskTypeModel> _defaultTaskTypes() {
    return _normalizeTaskTypes(
      const <WorkOrderTaskTypeModel>[
        WorkOrderTaskTypeModel(
          id: 'task-type-design',
          name: 'Diseno',
          description: 'Preparación y ajuste del arte final.',
          isSystem: true,
          isActive: true,
          sortOrder: 0,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-print',
          name: 'Impresion',
          description: 'Proceso de impresión del material.',
          isSystem: true,
          isActive: true,
          sortOrder: 1,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-cut',
          name: 'Corte',
          description: 'Recorte y dimensionado de piezas.',
          isSystem: true,
          isActive: true,
          sortOrder: 2,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-laminate',
          name: 'Laminado',
          description: 'Protección o acabado laminado.',
          isSystem: true,
          isActive: true,
          sortOrder: 3,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-die-cut',
          name: 'Troquelado',
          description: 'Corte especial con troquel.',
          isSystem: true,
          isActive: true,
          sortOrder: 4,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-glue',
          name: 'Pegado',
          description: 'Unión o fijación de piezas.',
          isSystem: true,
          isActive: true,
          sortOrder: 5,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-assembly',
          name: 'Ensamblado',
          description: 'Montaje y armado del pedido.',
          isSystem: true,
          isActive: true,
          sortOrder: 6,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-finish',
          name: 'Acabado',
          description: 'Terminación final del producto.',
          isSystem: true,
          isActive: true,
          sortOrder: 7,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-pack',
          name: 'Empaque',
          description: 'Preparación para entrega o almacenaje.',
          isSystem: true,
          isActive: true,
          sortOrder: 8,
        ),
        WorkOrderTaskTypeModel(
          id: 'task-type-partial-delivery',
          name: 'Entrega parcial',
          description: 'Salida parcial del pedido al cliente.',
          isSystem: true,
          isActive: true,
          sortOrder: 9,
        ),
      ],
    );
  }

  List<WorkOrderTaskWorkerRoleModel> _defaultTaskWorkerRoles() {
    return _normalizeTaskWorkerRoles(
      const <WorkOrderTaskWorkerRoleModel>[
        WorkOrderTaskWorkerRoleModel(
          id: 'task-worker-role-designer',
          name: 'Disenador',
          description: 'Prepara y ajusta el arte final del pedido.',
          isSystem: true,
          isActive: true,
          sortOrder: 0,
        ),
        WorkOrderTaskWorkerRoleModel(
          id: 'task-worker-role-printer',
          name: 'Impresor',
          description: 'Opera el proceso de impresión del trabajo.',
          isSystem: true,
          isActive: true,
          sortOrder: 1,
        ),
        WorkOrderTaskWorkerRoleModel(
          id: 'task-worker-role-cutter',
          name: 'Cortador',
          description: 'Realiza corte y dimensionado del material.',
          isSystem: true,
          isActive: true,
          sortOrder: 2,
        ),
        WorkOrderTaskWorkerRoleModel(
          id: 'task-worker-role-finisher',
          name: 'Acabador',
          description: 'Se encarga del acabado y terminación final.',
          isSystem: true,
          isActive: true,
          sortOrder: 3,
        ),
        WorkOrderTaskWorkerRoleModel(
          id: 'task-worker-role-installer',
          name: 'Instalador',
          description: 'Participa en montaje o instalación del pedido.',
          isSystem: true,
          isActive: true,
          sortOrder: 4,
        ),
        WorkOrderTaskWorkerRoleModel(
          id: 'task-worker-role-helper',
          name: 'Auxiliar',
          description: 'Brinda apoyo operativo al proceso productivo.',
          isSystem: true,
          isActive: true,
          sortOrder: 5,
        ),
        WorkOrderTaskWorkerRoleModel(
          id: 'task-worker-role-supervisor',
          name: 'Supervisor',
          description: 'Valida la calidad y supervisa la ejecución.',
          isSystem: true,
          isActive: true,
          sortOrder: 6,
        ),
      ],
    );
  }

  List<WorkOrderTaskTypeModel> _normalizeTaskTypes(
    List<WorkOrderTaskTypeModel> raw,
  ) {
    final List<WorkOrderTaskTypeModel> values = <WorkOrderTaskTypeModel>[];
    final Set<String> seenIds = <String>{};
    final Set<String> seenNames = <String>{};
    for (final WorkOrderTaskTypeModel row in raw) {
      final String cleanId = row.id.trim();
      final String cleanName = row.name.trim();
      if (cleanId.isEmpty ||
          cleanName.isEmpty ||
          !seenIds.add(cleanId) ||
          !seenNames.add(cleanName.toLowerCase())) {
        continue;
      }
      values.add(
        row.copyWith(
          id: cleanId,
          name: cleanName,
          description: row.description.trim(),
        ),
      );
    }
    values.sort((WorkOrderTaskTypeModel a, WorkOrderTaskTypeModel b) {
      final int byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) {
        return byOrder;
      }
      return a.name.compareTo(b.name);
    });
    return values;
  }

  List<WorkOrderTaskWorkerRoleModel> _normalizeTaskWorkerRoles(
    List<WorkOrderTaskWorkerRoleModel> raw,
  ) {
    final List<WorkOrderTaskWorkerRoleModel> values =
        <WorkOrderTaskWorkerRoleModel>[];
    final Set<String> seenIds = <String>{};
    final Set<String> seenNames = <String>{};
    for (final WorkOrderTaskWorkerRoleModel row in raw) {
      final String cleanId = row.id.trim();
      final String cleanName = row.name.trim();
      if (cleanId.isEmpty ||
          cleanName.isEmpty ||
          !seenIds.add(cleanId) ||
          !seenNames.add(cleanName.toLowerCase())) {
        continue;
      }
      values.add(
        row.copyWith(
          id: cleanId,
          name: cleanName,
          description: row.description.trim(),
        ),
      );
    }
    values
        .sort((WorkOrderTaskWorkerRoleModel a, WorkOrderTaskWorkerRoleModel b) {
      final int byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) {
        return byOrder;
      }
      return a.name.compareTo(b.name);
    });
    return values;
  }

  List<WorkOrderTaskTypeModel> _mergeDefaultTaskTypes(
    List<WorkOrderTaskTypeModel> catalog,
  ) {
    final List<WorkOrderTaskTypeModel> defaults = _defaultTaskTypes();
    final List<WorkOrderTaskTypeModel> merged = catalog.toList(growable: true);
    final Set<String> existingIds = merged
        .map((WorkOrderTaskTypeModel row) => row.id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    final Set<String> existingNames = merged
        .map((WorkOrderTaskTypeModel row) => row.name.trim().toLowerCase())
        .where((String name) => name.isNotEmpty)
        .toSet();
    for (final WorkOrderTaskTypeModel row in defaults) {
      if (existingIds.contains(row.id) ||
          existingNames.contains(row.name.trim().toLowerCase())) {
        continue;
      }
      merged.add(row);
      existingIds.add(row.id);
      existingNames.add(row.name.trim().toLowerCase());
    }
    return _normalizeTaskTypes(merged);
  }

  List<WorkOrderTaskWorkerRoleModel> _mergeDefaultTaskWorkerRoles(
    List<WorkOrderTaskWorkerRoleModel> catalog,
  ) {
    final List<WorkOrderTaskWorkerRoleModel> defaults =
        _defaultTaskWorkerRoles();
    final List<WorkOrderTaskWorkerRoleModel> merged =
        catalog.toList(growable: true);
    final Set<String> existingIds = merged
        .map((WorkOrderTaskWorkerRoleModel row) => row.id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    final Set<String> existingNames = merged
        .map(
            (WorkOrderTaskWorkerRoleModel row) => row.name.trim().toLowerCase())
        .where((String name) => name.isNotEmpty)
        .toSet();
    for (final WorkOrderTaskWorkerRoleModel row in defaults) {
      if (existingIds.contains(row.id) ||
          existingNames.contains(row.name.trim().toLowerCase())) {
        continue;
      }
      merged.add(row);
      existingIds.add(row.id);
      existingNames.add(row.name.trim().toLowerCase());
    }
    return _normalizeTaskWorkerRoles(merged);
  }

  Future<void> _saveTaskTypesCatalog(
      List<WorkOrderTaskTypeModel> catalog) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _taskTypesCatalogKey,
            value: jsonEncode(
              catalog
                  .map((WorkOrderTaskTypeModel row) => row.toJson())
                  .toList(growable: false),
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _saveTaskWorkerRolesCatalog(
    List<WorkOrderTaskWorkerRoleModel> catalog,
  ) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _taskWorkerRolesCatalogKey,
            value: jsonEncode(
              catalog
                  .map((WorkOrderTaskWorkerRoleModel row) => row.toJson())
                  .toList(growable: false),
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<String?> _resolveCustomerName(String? customerId) async {
    final String? clean = _normalizeOptional(customerId);
    if (clean == null) {
      return null;
    }
    final Customer? customer = await (_db.select(_db.customers)
          ..where((Customers tbl) => tbl.id.equals(clean)))
        .getSingleOrNull();
    return customer?.fullName.trim().isEmpty == true
        ? null
        : customer?.fullName;
  }

  _HeaderSnapshot _headerFromCollections({
    required String title,
    required List<WorkOrderProductItem> items,
    required List<WorkOrderAssignmentItem> assignments,
  }) {
    final WorkOrderProductItem firstItem = items.first;
    final WorkOrderAssignmentItem? firstAssignment =
        assignments.isEmpty ? null : assignments.first;
    final String computedTitle = title.trim().isNotEmpty
        ? title.trim()
        : items.length == 1
            ? firstItem.productName
            : '${firstItem.productName} y ${items.length - 1} más';
    final double qty =
        items.length == 1 ? firstItem.qty : items.length.toDouble();
    final String unitLabel = items.length == 1 ? firstItem.unitLabel : 'items';
    return _HeaderSnapshot(
      title: computedTitle,
      qty: qty,
      unitLabel: unitLabel,
      primaryEmployeeId: firstAssignment?.employeeId,
      primaryEmployeeName: firstAssignment?.employeeName,
    );
  }

  String _buildItemSummary(List<WorkOrderProductItem> items) {
    if (items.isEmpty) {
      return 'Sin productos';
    }
    if (items.length == 1) {
      final WorkOrderProductItem first = items.first;
      return '${first.productName} · ${_qty(first.qty)} ${first.unitLabel}';
    }
    return '${items.first.productName} y ${items.length - 1} productos más';
  }

  String _buildAssignmentSummary(List<WorkOrderAssignmentItem> assignments) {
    if (assignments.isEmpty) {
      return 'Sin asignar';
    }
    if (assignments.length == 1) {
      final WorkOrderAssignmentItem first = assignments.first;
      return '${first.employeeName} · ${first.roleName}';
    }
    return '${assignments.length} trabajadores asignados';
  }

  String _displayTitle(String title, List<WorkOrderProductItem> items) {
    final String clean = title.trim();
    if (clean.isNotEmpty) {
      return clean;
    }
    if (items.isEmpty) {
      return 'Pedido';
    }
    if (items.length == 1) {
      return items.first.productName;
    }
    return '${items.first.productName} y ${items.length - 1} más';
  }

  String _normalizeCatalogValue(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.length == 1) {
      return trimmed.toUpperCase();
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  DateTime? _statusCompletedAt(
    String status,
    DateTime now, {
    DateTime? previousValue,
  }) {
    if (status == WorkOrderStatusCatalog.ready ||
        status == WorkOrderStatusCatalog.delivered) {
      return previousValue ?? now;
    }
    return null;
  }

  DateTime? _statusDeliveredAt(
    String status,
    DateTime now, {
    DateTime? previousValue,
  }) {
    if (status == WorkOrderStatusCatalog.delivered) {
      return previousValue ?? now;
    }
    return null;
  }

  bool _matchesOrderDateRange(
    WorkOrder row, {
    required List<WorkOrderTaskItem> tasks,
    required DateTime? from,
    required DateTime? to,
    required String criterion,
  }) {
    if (from == null && to == null) {
      return true;
    }
    switch (criterion.trim()) {
      case WorkOrderDateFilterCriterion.taskCreatedAt:
        for (final WorkOrderTaskItem task in tasks) {
          if (_isInDateRange(task.createdAt, from: from, to: to)) {
            return true;
          }
        }
        return false;
      case WorkOrderDateFilterCriterion.dueAt:
        return _isInDateRange(row.dueAt, from: from, to: to);
      case WorkOrderDateFilterCriterion.createdAt:
      default:
        return _isInDateRange(row.createdAt, from: from, to: to);
    }
  }

  bool _isInDateRange(
    DateTime? value, {
    required DateTime? from,
    required DateTime? to,
  }) {
    if (value == null) {
      return false;
    }
    final DateTime target = value.toLocal();
    if (from != null && target.isBefore(from)) {
      return false;
    }
    if (to != null && !target.isBefore(to)) {
      return false;
    }
    return true;
  }

  Future<_WorkOrderCostSummary> _buildMaterialCostSummary(
    List<WorkOrderTaskItem> tasks,
  ) async {
    final Set<String> productIds = <String>{};
    for (final WorkOrderTaskItem task in tasks) {
      for (final WorkOrderTaskMaterialItem item in task.materials) {
        final String id = item.productId.trim();
        if (id.isNotEmpty) {
          productIds.add(id);
        }
      }
      for (final WorkOrderTaskMaterialItem item in task.wasteMaterials) {
        final String id = item.productId.trim();
        if (id.isNotEmpty) {
          productIds.add(id);
        }
      }
    }

    final Map<String, Product> productsById = <String, Product>{};
    if (productIds.isNotEmpty) {
      final List<Product> productRows = await (_db.select(_db.products)
            ..where((Products tbl) => tbl.id.isIn(productIds)))
          .get();
      for (final Product row in productRows) {
        productsById[row.id] = row;
      }
    }

    final Map<String, _MaterialCostAccumulator> grouped =
        <String, _MaterialCostAccumulator>{};
    final Map<String, int> totalsByCurrency = <String, int>{};

    void accumulate(
      WorkOrderTaskMaterialItem item, {
      required bool isWaste,
    }) {
      final Product? product = productsById[item.productId.trim()];
      final String currencyCode = (product?.currencyCode ?? 'USD').trim();
      final int unitCostCents = product?.costPriceCents ?? 0;
      final String key =
          '${item.productId}|${item.productName}|${item.unitLabel}|$currencyCode';
      final _MaterialCostAccumulator row = grouped.putIfAbsent(
        key,
        () => _MaterialCostAccumulator(
          productId: item.productId.trim().isEmpty ? null : item.productId,
          productName: item.productName,
          productSku: item.productSku,
          unitLabel: item.unitLabel,
          currencyCode: currencyCode,
          unitCostCents: unitCostCents,
        ),
      );
      row.unitCostCents = unitCostCents;
      final double qty = _roundTo2(item.qty);
      final int lineCostCents = (qty * unitCostCents).round();
      if (isWaste) {
        row.wasteQty = _roundTo2(row.wasteQty + qty);
        row.wasteCostCents += lineCostCents;
      } else {
        row.usedQty = _roundTo2(row.usedQty + qty);
        row.usedCostCents += lineCostCents;
      }
      totalsByCurrency.update(
        currencyCode,
        (int value) => value + lineCostCents,
        ifAbsent: () => lineCostCents,
      );
    }

    for (final WorkOrderTaskItem task in tasks) {
      for (final WorkOrderTaskMaterialItem item in task.materials) {
        accumulate(item, isWaste: false);
      }
      for (final WorkOrderTaskMaterialItem item in task.wasteMaterials) {
        accumulate(item, isWaste: true);
      }
    }

    final List<WorkOrderMaterialCostLine> lines = grouped.values
        .map(
          (_MaterialCostAccumulator row) => WorkOrderMaterialCostLine(
            productId: row.productId,
            productName: row.productName,
            productSku: row.productSku,
            unitLabel: row.unitLabel,
            currencyCode: row.currencyCode,
            unitCostCents: row.unitCostCents,
            usedQty: row.usedQty,
            wasteQty: row.wasteQty,
            totalQty: row.usedQty + row.wasteQty,
            usedCostCents: row.usedCostCents,
            wasteCostCents: row.wasteCostCents,
            totalCostCents: row.usedCostCents + row.wasteCostCents,
          ),
        )
        .toList()
      ..sort(
        (WorkOrderMaterialCostLine a, WorkOrderMaterialCostLine b) {
          final int byCost = b.totalCostCents.compareTo(a.totalCostCents);
          if (byCost != 0) {
            return byCost;
          }
          return a.productName.compareTo(b.productName);
        },
      );

    final List<WorkOrderCostTotal> totals = totalsByCurrency.entries
        .map(
          (MapEntry<String, int> entry) => WorkOrderCostTotal(
            currencyCode: entry.key,
            totalCostCents: entry.value,
          ),
        )
        .toList()
      ..sort(
        (WorkOrderCostTotal a, WorkOrderCostTotal b) =>
            a.currencyCode.compareTo(b.currencyCode),
      );

    return _WorkOrderCostSummary(
      lines: lines,
      totals: totals,
    );
  }

  Future<_RequestedOrderCostSummary> _buildRequestedOrderCostSummary({
    required List<WorkOrderProductItem> items,
    required List<WorkOrderTaskItem> tasks,
  }) async {
    final Set<String> productIds = items
        .map((WorkOrderProductItem item) => item.productId?.trim() ?? '')
        .where((String id) => id.isNotEmpty)
        .toSet();
    for (final WorkOrderTaskItem task in tasks) {
      for (final WorkOrderTaskMaterialItem item in task.materials) {
        final String productId = item.productId.trim();
        if (productId.isNotEmpty) {
          productIds.add(productId);
        }
      }
    }

    final Map<String, Product> productsById = <String, Product>{};
    if (productIds.isNotEmpty) {
      final List<Product> productRows = await (_db.select(_db.products)
            ..where((Products tbl) => tbl.id.isIn(productIds)))
          .get();
      for (final Product row in productRows) {
        productsById[row.id] = row;
      }
    }

    final double consumedSurfaceQty = _sumConsumedSurfaceQty(tasks);
    final List<WorkOrderRequestedCostLine> lines =
        <WorkOrderRequestedCostLine>[];
    final Map<String, int> totalsByCurrency = <String, int>{};

    for (final WorkOrderProductItem item in items) {
      final Product? product =
          item.productId == null ? null : productsById[item.productId!.trim()];
      final String currencyCode =
          (product?.currencyCode ?? 'USD').trim().toUpperCase();
      final int unitCostCents = product?.priceCents ?? 0;
      final String costingMode = ProductOrderCostingModeCatalog.normalize(
        product?.orderCostingMode,
      );
      final bool usesConsumedQty =
          costingMode == ProductOrderCostingModeCatalog.consumedArea &&
              consumedSurfaceQty > 0;
      final double billedQty =
          _roundTo2(usesConsumedQty ? consumedSurfaceQty : item.qty);
      final int totalCostCents = (billedQty * unitCostCents).round();
      totalsByCurrency.update(
        currencyCode,
        (int value) => value + totalCostCents,
        ifAbsent: () => totalCostCents,
      );
      lines.add(
        WorkOrderRequestedCostLine(
          productId: item.productId,
          productName: item.productName,
          productSku: item.productSku,
          unitLabel: item.unitLabel,
          currencyCode: currencyCode,
          unitCostCents: unitCostCents,
          orderedQty: _roundTo2(item.qty),
          billedQty: billedQty,
          totalCostCents: totalCostCents,
          usesConsumedQty: usesConsumedQty,
        ),
      );
    }

    final Map<String, _RequestedLineAccumulator> serviceExtras =
        <String, _RequestedLineAccumulator>{};
    for (final WorkOrderTaskItem task in tasks) {
      for (final WorkOrderTaskMaterialItem item in task.materials) {
        final Product? product = productsById[item.productId.trim()];
        if (!_isServiceProduct(product)) {
          continue;
        }
        final String currencyCode =
            (product?.currencyCode ?? 'USD').trim().toUpperCase();
        final int unitPriceCents = product?.priceCents ?? 0;
        final double billedQty = _roundTo2(item.qty);
        if (billedQty <= 0) {
          continue;
        }
        final String key =
            '${item.productId}|${item.productName}|${item.unitLabel}|$currencyCode';
        final _RequestedLineAccumulator row = serviceExtras.putIfAbsent(
          key,
          () => _RequestedLineAccumulator(
            productId: item.productId.trim().isEmpty ? null : item.productId,
            productName: item.productName,
            productSku: item.productSku,
            unitLabel: item.unitLabel,
            currencyCode: currencyCode,
            unitPriceCents: unitPriceCents,
          ),
        );
        row.unitPriceCents = unitPriceCents;
        row.qty = _roundTo2(row.qty + billedQty);
      }
    }

    for (final _RequestedLineAccumulator row in serviceExtras.values) {
      final int totalCostCents = (row.qty * row.unitPriceCents).round();
      totalsByCurrency.update(
        row.currencyCode,
        (int value) => value + totalCostCents,
        ifAbsent: () => totalCostCents,
      );
      lines.add(
        WorkOrderRequestedCostLine(
          productId: row.productId,
          productName: row.productName,
          productSku: row.productSku,
          unitLabel: row.unitLabel,
          currencyCode: row.currencyCode,
          unitCostCents: row.unitPriceCents,
          orderedQty: row.qty,
          billedQty: row.qty,
          totalCostCents: totalCostCents,
          usesConsumedQty: false,
        ),
      );
    }

    lines.sort((WorkOrderRequestedCostLine a, WorkOrderRequestedCostLine b) {
      final int byCost = b.totalCostCents.compareTo(a.totalCostCents);
      if (byCost != 0) {
        return byCost;
      }
      return a.productName.compareTo(b.productName);
    });

    final List<WorkOrderCostTotal> totals = totalsByCurrency.entries
        .map(
          (MapEntry<String, int> entry) => WorkOrderCostTotal(
            currencyCode: entry.key,
            totalCostCents: entry.value,
          ),
        )
        .toList()
      ..sort(
        (WorkOrderCostTotal a, WorkOrderCostTotal b) =>
            a.currencyCode.compareTo(b.currencyCode),
      );

    return _RequestedOrderCostSummary(
      lines: lines,
      totals: totals,
    );
  }

  Future<WorkOrdersCompanion> _buildQuoteCompanionForOrder({
    required WorkOrder existing,
    required List<WorkOrderProductItem> items,
    required List<WorkOrderTaskItem> tasks,
  }) async {
    final WorkOrderPricingSnapshot? existingPricingSnapshot =
        _parsePricingSnapshotJson(existing.pricingSnapshotJson);
    final _WorkOrderQuoteSnapshot quoteSnapshot =
        existingPricingSnapshot == null
            ? await _buildQuoteSnapshot(
                items: items,
                tasks: tasks,
              )
            : await _buildQuoteSnapshotWithPricingSnapshot(
                items: items,
                tasks: tasks,
                pricingSnapshot: existingPricingSnapshot,
              );
    return WorkOrdersCompanion(
      quotedTotalsJson: Value(_encodeCostTotals(quoteSnapshot.totals)),
      quotedRequestedLinesJson: Value(
        _encodeRequestedCostLines(quoteSnapshot.lines),
      ),
      quotedPaymentVariantsJson: Value(
        _encodePaymentValues(quoteSnapshot.paymentValues),
      ),
      pricingSnapshotJson: Value(
        jsonEncode(quoteSnapshot.pricingSnapshot.toJson()),
      ),
    );
  }

  Future<_WorkOrderQuoteSnapshot> _buildQuoteSnapshot({
    required List<WorkOrderProductItem> items,
    required List<WorkOrderTaskItem> tasks,
  }) async {
    final _RequestedOrderCostSummary requested =
        await _buildRequestedOrderCostSummary(
      items: items,
      tasks: tasks,
    );
    final ConfiguracionLocalDataSource configDs =
        ConfiguracionLocalDataSource(_db);
    final AppCurrencyConfig currencyConfig =
        await configDs.loadCurrencyConfig();
    final WorkOrderPaymentDisplayConfig paymentConfig =
        await configDs.loadWorkOrderPaymentDisplayConfig();
    final WorkOrderPricingSnapshot pricingSnapshot = WorkOrderPricingSnapshot(
      capturedAt: DateTime.now(),
      primaryCurrencyCode: currencyConfig.primaryCurrencyCode,
      localCurrencyCode: paymentConfig.localCurrencyCode,
      foreignCurrencyCode: paymentConfig.foreignCurrencyCode,
      localCashFixedSurcharge: paymentConfig.localCashFixedSurcharge,
      localTransferPercentSurcharge:
          paymentConfig.localTransferPercentSurcharge,
      ratesByCode: <String, double>{
        for (final AppCurrencySetting row in currencyConfig.currencies)
          row.code.trim().toUpperCase(): row.rateToPrimary,
      },
    );
    final List<WorkOrderPaymentValue> paymentValues =
        _buildPaymentValuesFromSnapshot(
      totals: requested.totals,
      pricingSnapshot: pricingSnapshot,
    );
    return _WorkOrderQuoteSnapshot(
      lines: requested.lines,
      totals: requested.totals,
      paymentValues: paymentValues,
      pricingSnapshot: pricingSnapshot,
    );
  }

  Future<_WorkOrderQuoteSnapshot> _buildQuoteSnapshotWithPricingSnapshot({
    required List<WorkOrderProductItem> items,
    required List<WorkOrderTaskItem> tasks,
    required WorkOrderPricingSnapshot pricingSnapshot,
  }) async {
    final _RequestedOrderCostSummary requested =
        await _buildRequestedOrderCostSummary(
      items: items,
      tasks: tasks,
    );
    final WorkOrderPricingSnapshot normalized =
        _normalizePricingSnapshot(pricingSnapshot);
    final List<WorkOrderPaymentValue> paymentValues =
        _buildPaymentValuesFromSnapshot(
      totals: requested.totals,
      pricingSnapshot: normalized,
    );
    return _WorkOrderQuoteSnapshot(
      lines: requested.lines,
      totals: requested.totals,
      paymentValues: paymentValues,
      pricingSnapshot: normalized,
    );
  }

  List<WorkOrderPaymentValue> _buildPaymentValuesFromSnapshot({
    required List<WorkOrderCostTotal> totals,
    required WorkOrderPricingSnapshot pricingSnapshot,
  }) {
    if (totals.isEmpty) {
      return const <WorkOrderPaymentValue>[];
    }
    final String localCode =
        pricingSnapshot.localCurrencyCode.trim().toUpperCase();
    final String foreignCode =
        pricingSnapshot.foreignCurrencyCode.trim().toUpperCase();
    final int foreignTotal = _convertTotalsWithSnapshot(
      totals: totals,
      targetCurrencyCode: foreignCode,
      pricingSnapshot: pricingSnapshot,
    );
    final int localCash = _convertTotalsWithSnapshot(
      totals: totals,
      targetCurrencyCode: localCode,
      pricingSnapshot: pricingSnapshot,
      useLocalCashRate: true,
    );
    final int localTransfer =
        (localCash * (1 + pricingSnapshot.localTransferPercentSurcharge / 100))
            .round();
    return <WorkOrderPaymentValue>[
      WorkOrderPaymentValue(
        label: foreignCode,
        currencyCode: foreignCode,
        amountCents: foreignTotal,
      ),
      WorkOrderPaymentValue(
        label: '$localCode Efectivo',
        currencyCode: localCode,
        amountCents: localCash,
      ),
      WorkOrderPaymentValue(
        label: '$localCode Transfer.',
        currencyCode: localCode,
        amountCents: localTransfer,
      ),
    ];
  }

  int _convertTotalsWithSnapshot({
    required List<WorkOrderCostTotal> totals,
    required String targetCurrencyCode,
    required WorkOrderPricingSnapshot pricingSnapshot,
    bool useLocalCashRate = false,
  }) {
    int total = 0;
    for (final WorkOrderCostTotal row in totals) {
      total += _convertCentsWithSnapshot(
        amountCents: row.totalCostCents,
        sourceCurrencyCode: row.currencyCode,
        targetCurrencyCode: targetCurrencyCode,
        pricingSnapshot: pricingSnapshot,
        useLocalCashRate: useLocalCashRate,
      );
    }
    return total;
  }

  int _convertCentsWithSnapshot({
    required int amountCents,
    required String sourceCurrencyCode,
    required String targetCurrencyCode,
    required WorkOrderPricingSnapshot pricingSnapshot,
    required bool useLocalCashRate,
  }) {
    final String source = sourceCurrencyCode.trim().toUpperCase();
    final String target = targetCurrencyCode.trim().toUpperCase();
    if (source == target) {
      return amountCents;
    }
    final String primary =
        pricingSnapshot.primaryCurrencyCode.trim().toUpperCase();
    final double sourceRate = pricingSnapshot.ratesByCode[source] ?? 1;
    final double targetRate = pricingSnapshot.ratesByCode[target] ?? 1;
    final double sourceAmount = amountCents / 100;
    final double amountInPrimary = source == primary
        ? sourceAmount
        : sourceAmount / (sourceRate <= 0 ? 1 : sourceRate);
    final bool applyLocalCashRate = useLocalCashRate &&
        source == pricingSnapshot.foreignCurrencyCode.trim().toUpperCase() &&
        target == pricingSnapshot.localCurrencyCode.trim().toUpperCase() &&
        source != target;
    final double resolvedTargetRate = applyLocalCashRate
        ? ((targetRate <= 0 ? 1 : targetRate) +
            pricingSnapshot.localCashFixedSurcharge)
        : (targetRate <= 0 ? 1 : targetRate);
    final double targetAmount = target == primary
        ? amountInPrimary
        : amountInPrimary * resolvedTargetRate;
    return (targetAmount * 100).round();
  }

  WorkOrderPricingSnapshot _normalizePricingSnapshot(
    WorkOrderPricingSnapshot snapshot,
  ) {
    final String primary = snapshot.primaryCurrencyCode.trim().toUpperCase();
    final String local = snapshot.localCurrencyCode.trim().toUpperCase();
    final String foreign = snapshot.foreignCurrencyCode.trim().toUpperCase();
    final Map<String, double> rates = <String, double>{};
    for (final MapEntry<String, double> entry in snapshot.ratesByCode.entries) {
      final String code = entry.key.trim().toUpperCase();
      if (code.isEmpty) {
        continue;
      }
      rates[code] =
          entry.value.isFinite && entry.value > 0 ? _roundTo2(entry.value) : 1;
    }
    if (!rates.containsKey(primary)) {
      rates[primary] = 1;
    } else {
      rates[primary] = 1;
    }
    if (!rates.containsKey(local)) {
      rates[local] = local == primary ? 1 : 1;
    }
    if (!rates.containsKey(foreign)) {
      rates[foreign] = foreign == primary ? 1 : 1;
    }
    return WorkOrderPricingSnapshot(
      capturedAt: snapshot.capturedAt,
      primaryCurrencyCode: primary,
      localCurrencyCode: local,
      foreignCurrencyCode: foreign,
      localCashFixedSurcharge: _roundTo2(
        snapshot.localCashFixedSurcharge < 0
            ? 0
            : snapshot.localCashFixedSurcharge,
      ),
      localTransferPercentSurcharge: _roundTo2(
        snapshot.localTransferPercentSurcharge < 0
            ? 0
            : snapshot.localTransferPercentSurcharge,
      ),
      ratesByCode: rates,
    );
  }

  List<WorkOrderRecordedPaymentLine> _sanitizePaymentLines(
    List<WorkOrderRecordedPaymentLine> lines,
  ) {
    return lines
        .where((WorkOrderRecordedPaymentLine line) {
          return line.methodCode.trim().isNotEmpty &&
              line.currencyCode.trim().isNotEmpty &&
              line.enteredAmountCents > 0;
        })
        .map(
          (WorkOrderRecordedPaymentLine line) => WorkOrderRecordedPaymentLine(
            methodCode: line.methodCode.trim().toLowerCase(),
            methodLabel: line.methodLabel.trim().isEmpty
                ? line.methodCode.trim()
                : line.methodLabel.trim(),
            currencyCode: line.currencyCode.trim().toUpperCase(),
            enteredAmountCents:
                line.enteredAmountCents < 0 ? 0 : line.enteredAmountCents,
            paidAt: line.paidAt,
            transactionId: _normalizeOptional(line.transactionId),
            note: _normalizeOptional(line.note),
          ),
        )
        .toList(growable: false);
  }

  Future<String> _nextFolio(DateTime now) async {
    final String prefix =
        'PED-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT folio
      FROM work_orders
      WHERE folio LIKE ?
      ORDER BY created_at DESC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>('$prefix-%')],
    ).get();
    int next = 1;
    if (rows.isNotEmpty) {
      final String last =
          _string(rows.first.readNullable<String>('folio'), fallback: '');
      final List<String> pieces = last.split('-');
      if (pieces.isNotEmpty) {
        next = (int.tryParse(pieces.last) ?? 0) + 1;
      }
    }
    return '$prefix-${next.toString().padLeft(3, '0')}';
  }

  double _sumConsumedSurfaceQty(List<WorkOrderTaskItem> tasks) {
    double total = 0;
    for (final WorkOrderTaskItem task in tasks) {
      for (final WorkOrderTaskMaterialItem item in task.materials) {
        if (_usesSquareMeters(item.unitLabel) && item.qty > 0) {
          total = _roundTo2(total + item.qty);
        }
      }
    }
    return _roundTo2(total);
  }

  bool _isServiceProduct(Product? product) {
    if (product == null) {
      return false;
    }
    return product.productType.trim().toLowerCase() == 'servicio';
  }

  bool _usesSquareMeters(String unitLabel) {
    final String unit = unitLabel.trim().toLowerCase();
    return unit.contains('m2') ||
        unit.contains('m²') ||
        unit.contains('metro cuadrado') ||
        unit.contains('metros cuadrados');
  }

  String _normalizeStatus(String value) {
    final String clean = value.trim();
    if (WorkOrderStatusCatalog.allStatuses.contains(clean)) {
      return clean;
    }
    return WorkOrderStatusCatalog.pending;
  }

  String _normalizePriority(String value) {
    final String clean = value.trim();
    if (WorkOrderPriorityCatalog.all.contains(clean)) {
      return clean;
    }
    return WorkOrderPriorityCatalog.normal;
  }

  String _normalizePaymentStatus(String value) {
    final String clean = value.trim();
    if (WorkOrderPaymentStatusCatalog.all.contains(clean)) {
      return clean;
    }
    return WorkOrderPaymentStatusCatalog.unpaid;
  }

  String _normalizeStatusFilter(String value) {
    final String clean = value.trim();
    if (clean.isEmpty || clean == 'all') {
      return 'all';
    }
    return _normalizeStatus(clean);
  }

  String _normalizeWorkType(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      return 'General';
    }
    return clean;
  }

  String? _normalizeOptional(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
  }

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Map<String, Object?> _decodeJsonMap(String? raw) {
    final String source = (raw ?? '').trim();
    if (source.isEmpty) {
      return const <String, Object?>{};
    }
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
    } catch (_) {
      return const <String, Object?>{};
    }
    return const <String, Object?>{};
  }
}

class _HeaderSnapshot {
  const _HeaderSnapshot({
    required this.title,
    required this.qty,
    required this.unitLabel,
    required this.primaryEmployeeId,
    required this.primaryEmployeeName,
  });

  final String title;
  final double qty;
  final String unitLabel;
  final String? primaryEmployeeId;
  final String? primaryEmployeeName;
}

class _EmployeeAccumulator {
  _EmployeeAccumulator({
    required this.employeeId,
    required this.employeeName,
  });

  final String employeeId;
  final String employeeName;
  int total = 0;
  int pending = 0;
  int inProgress = 0;
  int ready = 0;

  WorkOrderEmployeeSummary toSummary() {
    return WorkOrderEmployeeSummary(
      employeeId: employeeId,
      employeeName: employeeName,
      total: total,
      pending: pending,
      inProgress: inProgress,
      ready: ready,
    );
  }
}

class _MaterialConsumptionAccumulator {
  _MaterialConsumptionAccumulator({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
  });

  final String? productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  double qty = 0;
}

class _MaterialCostAccumulator {
  _MaterialCostAccumulator({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
    required this.currencyCode,
    required this.unitCostCents,
  });

  final String? productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  final String currencyCode;
  int unitCostCents;
  double usedQty = 0;
  double wasteQty = 0;
  int usedCostCents = 0;
  int wasteCostCents = 0;
}

class _RequestedLineAccumulator {
  _RequestedLineAccumulator({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitLabel,
    required this.currencyCode,
    required this.unitPriceCents,
  });

  final String? productId;
  final String productName;
  final String productSku;
  final String unitLabel;
  final String currencyCode;
  int unitPriceCents;
  double qty = 0;
}

class _WorkOrderCostSummary {
  const _WorkOrderCostSummary({
    required this.lines,
    required this.totals,
  });

  final List<WorkOrderMaterialCostLine> lines;
  final List<WorkOrderCostTotal> totals;
}

class _RequestedOrderCostSummary {
  const _RequestedOrderCostSummary({
    required this.lines,
    required this.totals,
  });

  final List<WorkOrderRequestedCostLine> lines;
  final List<WorkOrderCostTotal> totals;
}

class _WorkOrderQuoteSnapshot {
  const _WorkOrderQuoteSnapshot({
    required this.lines,
    required this.totals,
    required this.paymentValues,
    required this.pricingSnapshot,
  });

  final List<WorkOrderRequestedCostLine> lines;
  final List<WorkOrderCostTotal> totals;
  final List<WorkOrderPaymentValue> paymentValues;
  final WorkOrderPricingSnapshot pricingSnapshot;
}

String _string(Object? value, {required String fallback}) {
  final String clean = (value as String? ?? '').trim();
  return clean.isEmpty ? fallback : clean;
}

int _intValue(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

String? _nullableString(Object? value) {
  final String clean = (value as String? ?? '').trim();
  return clean.isEmpty ? null : clean;
}

double _doubleValue(Object? value, {required double fallback}) {
  if (value is num) {
    return _roundTo2(value.toDouble());
  }
  if (value is String) {
    return _roundTo2(double.tryParse(value) ?? fallback);
  }
  return _roundTo2(fallback);
}

double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return _roundTo2(value.toDouble());
  }
  if (value is String) {
    final double? parsed = double.tryParse(value);
    return parsed == null ? null : _roundTo2(parsed);
  }
  return null;
}

double _roundTo2(double value) {
  return (value * 100).round() / 100;
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<WorkOrderCostTotal> _parseCostTotalsJson(String? raw) {
  final List<dynamic> decoded = _decodeJsonList(raw);
  return decoded
      .whereType<Map>()
      .map(
        (Map item) => WorkOrderCostTotal.fromJson(
          item.cast<String, Object?>(),
        ),
      )
      .toList(growable: false);
}

String _encodeCostTotals(List<WorkOrderCostTotal> totals) {
  return jsonEncode(
    totals
        .map((WorkOrderCostTotal row) => row.toJson())
        .toList(growable: false),
  );
}

List<WorkOrderRequestedCostLine> _parseRequestedCostLinesJson(String? raw) {
  final List<dynamic> decoded = _decodeJsonList(raw);
  return decoded
      .whereType<Map>()
      .map(
        (Map item) => WorkOrderRequestedCostLine.fromJson(
          item.cast<String, Object?>(),
        ),
      )
      .toList(growable: false);
}

String _encodeRequestedCostLines(List<WorkOrderRequestedCostLine> lines) {
  return jsonEncode(
    lines
        .map((WorkOrderRequestedCostLine row) => row.toJson())
        .toList(growable: false),
  );
}

List<WorkOrderPaymentValue> _parsePaymentValuesJson(String? raw) {
  final List<dynamic> decoded = _decodeJsonList(raw);
  return decoded
      .whereType<Map>()
      .map(
        (Map item) => WorkOrderPaymentValue.fromJson(
          item.cast<String, Object?>(),
        ),
      )
      .toList(growable: false);
}

String _encodePaymentValues(List<WorkOrderPaymentValue> values) {
  return jsonEncode(
    values
        .map((WorkOrderPaymentValue row) => row.toJson())
        .toList(growable: false),
  );
}

List<WorkOrderRecordedPaymentLine> _parsePaymentLinesJson(String? raw) {
  final List<dynamic> decoded = _decodeJsonList(raw);
  return decoded
      .whereType<Map>()
      .map(
        (Map item) => WorkOrderRecordedPaymentLine.fromJson(
          item.cast<String, Object?>(),
        ),
      )
      .toList(growable: false);
}

String _encodePaymentLines(List<WorkOrderRecordedPaymentLine> lines) {
  return jsonEncode(
    lines
        .map((WorkOrderRecordedPaymentLine row) => row.toJson())
        .toList(growable: false),
  );
}

WorkOrderPricingSnapshot? _parsePricingSnapshotJson(String? raw) {
  final String source = (raw ?? '').trim();
  if (source.isEmpty) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(source);
    if (decoded is Map) {
      return WorkOrderPricingSnapshot.fromJson(
        decoded.cast<String, Object?>(),
      );
    }
  } catch (_) {}
  return null;
}

List<dynamic> _decodeJsonList(String? raw) {
  final String source = (raw ?? '').trim();
  if (source.isEmpty) {
    return const <dynamic>[];
  }
  try {
    final Object? decoded = jsonDecode(source);
    if (decoded is List) {
      return decoded;
    }
  } catch (_) {}
  return const <dynamic>[];
}

List<Map<String, Object?>> _listOfMaps(Object? raw) {
  if (raw is! List) {
    return const <Map<String, Object?>>[];
  }
  return raw
      .whereType<Map>()
      .map((Map value) => value.cast<String, Object?>())
      .toList(growable: false);
}

List<String> _listOfStrings(Object? raw) {
  if (raw is! List<Object?>) {
    return const <String>[];
  }
  return raw
      .map((Object? item) => item?.toString().trim() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}
