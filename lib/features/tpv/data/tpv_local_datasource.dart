import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_service.dart';
import '../../../core/security/app_permissions.dart';

class TpvSessionWithUser {
  const TpvSessionWithUser({
    required this.session,
    required this.user,
    this.responsibleEmployees = const <TpvEmployee>[],
  });

  final PosSession session;
  final User user;
  final List<TpvEmployee> responsibleEmployees;
}

class TpvEmployee {
  const TpvEmployee({
    required this.id,
    required this.code,
    required this.name,
    required this.sex,
    required this.identityNumber,
    required this.address,
    required this.imagePath,
    required this.associatedUserId,
    required this.associatedUsername,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final String? sex;
  final String? identityNumber;
  final String? address;
  final String? imagePath;
  final String? associatedUserId;
  final String? associatedUsername;
  final bool isActive;
}

class TpvUserOption {
  const TpvUserOption({
    required this.id,
    required this.username,
  });

  final String id;
  final String username;
}

class TpvWarehouseOption {
  const TpvWarehouseOption({
    required this.id,
    required this.name,
    required this.warehouseType,
  });

  final String id;
  final String name;
  final String warehouseType;
}

class TpvTerminalConfig {
  const TpvTerminalConfig({
    required this.currencyCode,
    required this.currencySymbol,
    required this.paymentMethods,
    required this.cashDenominationsCents,
    required this.useCashDenominationsOnClose,
    required this.allowDiscounts,
  });

  static const TpvTerminalConfig defaults = TpvTerminalConfig(
    currencyCode: 'USD',
    currencySymbol: r'$',
    paymentMethods: <String>['cash', 'consignment'],
    cashDenominationsCents: <int>[10000, 5000, 2000, 1000, 500, 100],
    useCashDenominationsOnClose: true,
    allowDiscounts: false,
  );

  final String currencyCode;
  final String currencySymbol;
  final List<String> paymentMethods;
  final List<int> cashDenominationsCents;
  final bool useCashDenominationsOnClose;
  final bool allowDiscounts;
}

class TpvTerminalView {
  const TpvTerminalView({
    required this.terminal,
    required this.warehouse,
    this.openSession,
  });

  final PosTerminal terminal;
  final Warehouse warehouse;
  final TpvSessionWithUser? openSession;
}

class TpvSessionCashBreakdown {
  const TpvSessionCashBreakdown({
    required this.denominationCents,
    required this.unitCount,
  });

  final int denominationCents;
  final int unitCount;

  int get subtotalCents => denominationCents * unitCount;
}

class TpvSessionSalesSummary {
  const TpvSessionSalesSummary({
    required this.postedSalesCount,
    required this.postedSubtotalCents,
    required this.postedTaxCents,
    required this.postedTotalCents,
    required this.archivedSalesCount,
  });

  final int postedSalesCount;
  final int postedSubtotalCents;
  final int postedTaxCents;
  final int postedTotalCents;
  final int archivedSalesCount;
}

class TpvSessionSaleView {
  const TpvSessionSaleView({
    required this.saleId,
    required this.folio,
    required this.createdAt,
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
    required this.status,
    required this.customerName,
    required this.paymentMethods,
  });

  final String saleId;
  final String folio;
  final DateTime createdAt;
  final int subtotalCents;
  final int taxCents;
  final int totalCents;
  final String status;
  final String? customerName;
  final List<String> paymentMethods;
}

class TpvLocalDataSource {
  TpvLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;

  static const List<String> kAllowedPaymentMethods = <String>[
    'cash',
    'card',
    'transfer',
    'wallet',
    'consignment',
  ];

  Future<void> _logAudit({
    String? userId,
    required String action,
    required String entity,
    required String entityId,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    final String? safeUserId = _normalizeOptional(userId);
    return _db.into(_db.auditLogs).insert(
          AuditLogsCompanion.insert(
            id: _uuid.v4(),
            userId: Value(safeUserId),
            action: action,
            entity: entity,
            entityId: entityId,
            payloadJson: jsonEncode(payload),
          ),
        );
  }

  Future<List<PosTerminal>> listActiveTerminalOptions() {
    return (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) =>
              tbl.isActive.equals(true) &
              tbl.id.isNotNull() &
              tbl.code.isNotNull() &
              tbl.name.isNotNull() &
              tbl.warehouseId.isNotNull() &
              tbl.createdAt.isNotNull())
          ..orderBy(<OrderingTerm Function(PosTerminals)>[
            (PosTerminals tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
  }

  Future<List<TpvTerminalView>> listActiveTerminalViews() async {
    final List<PosTerminal> terminals = await listActiveTerminalOptions();
    if (terminals.isEmpty) {
      return <TpvTerminalView>[];
    }

    final Set<String> warehouseIds =
        terminals.map((PosTerminal terminal) => terminal.warehouseId).toSet();
    final Set<String> terminalIds =
        terminals.map((PosTerminal terminal) => terminal.id).toSet();

    final List<Warehouse> warehouses = await (_db.select(_db.warehouses)
          ..where((Warehouses tbl) => tbl.id.isIn(warehouseIds)))
        .get();
    final Map<String, Warehouse> warehouseById = <String, Warehouse>{
      for (final Warehouse warehouse in warehouses) warehouse.id: warehouse,
    };

    final List<PosSession> openSessions = await (_db.select(_db.posSessions)
          ..where((PosSessions tbl) =>
              tbl.terminalId.isIn(terminalIds) & tbl.status.equals('open')))
        .get();
    final Set<String> userIds =
        openSessions.map((PosSession session) => session.userId).toSet();
    final List<User> users = userIds.isEmpty
        ? <User>[]
        : await (_db.select(_db.users)
              ..where((Users tbl) => tbl.id.isIn(userIds)))
            .get();
    final Map<String, List<TpvEmployee>> responsibleBySessionId =
        await listResponsibleEmployeesForSessions(
      openSessions.map((PosSession session) => session.id),
    );
    final Map<String, User> userById = <String, User>{
      for (final User user in users) user.id: user,
    };
    final Map<String, TpvSessionWithUser> openByTerminalId =
        <String, TpvSessionWithUser>{};
    for (final PosSession session in openSessions) {
      final User? user = userById[session.userId];
      if (user == null) {
        continue;
      }
      openByTerminalId[session.terminalId] = TpvSessionWithUser(
        session: session,
        user: user,
        responsibleEmployees:
            responsibleBySessionId[session.id] ?? const <TpvEmployee>[],
      );
    }

    final List<TpvTerminalView> result = <TpvTerminalView>[];
    for (final PosTerminal terminal in terminals) {
      final Warehouse? warehouse = warehouseById[terminal.warehouseId];
      if (warehouse == null) {
        continue;
      }
      result.add(
        TpvTerminalView(
          terminal: terminal,
          warehouse: warehouse,
          openSession: openByTerminalId[terminal.id],
        ),
      );
    }

    return result;
  }

  Future<TpvTerminalView?> getTerminalView(String terminalId) async {
    final PosTerminal? terminal = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.equals(terminalId)))
        .getSingleOrNull();
    if (terminal == null) {
      return null;
    }

    final Warehouse? warehouse = await (_db.select(_db.warehouses)
          ..where((Warehouses tbl) => tbl.id.equals(terminal.warehouseId)))
        .getSingleOrNull();
    if (warehouse == null) {
      return null;
    }

    final PosSession? openSession = await getOpenSessionForTerminal(terminalId);
    TpvSessionWithUser? sessionWithUser;
    if (openSession != null) {
      final User? user = await (_db.select(_db.users)
            ..where((Users tbl) => tbl.id.equals(openSession.userId)))
          .getSingleOrNull();
      final List<TpvEmployee> responsible =
          await listSessionResponsibleEmployees(
        openSession.id,
      );
      if (user != null) {
        sessionWithUser = TpvSessionWithUser(
          session: openSession,
          user: user,
          responsibleEmployees: responsible,
        );
      }
    }

    return TpvTerminalView(
      terminal: terminal,
      warehouse: warehouse,
      openSession: sessionWithUser,
    );
  }

  Future<String> createTerminal({
    required String name,
    String? code,
    String? warehouseId,
    TpvTerminalConfig? config,
    String? imagePath,
    String? actorUserId,
    List<String> allowedEmployeeIds = const <String>[],
  }) async {
    await _licenseService.requireWriteAccess();
    final LicenseStatus licenseStatus = await _licenseService.current();
    if (!licenseStatus.isFull) {
      final int activeTerminals = await _countActiveTerminals();
      if (activeTerminals >= DemoLicenseLimits.maxActiveTerminals) {
        throw const LicenseException(
          'Modo demo: solo puedes tener 1 TPV activo.',
        );
      }
    }
    final String cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre del TPV es obligatorio.');
    }
    final TpvTerminalConfig safeConfig = _sanitizeConfig(config);
    final String? safeActorUserId = _normalizeOptional(actorUserId);

    final String resolvedCode = await _resolveTerminalCode(
      name: cleanName,
      code: code,
      excludeTerminalId: null,
    );

    return _db.transaction(() async {
      final String? requestedWarehouseId = _normalizeOptional(warehouseId);
      String resolvedWarehouseId;
      if (requestedWarehouseId == null) {
        resolvedWarehouseId = _uuid.v4();
        await _db.into(_db.warehouses).insert(
              WarehousesCompanion.insert(
                id: resolvedWarehouseId,
                name: cleanName,
                warehouseType: const Value('TPV'),
              ),
            );
      } else {
        await _requireWarehouseAvailableForTerminal(
          warehouseId: requestedWarehouseId,
          excludeTerminalId: null,
        );
        resolvedWarehouseId = requestedWarehouseId;
      }
      final String terminalId = _uuid.v4();

      await _db.into(_db.posTerminals).insert(
            PosTerminalsCompanion.insert(
              id: terminalId,
              code: resolvedCode,
              name: cleanName,
              warehouseId: resolvedWarehouseId,
              currencyCode: Value(safeConfig.currencyCode),
              currencySymbol: Value(safeConfig.currencySymbol),
              paymentMethodsJson: Value(
                jsonEncode(safeConfig.paymentMethods),
              ),
              cashDenominationsJson: Value(
                _encodeCashDenominationsConfig(safeConfig),
              ),
              imagePath: Value(imagePath),
            ),
          );

      await _replaceTerminalEmployeeAccess(
        terminalId: terminalId,
        employeeIds: allowedEmployeeIds,
      );
      final List<String> assignedEmployeeIds =
          (await listAllowedEmployeeIdsForTerminal(terminalId)).toList()
            ..sort();
      await _logAudit(
        userId: safeActorUserId,
        action: 'TPV_TERMINAL_CREATED',
        entity: 'tpv_terminal',
        entityId: terminalId,
        payload: <String, Object?>{
          'code': resolvedCode,
          'name': cleanName,
          'warehouseId': resolvedWarehouseId,
          'currencyCode': safeConfig.currencyCode,
          'paymentMethods': safeConfig.paymentMethods,
          'allowedEmployeeIds': assignedEmployeeIds,
        },
      );

      return terminalId;
    });
  }

  Future<int> _countActiveTerminals() async {
    final Expression<int> countExp = _db.posTerminals.id.count();
    final TypedResult row = await (_db.selectOnly(_db.posTerminals)
          ..addColumns(<Expression<Object>>[countExp])
          ..where(_db.posTerminals.isActive.equals(true)))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> updateTerminal({
    required String terminalId,
    required String name,
    required String code,
    String? warehouseId,
    TpvTerminalConfig? config,
    String? imagePath,
    String? actorUserId,
    List<String> allowedEmployeeIds = const <String>[],
  }) async {
    await _licenseService.requireWriteAccess();
    final String cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre del TPV es obligatorio.');
    }

    final PosTerminal? terminal = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.equals(terminalId)))
        .getSingleOrNull();
    if (terminal == null) {
      throw Exception('El TPV no existe.');
    }

    final String resolvedCode = await _resolveTerminalCode(
      name: cleanName,
      code: code,
      excludeTerminalId: terminalId,
    );
    final String requestedWarehouseId =
        _normalizeOptional(warehouseId) ?? terminal.warehouseId;
    if (requestedWarehouseId != terminal.warehouseId) {
      await _requireWarehouseAvailableForTerminal(
        warehouseId: requestedWarehouseId,
        excludeTerminalId: terminalId,
      );
    }
    final TpvTerminalConfig safeConfig = _sanitizeConfig(config);
    final String? safeActorUserId = _normalizeOptional(actorUserId);

    await _db.transaction(() async {
      final Warehouse? currentWarehouse = await (_db.select(_db.warehouses)
            ..where((Warehouses tbl) => tbl.id.equals(terminal.warehouseId)))
          .getSingleOrNull();
      await (_db.update(_db.posTerminals)
            ..where((PosTerminals tbl) => tbl.id.equals(terminalId)))
          .write(
        PosTerminalsCompanion(
          name: Value(cleanName),
          code: Value(resolvedCode),
          warehouseId: Value(requestedWarehouseId),
          currencyCode: Value(safeConfig.currencyCode),
          currencySymbol: Value(safeConfig.currencySymbol),
          paymentMethodsJson: Value(
            jsonEncode(safeConfig.paymentMethods),
          ),
          cashDenominationsJson: Value(
            _encodeCashDenominationsConfig(safeConfig),
          ),
          imagePath: Value(imagePath),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (requestedWarehouseId == terminal.warehouseId &&
          currentWarehouse != null &&
          currentWarehouse.warehouseType.trim().toUpperCase() == 'TPV' &&
          currentWarehouse.name.trim() == terminal.name.trim()) {
        await (_db.update(_db.warehouses)
              ..where((Warehouses tbl) => tbl.id.equals(terminal.warehouseId)))
            .write(
          WarehousesCompanion(
            name: Value(cleanName),
          ),
        );
      }

      await _replaceTerminalEmployeeAccess(
        terminalId: terminalId,
        employeeIds: allowedEmployeeIds,
      );
      final List<String> assignedEmployeeIds =
          (await listAllowedEmployeeIdsForTerminal(terminalId)).toList()
            ..sort();
      await _logAudit(
        userId: safeActorUserId,
        action: 'TPV_TERMINAL_UPDATED',
        entity: 'tpv_terminal',
        entityId: terminalId,
        payload: <String, Object?>{
          'before': <String, Object?>{
            'code': terminal.code,
            'name': terminal.name,
            'warehouseId': terminal.warehouseId,
            'currencyCode': terminal.currencyCode,
            'isActive': terminal.isActive,
          },
          'after': <String, Object?>{
            'code': resolvedCode,
            'name': cleanName,
            'warehouseId': requestedWarehouseId,
            'currencyCode': safeConfig.currencyCode,
            'paymentMethods': safeConfig.paymentMethods,
            'allowedEmployeeIds': assignedEmployeeIds,
            'isActive': true,
          },
        },
      );
    });
  }

  Future<List<TpvWarehouseOption>> listWarehousesEligibleForTerminalAccess({
    String? terminalId,
  }) async {
    final String? cleanTerminalId = _normalizeOptional(terminalId);
    String? currentWarehouseId;
    if (cleanTerminalId != null) {
      final PosTerminal? terminal = await (_db.select(_db.posTerminals)
            ..where((PosTerminals tbl) => tbl.id.equals(cleanTerminalId)))
          .getSingleOrNull();
      currentWarehouseId = terminal?.warehouseId;
    }

    final List<Warehouse> warehouses = await (_db.select(_db.warehouses)
          ..where((Warehouses tbl) {
            if (currentWarehouseId == null) {
              return tbl.isActive.equals(true);
            }
            return tbl.isActive.equals(true) |
                tbl.id.equals(currentWarehouseId);
          })
          ..orderBy(<OrderingTerm Function(Warehouses)>[
            (Warehouses tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
    if (warehouses.isEmpty) {
      return const <TpvWarehouseOption>[];
    }

    final Set<String> warehouseIds =
        warehouses.map((Warehouse item) => item.id).toSet();
    final List<PosTerminal> terminals = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.warehouseId.isIn(warehouseIds)))
        .get();
    final Map<String, String> terminalByWarehouseId = <String, String>{
      for (final PosTerminal terminal in terminals)
        terminal.warehouseId: terminal.id,
    };

    final List<TpvWarehouseOption> options = <TpvWarehouseOption>[];
    for (final Warehouse warehouse in warehouses) {
      final String? ownerTerminalId = terminalByWarehouseId[warehouse.id];
      final bool canUse = ownerTerminalId == null ||
          ownerTerminalId == cleanTerminalId ||
          warehouse.id == currentWarehouseId;
      if (!canUse) {
        continue;
      }
      options.add(
        TpvWarehouseOption(
          id: warehouse.id,
          name: warehouse.name,
          warehouseType: warehouse.warehouseType,
        ),
      );
    }
    return options;
  }

  Future<void> deactivateTerminal(
    String terminalId, {
    String? actorUserId,
  }) async {
    await _licenseService.requireWriteAccess();
    final String? safeActorUserId = _normalizeOptional(actorUserId);
    final PosTerminal? terminal = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.equals(terminalId)))
        .getSingleOrNull();
    if (terminal == null) {
      throw Exception('El TPV no existe.');
    }

    await _db.transaction(() async {
      final DateTime deactivatedAt = DateTime.now();
      await (_db.update(_db.posTerminals)
            ..where((PosTerminals tbl) => tbl.id.equals(terminalId)))
          .write(
        PosTerminalsCompanion(
          isActive: const Value(false),
          updatedAt: Value(deactivatedAt),
        ),
      );

      await (_db.update(_db.warehouses)
            ..where((Warehouses tbl) => tbl.id.equals(terminal.warehouseId)))
          .write(
        const WarehousesCompanion(
          isActive: Value(false),
        ),
      );

      await (_db.delete(_db.posTerminalEmployees)
            ..where(
              (PosTerminalEmployees tbl) => tbl.terminalId.equals(terminalId),
            ))
          .go();

      final List<PosSession> openSessions = await (_db.select(_db.posSessions)
            ..where((PosSessions tbl) =>
                tbl.terminalId.equals(terminalId) & tbl.status.equals('open')))
          .get();
      final List<String> autoClosedSessionIds = <String>[];
      for (final PosSession session in openSessions) {
        await (_db.update(_db.posSessions)
              ..where((PosSessions tbl) => tbl.id.equals(session.id)))
            .write(
          PosSessionsCompanion(
            status: const Value('closed'),
            closedAt: Value(deactivatedAt),
            note: const Value('Cierre automatico por baja de TPV'),
          ),
        );
        autoClosedSessionIds.add(session.id);
        await _logAudit(
          userId: safeActorUserId,
          action: 'TPV_SESSION_AUTO_CLOSED',
          entity: 'pos_session',
          entityId: session.id,
          payload: <String, Object?>{
            'terminalId': terminalId,
            'terminalName': terminal.name,
            'reason': 'terminal_deactivated',
            'closedAt': deactivatedAt.toIso8601String(),
          },
        );
      }
      await _logAudit(
        userId: safeActorUserId,
        action: 'TPV_TERMINAL_DEACTIVATED',
        entity: 'tpv_terminal',
        entityId: terminalId,
        payload: <String, Object?>{
          'code': terminal.code,
          'name': terminal.name,
          'warehouseId': terminal.warehouseId,
          'deactivatedAt': deactivatedAt.toIso8601String(),
          'autoClosedSessionIds': autoClosedSessionIds,
        },
      );
    });
  }

  Future<PosSession?> getOpenSessionForTerminal(String terminalId) {
    return (_db.select(_db.posSessions)
          ..where((PosSessions tbl) =>
              tbl.terminalId.equals(terminalId) & tbl.status.equals('open')))
        .getSingleOrNull();
  }

  Future<PosSession?> getOpenSessionForTerminalAndUser({
    required String terminalId,
    required String userId,
  }) {
    return (_db.select(_db.posSessions)
          ..where((PosSessions tbl) =>
              tbl.terminalId.equals(terminalId) &
              tbl.userId.equals(userId) &
              tbl.status.equals('open')))
        .getSingleOrNull();
  }

  Future<TpvTerminalConfig?> getTerminalConfig(String terminalId) async {
    final PosTerminal? terminal = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.equals(terminalId)))
        .getSingleOrNull();
    if (terminal == null) {
      return null;
    }
    return configFromTerminal(terminal);
  }

  TpvTerminalConfig configFromTerminal(PosTerminal terminal) {
    final String currencyCode = _sanitizeCurrencyCode(terminal.currencyCode);
    final String currencySymbol =
        _sanitizeCurrencySymbol(terminal.currencySymbol);
    final List<String> paymentMethods =
        _sanitizePaymentMethods(_decodeStringList(terminal.paymentMethodsJson));
    final ({
      List<int> denominations,
      bool useOnClose,
      bool allowDiscounts
    }) cashConfig =
        _decodeCashDenominationsConfig(terminal.cashDenominationsJson);
    final List<int> denominations = _sanitizeDenominations(
      cashConfig.denominations,
    );

    return TpvTerminalConfig(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      paymentMethods: paymentMethods,
      cashDenominationsCents: denominations,
      useCashDenominationsOnClose: cashConfig.useOnClose,
      allowDiscounts: cashConfig.allowDiscounts,
    );
  }

  Future<List<TpvUserOption>> listActiveUserOptions() async {
    final List<User> users = await (_db.select(_db.users)
          ..where((Users tbl) =>
              tbl.isActive.equals(true) &
              tbl.id.isNotNull() &
              tbl.username.isNotNull())
          ..orderBy(<OrderingTerm Function(Users)>[
            (Users tbl) => OrderingTerm.asc(tbl.username),
          ]))
        .get();

    return users
        .map(
          (User user) => TpvUserOption(
            id: user.id,
            username: user.username,
          ),
        )
        .toList();
  }

  Future<List<TpvEmployee>> listEmployees(
      {bool includeInactive = false}) async {
    final String statusFilter = includeInactive ? '' : 'AND e.is_active = 1';
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        e.id AS id,
        e.code AS code,
        e.name AS name,
        e.sex AS sex,
        e.identity_number AS identity_number,
        e.address AS address,
        e.image_path AS image_path,
        e.associated_user_id AS associated_user_id,
        e.is_active AS is_active,
        u.username AS associated_username
      FROM employees e
      LEFT JOIN users u
        ON u.id = e.associated_user_id
      WHERE e.id IS NOT NULL
        AND e.name IS NOT NULL
        $statusFilter
      ORDER BY e.name ASC
      ''',
    ).get();
    return rows
        .map(
          (QueryRow row) => TpvEmployee(
            id: row.read<String>('id'),
            code: row.read<String>('code'),
            name: row.read<String>('name'),
            sex: _normalizeOptional(row.readNullable<String>('sex')),
            identityNumber:
                _normalizeOptional(row.readNullable<String>('identity_number')),
            address: _normalizeOptional(row.readNullable<String>('address')),
            imagePath:
                _normalizeOptional(row.readNullable<String>('image_path')),
            associatedUserId: _normalizeOptional(
                row.readNullable<String>('associated_user_id')),
            associatedUsername: _normalizeOptional(
                row.readNullable<String>('associated_username')),
            isActive: row.read<bool>('is_active'),
          ),
        )
        .toList();
  }

  Future<List<TpvEmployee>> listArchivedEmployees({
    String? search,
    int limit = 250,
  }) async {
    final String cleanedSearch = (search ?? '').trim().toLowerCase();
    final int safeLimit = limit < 1 ? 1 : limit;
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        e.id AS id,
        e.code AS code,
        e.name AS name,
        e.sex AS sex,
        e.identity_number AS identity_number,
        e.address AS address,
        e.image_path AS image_path,
        e.associated_user_id AS associated_user_id,
        e.is_active AS is_active,
        u.username AS associated_username
      FROM employees e
      LEFT JOIN users u
        ON u.id = e.associated_user_id
      WHERE e.is_active = 0
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (cleanedSearch.isNotEmpty) {
      final String pattern = '%$cleanedSearch%';
      sql.write(
        '''
        AND (
          LOWER(COALESCE(e.name, '')) LIKE ?
          OR LOWER(COALESCE(e.code, '')) LIKE ?
          OR LOWER(COALESCE(e.identity_number, '')) LIKE ?
          OR LOWER(COALESCE(u.username, '')) LIKE ?
        )
        ''',
      );
      variables.addAll(<Variable<Object>>[
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
      ]);
    }
    sql.write(
      '''
      ORDER BY COALESCE(e.updated_at, e.created_at) DESC, e.name ASC
      LIMIT ?
      ''',
    );
    variables.add(Variable<int>(safeLimit));

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();
    return rows
        .map(
          (QueryRow row) => TpvEmployee(
            id: row.read<String>('id'),
            code: row.read<String>('code'),
            name: row.read<String>('name'),
            sex: _normalizeOptional(row.readNullable<String>('sex')),
            identityNumber:
                _normalizeOptional(row.readNullable<String>('identity_number')),
            address: _normalizeOptional(row.readNullable<String>('address')),
            imagePath:
                _normalizeOptional(row.readNullable<String>('image_path')),
            associatedUserId: _normalizeOptional(
                row.readNullable<String>('associated_user_id')),
            associatedUsername: _normalizeOptional(
                row.readNullable<String>('associated_username')),
            isActive: row.read<bool>('is_active'),
          ),
        )
        .toList(growable: false);
  }

  Future<List<TpvEmployee>> listActiveEmployees() {
    return listEmployees(includeInactive: false);
  }

  Future<List<TpvEmployee>> listEmployeesEligibleForTerminalAccess() async {
    final Set<String> userIds = await _listUserIdsWithPosSalesAccess();
    if (userIds.isEmpty) {
      return <TpvEmployee>[];
    }
    final List<TpvEmployee> employees = await listActiveEmployees();
    return employees.where((TpvEmployee employee) {
      final String associatedUserId = (employee.associatedUserId ?? '').trim();
      if (associatedUserId.isEmpty) {
        return false;
      }
      return userIds.contains(associatedUserId);
    }).toList(growable: false);
  }

  Future<Set<String>> listAllowedEmployeeIdsForTerminal(
      String terminalId) async {
    final String cleanTerminalId = terminalId.trim();
    if (cleanTerminalId.isEmpty) {
      return <String>{};
    }
    final List<PosTerminalEmployee> rows =
        await (_db.select(_db.posTerminalEmployees)
              ..where(
                (PosTerminalEmployees tbl) =>
                    tbl.terminalId.equals(cleanTerminalId),
              ))
            .get();
    return rows
        .map((PosTerminalEmployee row) => row.employeeId.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
  }

  Future<bool> isEmployeeAllowedForTerminal({
    required String terminalId,
    required String employeeId,
  }) async {
    final String cleanTerminalId = terminalId.trim();
    final String cleanEmployeeId = employeeId.trim();
    if (cleanTerminalId.isEmpty || cleanEmployeeId.isEmpty) {
      return false;
    }
    final List<PosTerminalEmployee> restrictedRows =
        await (_db.select(_db.posTerminalEmployees)
              ..where((PosTerminalEmployees tbl) =>
                  tbl.terminalId.equals(cleanTerminalId))
              ..limit(1))
            .get();
    if (restrictedRows.isEmpty) {
      return true;
    }

    final PosTerminalEmployee? row = await (_db.select(_db.posTerminalEmployees)
          ..where(
            (PosTerminalEmployees tbl) =>
                tbl.terminalId.equals(cleanTerminalId) &
                tbl.employeeId.equals(cleanEmployeeId),
          ))
        .getSingleOrNull();
    return row != null;
  }

  Future<bool> userCanAccessTerminal({
    required String terminalId,
    required String userId,
  }) async {
    final String cleanTerminalId = terminalId.trim();
    final String cleanUserId = userId.trim();
    if (cleanTerminalId.isEmpty || cleanUserId.isEmpty) {
      return false;
    }

    if (await _userHasAdminRole(cleanUserId)) {
      return true;
    }
    final TpvEmployee? employee =
        await findActiveEmployeeByAssociatedUser(cleanUserId);
    if (employee == null) {
      return false;
    }
    return isEmployeeAllowedForTerminal(
      terminalId: cleanTerminalId,
      employeeId: employee.id,
    );
  }

  Future<List<TpvTerminalView>> filterTerminalViewsForEmployee({
    required List<TpvTerminalView> terminals,
    required String employeeId,
  }) async {
    final String cleanEmployeeId = employeeId.trim();
    if (cleanEmployeeId.isEmpty || terminals.isEmpty) {
      return <TpvTerminalView>[];
    }
    final Set<String> terminalIds =
        terminals.map((TpvTerminalView row) => row.terminal.id).toSet();
    final List<PosTerminalEmployee> rows = await (_db
            .select(_db.posTerminalEmployees)
          ..where(
              (PosTerminalEmployees tbl) => tbl.terminalId.isIn(terminalIds)))
        .get();

    final Map<String, Set<String>> employeesByTerminal =
        <String, Set<String>>{};
    for (final PosTerminalEmployee row in rows) {
      employeesByTerminal
          .putIfAbsent(row.terminalId, () => <String>{})
          .add(row.employeeId);
    }

    return terminals.where((TpvTerminalView terminal) {
      final Set<String>? allowed = employeesByTerminal[terminal.terminal.id];
      if (allowed == null || allowed.isEmpty) {
        return true;
      }
      return allowed.contains(cleanEmployeeId);
    }).toList(growable: false);
  }

  Future<TpvEmployee?> findActiveEmployeeByAssociatedUser(
    String userId,
  ) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return null;
    }
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        e.id AS id,
        e.code AS code,
        e.name AS name,
        e.sex AS sex,
        e.identity_number AS identity_number,
        e.address AS address,
        e.image_path AS image_path,
        e.associated_user_id AS associated_user_id,
        e.is_active AS is_active,
        u.username AS associated_username
      FROM employees e
      LEFT JOIN users u
        ON u.id = e.associated_user_id
      WHERE e.is_active = 1
        AND e.associated_user_id = ?
      ORDER BY e.created_at ASC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanUserId)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    final QueryRow row = rows.first;
    return TpvEmployee(
      id: row.read<String>('id'),
      code: row.read<String>('code'),
      name: row.read<String>('name'),
      sex: _normalizeOptional(row.readNullable<String>('sex')),
      identityNumber:
          _normalizeOptional(row.readNullable<String>('identity_number')),
      address: _normalizeOptional(row.readNullable<String>('address')),
      imagePath: _normalizeOptional(row.readNullable<String>('image_path')),
      associatedUserId:
          _normalizeOptional(row.readNullable<String>('associated_user_id')),
      associatedUsername:
          _normalizeOptional(row.readNullable<String>('associated_username')),
      isActive: row.read<bool>('is_active'),
    );
  }

  Future<String> createEmployee({
    required String name,
    String? code,
    String? sex,
    String? identityNumber,
    String? address,
    String? imagePath,
    String? associatedUserId,
  }) async {
    await _licenseService.requireWriteAccess();
    await _requireDemoEmployeeSlotForActivation();
    final String cleanName = _normalizeEmployeeName(name);
    if (cleanName.isEmpty) {
      throw Exception('El nombre del empleado es obligatorio.');
    }
    final String? cleanUserId = _normalizeOptional(associatedUserId);
    if (cleanUserId != null) {
      final User? user = await (_db.select(_db.users)
            ..where((Users tbl) =>
                tbl.id.equals(cleanUserId) & tbl.isActive.equals(true)))
          .getSingleOrNull();
      if (user == null) {
        throw Exception('El usuario asociado no existe o esta inactivo.');
      }
    }
    final String resolvedCode = await _resolveEmployeeCode(
      preferredCode: code,
      name: cleanName,
      excludeEmployeeId: null,
    );
    final String id = _uuid.v4();
    await _db.into(_db.employees).insert(
          EmployeesCompanion.insert(
            id: id,
            code: resolvedCode,
            name: cleanName,
            sex: Value(_normalizeEmployeeSex(sex)),
            identityNumber: Value(_normalizeOptional(identityNumber)),
            address: Value(_normalizeOptional(address)),
            imagePath: Value(_normalizeOptional(imagePath)),
            associatedUserId: Value(cleanUserId),
          ),
        );
    return id;
  }

  Future<void> updateEmployee({
    required String employeeId,
    required String name,
    required String code,
    bool? isActive,
    String? sex,
    String? identityNumber,
    String? address,
    String? imagePath,
    String? associatedUserId,
  }) async {
    await _licenseService.requireWriteAccess();
    final Employee? existing = await (_db.select(_db.employees)
          ..where((Employees tbl) => tbl.id.equals(employeeId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El empleado no existe.');
    }

    final String cleanName = _normalizeEmployeeName(name);
    if (cleanName.isEmpty) {
      throw Exception('El nombre del empleado es obligatorio.');
    }
    final String? cleanUserId = _normalizeOptional(associatedUserId);
    if (cleanUserId != null) {
      final User? user = await (_db.select(_db.users)
            ..where((Users tbl) =>
                tbl.id.equals(cleanUserId) & tbl.isActive.equals(true)))
          .getSingleOrNull();
      if (user == null) {
        throw Exception('El usuario asociado no existe o esta inactivo.');
      }
    }
    final String resolvedCode = await _resolveEmployeeCode(
      preferredCode: code,
      name: cleanName,
      excludeEmployeeId: employeeId,
    );
    final bool nextIsActive = isActive ?? existing.isActive;
    if (!existing.isActive && nextIsActive) {
      await _requireDemoEmployeeSlotForActivation(
          excludeEmployeeId: employeeId);
    }

    await (_db.update(_db.employees)
          ..where((Employees tbl) => tbl.id.equals(employeeId)))
        .write(
      EmployeesCompanion(
        name: Value(cleanName),
        code: Value(resolvedCode),
        sex: Value(_normalizeEmployeeSex(sex)),
        identityNumber: Value(_normalizeOptional(identityNumber)),
        address: Value(_normalizeOptional(address)),
        imagePath: Value(_normalizeOptional(imagePath)),
        associatedUserId: Value(cleanUserId),
        isActive: isActive == null ? const Value.absent() : Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deactivateEmployee(String employeeId) async {
    await _licenseService.requireWriteAccess();
    final Employee? existing = await (_db.select(_db.employees)
          ..where((Employees tbl) => tbl.id.equals(employeeId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El empleado no existe.');
    }

    await (_db.update(_db.employees)
          ..where((Employees tbl) => tbl.id.equals(employeeId)))
        .write(
      EmployeesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> reactivateEmployee(String employeeId) async {
    await _licenseService.requireWriteAccess();
    final String safeEmployeeId = employeeId.trim();
    if (safeEmployeeId.isEmpty) {
      throw Exception('Empleado inválido.');
    }
    final Employee? existing = await (_db.select(_db.employees)
          ..where((Employees tbl) => tbl.id.equals(safeEmployeeId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El empleado no existe.');
    }
    if (existing.isActive) {
      return;
    }
    await _requireDemoEmployeeSlotForActivation(
      excludeEmployeeId: safeEmployeeId,
    );
    await (_db.update(_db.employees)
          ..where((Employees tbl) => tbl.id.equals(safeEmployeeId)))
        .write(
      EmployeesCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> permanentlyDeleteEmployee({
    required String employeeId,
    required String userId,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeEmployeeId = employeeId.trim();
    final String safeUserId = userId.trim();
    if (safeEmployeeId.isEmpty) {
      throw Exception('Empleado inválido.');
    }
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }

    await _db.transaction(() async {
      final Employee? existing = await (_db.select(_db.employees)
            ..where((Employees tbl) => tbl.id.equals(safeEmployeeId)))
          .getSingleOrNull();
      if (existing == null) {
        return;
      }
      if (existing.isActive) {
        throw Exception(
          'Primero desactiva el empleado antes de eliminarlo definitivamente.',
        );
      }

      await (_db.delete(_db.posTerminalEmployees)
            ..where(
              (PosTerminalEmployees tbl) =>
                  tbl.employeeId.equals(safeEmployeeId),
            ))
          .go();
      await (_db.delete(_db.posSessionEmployees)
            ..where(
              (PosSessionEmployees tbl) =>
                  tbl.employeeId.equals(safeEmployeeId),
            ))
          .go();
      await (_db.delete(_db.employees)
            ..where((Employees tbl) => tbl.id.equals(safeEmployeeId)))
          .go();

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'EMPLOYEE_PURGED',
              entity: 'employee',
              entityId: safeEmployeeId,
              payloadJson: jsonEncode(<String, Object?>{
                'code': existing.code,
                'name': existing.name,
              }),
            ),
          );
    });
  }

  Future<List<TpvEmployee>> listSessionResponsibleEmployees(
    String sessionId,
  ) async {
    final Map<String, List<TpvEmployee>> grouped =
        await listResponsibleEmployeesForSessions(<String>[sessionId]);
    return grouped[sessionId] ?? const <TpvEmployee>[];
  }

  Future<Map<String, List<TpvEmployee>>> listResponsibleEmployeesForSessions(
    Iterable<String> sessionIds,
  ) async {
    final Set<String> ids = sessionIds.toSet();
    if (ids.isEmpty) {
      return <String, List<TpvEmployee>>{};
    }

    final List<PosSessionEmployee> rows =
        await (_db.select(_db.posSessionEmployees)
              ..where((PosSessionEmployees tbl) => tbl.sessionId.isIn(ids))
              ..orderBy(<OrderingTerm Function(PosSessionEmployees)>[
                (PosSessionEmployees tbl) => OrderingTerm.asc(tbl.assignedAt),
              ]))
            .get();
    if (rows.isEmpty) {
      return <String, List<TpvEmployee>>{};
    }

    final Set<String> employeeIds =
        rows.map((PosSessionEmployee row) => row.employeeId).toSet();
    final List<Employee> employees = await (_db.select(_db.employees)
          ..where((Employees tbl) => tbl.id.isIn(employeeIds)))
        .get();
    final Map<String, Employee> byId = <String, Employee>{
      for (final Employee employee in employees) employee.id: employee,
    };

    final Map<String, List<TpvEmployee>> result = <String, List<TpvEmployee>>{};
    for (final PosSessionEmployee row in rows) {
      final Employee? employee = byId[row.employeeId];
      if (employee == null) {
        continue;
      }
      result.putIfAbsent(row.sessionId, () => <TpvEmployee>[]).add(
            TpvEmployee(
              id: employee.id,
              code: employee.code,
              name: employee.name,
              sex: _normalizeOptional(employee.sex),
              identityNumber: _normalizeOptional(employee.identityNumber),
              address: _normalizeOptional(employee.address),
              imagePath: _normalizeOptional(employee.imagePath),
              associatedUserId: _normalizeOptional(employee.associatedUserId),
              associatedUsername: null,
              isActive: employee.isActive,
            ),
          );
    }
    return result;
  }

  Future<String> openSession({
    required String terminalId,
    required String userId,
    List<String> responsibleEmployeeIds = const <String>[],
    int openingFloatCents = 0,
    String? note,
  }) async {
    await _licenseService.requireSalesAccess();
    final String safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }
    final PosTerminal? terminal = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.equals(terminalId)))
        .getSingleOrNull();
    if (terminal == null || !terminal.isActive) {
      throw Exception('El TPV seleccionado no es valido.');
    }
    await _assertDemoSessionTerminalAllowed(terminal.id);

    final PosSession? open = await getOpenSessionForTerminal(terminalId);
    if (open != null) {
      throw Exception('Ya existe una sesion abierta en este TPV.');
    }

    final Set<String> responsibleIds = responsibleEmployeeIds
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
    if (responsibleIds.isEmpty) {
      throw Exception('Debes seleccionar al menos un empleado responsable.');
    }
    final List<Employee> employees = await (_db.select(_db.employees)
          ..where((Employees tbl) =>
              tbl.id.isIn(responsibleIds) & tbl.isActive.equals(true)))
        .get();
    if (employees.length != responsibleIds.length) {
      throw Exception('Hay empleados responsables invalidos o inactivos.');
    }
    final LicenseStatus licenseStatus = await _licenseService.current();
    if (!licenseStatus.isFull && responsibleIds.length > 1) {
      throw const LicenseException(
        'Modo demo: cada turno permite un solo empleado responsable.',
      );
    }

    final IpvReport? openIpv = await (_db.select(_db.ipvReports)
          ..where((IpvReports tbl) =>
              tbl.terminalId.equals(terminalId) & tbl.status.equals('open')))
        .getSingleOrNull();
    if (openIpv != null) {
      throw Exception('Ya existe un IPV abierto en este TPV.');
    }

    final String sessionId = _uuid.v4();
    final DateTime openedAt = DateTime.now();
    final _IpvOpeningSnapshot openingSnapshot = await _buildIpvOpeningSnapshot(
      terminalId: terminalId,
      warehouseId: terminal.warehouseId,
    );
    await _db.transaction(() async {
      await _db.into(_db.posSessions).insert(
            PosSessionsCompanion.insert(
              id: sessionId,
              terminalId: terminalId,
              userId: safeUserId,
              openedAt: Value(openedAt),
              openingFloatCents: Value(openingFloatCents),
              note: Value(_normalizeOptional(note)),
            ),
          );

      for (final String employeeId in responsibleIds) {
        await _db.into(_db.posSessionEmployees).insert(
              PosSessionEmployeesCompanion.insert(
                sessionId: sessionId,
                employeeId: employeeId,
                assignedAt: Value(openedAt),
              ),
            );
      }

      final String reportId = _uuid.v4();
      await _db.into(_db.ipvReports).insert(
            IpvReportsCompanion.insert(
              id: reportId,
              terminalId: terminalId,
              warehouseId: terminal.warehouseId,
              sessionId: sessionId,
              openedAt: Value(openedAt),
              openedBy: safeUserId,
              openingSource: Value(openingSnapshot.source),
              note: Value(_normalizeOptional(note)),
            ),
          );

      final Set<String> productIds = openingSnapshot.startQtyByProduct.keys
          .where((String id) => id.trim().isNotEmpty)
          .toSet();
      final Map<String, _IpvProductFrozenInfo> productSnapshotById =
          await _loadProductSnapshotByProduct(productIds);
      for (final String productId in productIds) {
        final double startQty =
            openingSnapshot.startQtyByProduct[productId] ?? 0;
        final _IpvProductFrozenInfo productSnapshot =
            productSnapshotById[productId] ?? _IpvProductFrozenInfo.empty;
        await _db.into(_db.ipvReportLines).insert(
              IpvReportLinesCompanion.insert(
                reportId: reportId,
                productId: productId,
                productNameSnapshot: Value(productSnapshot.name),
                productSkuSnapshot: Value(productSnapshot.sku),
                startQty: Value(startQty),
                entriesQty: const Value(0),
                outputsQty: const Value(0),
                salesQty: const Value(0),
                finalQty: Value(startQty),
                salePriceCents: Value(productSnapshot.priceCents),
                totalAmountCents: const Value(0),
              ),
            );
      }
      final List<String> responsibleEmployeeIdList = responsibleIds.toList()
        ..sort();
      await _logAudit(
        userId: safeUserId,
        action: 'TPV_SESSION_OPENED',
        entity: 'pos_session',
        entityId: sessionId,
        payload: <String, Object?>{
          'terminalId': terminal.id,
          'terminalName': terminal.name,
          'warehouseId': terminal.warehouseId,
          'openedAt': openedAt.toIso8601String(),
          'openingFloatCents': openingFloatCents,
          'responsibleEmployeeIds': responsibleEmployeeIdList,
          'ipvReportId': reportId,
        },
      );
    });
    return sessionId;
  }

  Future<void> _assertDemoSessionTerminalAllowed(String terminalId) async {
    final LicenseStatus licenseStatus = await _licenseService.current();
    if (licenseStatus.isFull) {
      return;
    }

    final PosTerminal? firstTerminal = await (_db.select(_db.posTerminals)
          ..where(
            (PosTerminals tbl) =>
                tbl.isActive.equals(true) &
                tbl.id.isNotNull() &
                tbl.createdAt.isNotNull(),
          )
          ..orderBy(<OrderingTerm Function(PosTerminals)>[
            (PosTerminals tbl) => OrderingTerm.asc(tbl.createdAt),
            (PosTerminals tbl) => OrderingTerm.asc(tbl.name),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (firstTerminal == null) {
      return;
    }
    if (firstTerminal.id != terminalId) {
      throw Exception(
        'Modo demo: solo puedes iniciar sesion en el primer TPV registrado.',
      );
    }
  }

  Future<void> _requireDemoEmployeeSlotForActivation({
    String? excludeEmployeeId,
  }) async {
    final LicenseStatus licenseStatus = await _licenseService.current();
    if (licenseStatus.isFull) {
      return;
    }
    final int activeEmployees = await _countActiveEmployees(
      excludeEmployeeId: excludeEmployeeId,
    );
    if (activeEmployees >= DemoLicenseLimits.maxActiveEmployees) {
      throw const LicenseException(
        'Modo demo: solo puedes tener 1 empleado activo.',
      );
    }
  }

  Future<int> _countActiveEmployees({
    String? excludeEmployeeId,
  }) async {
    final Expression<int> countExp = _db.employees.id.count();
    Expression<bool> predicate = _db.employees.isActive.equals(true);
    final String? cleanExclude = _normalizeOptional(excludeEmployeeId);
    if (cleanExclude != null) {
      predicate = predicate & _db.employees.id.equals(cleanExclude).not();
    }
    final TypedResult row = await (_db.selectOnly(_db.employees)
          ..addColumns(<Expression<Object>>[countExp])
          ..where(predicate))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<Set<String>> _listUserIdsWithPosSalesAccess() async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        ur.user_id AS user_id,
        MAX(CASE WHEN u.is_active = 1 THEN 1 ELSE 0 END) AS is_active,
        MAX(CASE WHEN ur.role_id = ? THEN 1 ELSE 0 END) AS is_admin,
        MAX(CASE WHEN rp.permission_key = ? THEN 1 ELSE 0 END) AS has_tpv,
        MAX(CASE WHEN rp.permission_key = ? THEN 1 ELSE 0 END) AS has_sales_pos
      FROM user_roles ur
      LEFT JOIN users u
        ON u.id = ur.user_id
      LEFT JOIN role_permissions rp
        ON rp.role_id = ur.role_id
      GROUP BY ur.user_id
      HAVING is_active = 1
        AND is_admin = 0
        AND has_tpv = 1
        AND has_sales_pos = 1
      ''',
      variables: <Variable<Object>>[
        const Variable<String>(AppRoleIds.admin),
        const Variable<String>(AppPermissionKeys.tpvView),
        const Variable<String>(AppPermissionKeys.salesPos),
      ],
    ).get();

    return rows
        .map((QueryRow row) => (row.read<String>('user_id')).trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
  }

  Future<bool> _userHasAdminRole(String userId) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return false;
    }
    final User? user = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(cleanUserId)))
        .getSingleOrNull();
    if (user == null) {
      return false;
    }
    if (user.role.trim().toLowerCase() == 'admin' ||
        user.username.trim().toLowerCase() == 'admin') {
      return true;
    }
    final UserRole? role = await (_db.select(_db.userRoles)
          ..where(
            (UserRoles tbl) =>
                tbl.userId.equals(cleanUserId) &
                tbl.roleId.equals(AppRoleIds.admin),
          ))
        .getSingleOrNull();
    return role != null;
  }

  Future<void> _replaceTerminalEmployeeAccess({
    required String terminalId,
    required List<String> employeeIds,
  }) async {
    final String cleanTerminalId = terminalId.trim();
    if (cleanTerminalId.isEmpty) {
      return;
    }
    final Set<String> eligibleEmployeeIds =
        (await listEmployeesEligibleForTerminalAccess())
            .map((TpvEmployee employee) => employee.id)
            .toSet();
    final Set<String> sanitized = employeeIds
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .where((String value) => eligibleEmployeeIds.contains(value))
        .toSet();

    await (_db.delete(_db.posTerminalEmployees)
          ..where(
            (PosTerminalEmployees tbl) =>
                tbl.terminalId.equals(cleanTerminalId),
          ))
        .go();

    for (final String employeeId in sanitized) {
      await _db.into(_db.posTerminalEmployees).insert(
            PosTerminalEmployeesCompanion.insert(
              terminalId: cleanTerminalId,
              employeeId: employeeId,
            ),
          );
    }
  }

  Future<void> _requireWarehouseAvailableForTerminal({
    required String warehouseId,
    required String? excludeTerminalId,
  }) async {
    final String cleanWarehouseId = warehouseId.trim();
    final Warehouse? warehouse = await (_db.select(_db.warehouses)
          ..where((Warehouses tbl) => tbl.id.equals(cleanWarehouseId)))
        .getSingleOrNull();
    if (warehouse == null || !warehouse.isActive) {
      throw Exception('El almacén seleccionado no está disponible.');
    }

    final PosTerminal? owner = await (_db.select(_db.posTerminals)
          ..where(
              (PosTerminals tbl) => tbl.warehouseId.equals(cleanWarehouseId)))
        .getSingleOrNull();
    if (owner != null && owner.id != excludeTerminalId) {
      throw Exception(
        'El almacén "${warehouse.name}" ya está asociado a otro TPV.',
      );
    }
  }

  Future<void> closeSession({
    required String sessionId,
    int? closingCashCents,
    String? note,
    String? closedByUserId,
    Map<int, int>? cashCountByDenomination,
  }) async {
    await _licenseService.requireSalesAccess();
    final String safeSessionId = sessionId.trim();
    if (safeSessionId.isEmpty) {
      throw Exception('La sesion no existe.');
    }
    final PosSession? session = await (_db.select(_db.posSessions)
          ..where((PosSessions tbl) => tbl.id.equals(safeSessionId)))
        .getSingleOrNull();
    if (session == null) {
      throw Exception('La sesion no existe.');
    }
    if (session.status != 'open') {
      throw Exception('La sesion ya esta cerrada.');
    }

    final Map<int, int> sanitizedBreakdown =
        _sanitizeBreakdown(cashCountByDenomination);
    final int? inferredClosingCashCents = sanitizedBreakdown.isEmpty
        ? null
        : _computeClosingCashFromBreakdown(sanitizedBreakdown);
    final int? finalClosingCashCents =
        closingCashCents ?? inferredClosingCashCents;
    final String? safeActorUserId = _normalizeOptional(closedByUserId) ??
        _normalizeOptional(session.userId);
    final DateTime closedAt = DateTime.now();
    final PosTerminal? terminal = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.equals(session.terminalId)))
        .getSingleOrNull();
    if (terminal == null) {
      throw Exception('El TPV de la sesion no existe.');
    }

    await _db.transaction(() async {
      await (_db.update(_db.posSessions)
            ..where((PosSessions tbl) => tbl.id.equals(safeSessionId)))
          .write(
        PosSessionsCompanion(
          status: const Value('closed'),
          closedAt: Value(closedAt),
          closingCashCents: Value(finalClosingCashCents),
          note: Value(_mergeNotes(session.note, note)),
        ),
      );

      await (_db.delete(_db.posSessionCashBreakdowns)
            ..where((PosSessionCashBreakdowns tbl) =>
                tbl.sessionId.equals(safeSessionId)))
          .go();

      for (final MapEntry<int, int> entry in sanitizedBreakdown.entries) {
        await _db.into(_db.posSessionCashBreakdowns).insert(
              PosSessionCashBreakdownsCompanion.insert(
                sessionId: safeSessionId,
                denominationCents: entry.key,
                unitCount: Value(entry.value),
                subtotalCents: Value(entry.key * entry.value),
              ),
            );
      }

      await _closeIpvForSession(
        session: session,
        terminal: terminal,
        closedAt: closedAt,
        closeNote: note,
        closedByUserId: safeActorUserId ?? session.userId,
      );
      await _logAudit(
        userId: safeActorUserId,
        action: 'TPV_SESSION_CLOSED',
        entity: 'pos_session',
        entityId: safeSessionId,
        payload: <String, Object?>{
          'terminalId': terminal.id,
          'terminalName': terminal.name,
          'closedAt': closedAt.toIso8601String(),
          'openingFloatCents': session.openingFloatCents,
          'closingCashCents': finalClosingCashCents,
          'cashBreakdown': sanitizedBreakdown,
          'note': _normalizeOptional(note),
        },
      );
    });
  }

  Future<Map<String, int>> getSessionExpectedPaymentsByMethod(
    String sessionId,
  ) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        p.method AS method,
        COALESCE(SUM(p.amount_cents), 0) AS total_cents
      FROM payments p
      INNER JOIN sales s
        ON s.id = p.sale_id
      WHERE s.terminal_session_id = ?
        AND s.status = 'posted'
      GROUP BY p.method
      ''',
      variables: <Variable<Object>>[Variable<String>(sessionId)],
    ).get();

    final Map<String, int> result = <String, int>{};
    for (final QueryRow row in rows) {
      final String method = row.read<String>('method').trim().toLowerCase();
      if (method.isEmpty) {
        continue;
      }
      final int amount = row.read<int>('total_cents');
      result[method] = (result[method] ?? 0) + amount;
    }
    return result;
  }

  Future<TpvSessionSalesSummary> getSessionSalesSummary(
      String sessionId) async {
    final String safeSessionId = sessionId.trim();
    if (safeSessionId.isEmpty) {
      return const TpvSessionSalesSummary(
        postedSalesCount: 0,
        postedSubtotalCents: 0,
        postedTaxCents: 0,
        postedTotalCents: 0,
        archivedSalesCount: 0,
      );
    }

    final QueryRow? row = await _db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN LOWER(COALESCE(s.status, '')) = 'posted' THEN 1 ELSE 0 END), 0) AS posted_count,
        COALESCE(SUM(CASE WHEN LOWER(COALESCE(s.status, '')) = 'posted' THEN s.subtotal_cents ELSE 0 END), 0) AS posted_subtotal_cents,
        COALESCE(SUM(CASE WHEN LOWER(COALESCE(s.status, '')) = 'posted' THEN s.tax_cents ELSE 0 END), 0) AS posted_tax_cents,
        COALESCE(SUM(CASE WHEN LOWER(COALESCE(s.status, '')) = 'posted' THEN s.total_cents ELSE 0 END), 0) AS posted_total_cents,
        COALESCE(SUM(CASE WHEN LOWER(COALESCE(s.status, '')) = 'archived' THEN 1 ELSE 0 END), 0) AS archived_count
      FROM sales s
      WHERE s.terminal_session_id = ?
      ''',
      variables: <Variable<Object>>[Variable<String>(safeSessionId)],
    ).getSingleOrNull();

    return TpvSessionSalesSummary(
      postedSalesCount: (row?.data['posted_count'] as num?)?.toInt() ?? 0,
      postedSubtotalCents:
          (row?.data['posted_subtotal_cents'] as num?)?.toInt() ?? 0,
      postedTaxCents: (row?.data['posted_tax_cents'] as num?)?.toInt() ?? 0,
      postedTotalCents: (row?.data['posted_total_cents'] as num?)?.toInt() ?? 0,
      archivedSalesCount: (row?.data['archived_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<TpvSessionSaleView>> listSessionSales(
    String sessionId, {
    int limit = 200,
    int offset = 0,
  }) async {
    final String safeSessionId = sessionId.trim();
    if (safeSessionId.isEmpty) {
      return <TpvSessionSaleView>[];
    }
    final int safeLimit = limit < 1 ? 1 : limit;
    final int safeOffset = offset < 0 ? 0 : offset;
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        s.id AS sale_id,
        COALESCE(s.folio, '-') AS folio,
        s.created_at AS created_at,
        COALESCE(s.subtotal_cents, 0) AS subtotal_cents,
        COALESCE(s.tax_cents, 0) AS tax_cents,
        COALESCE(s.total_cents, 0) AS total_cents,
        LOWER(COALESCE(s.status, 'posted')) AS status,
        c.full_name AS customer_name,
        COALESCE(GROUP_CONCAT(DISTINCT LOWER(COALESCE(p.method, ''))), '') AS methods
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      LEFT JOIN payments p ON p.sale_id = s.id
      WHERE s.terminal_session_id = ?
      GROUP BY
        s.id,
        s.folio,
        s.created_at,
        s.subtotal_cents,
        s.tax_cents,
        s.total_cents,
        s.status,
        c.full_name
      ORDER BY s.created_at DESC
      LIMIT ?
      OFFSET ?
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeSessionId),
        Variable<int>(safeLimit),
        Variable<int>(safeOffset),
      ],
    ).get();

    return rows.map((QueryRow row) {
      final String rawMethods =
          (row.readNullable<String>('methods') ?? '').trim();
      final List<String> methods = rawMethods.isEmpty
          ? const <String>[]
          : rawMethods
              .split(',')
              .map((String value) => value.trim())
              .where((String value) => value.isNotEmpty)
              .toSet()
              .toList()
        ..sort();
      final String customerName =
          (row.readNullable<String>('customer_name') ?? '').trim();
      return TpvSessionSaleView(
        saleId: (row.readNullable<String>('sale_id') ?? '').trim(),
        folio: (row.readNullable<String>('folio') ?? '-').trim(),
        createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
        subtotalCents: (row.data['subtotal_cents'] as num?)?.toInt() ?? 0,
        taxCents: (row.data['tax_cents'] as num?)?.toInt() ?? 0,
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
        status: (row.readNullable<String>('status') ?? 'posted').trim(),
        customerName: customerName.isEmpty ? null : customerName,
        paymentMethods: methods,
      );
    }).toList(growable: false);
  }

  Future<void> reconcileIpvReport({
    required String reportId,
    required String userId,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeReportId = reportId.trim();
    final String safeUserId = userId.trim();
    if (safeReportId.isEmpty) {
      throw Exception('Reporte IPV inválido.');
    }
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }

    await _db.transaction(() async {
      final IpvReport? report = await (_db.select(_db.ipvReports)
            ..where((IpvReports tbl) => tbl.id.equals(safeReportId)))
          .getSingleOrNull();
      if (report == null) {
        throw Exception('El reporte IPV no existe.');
      }

      final DateTime movementStart = await _resolveMovementStartForReport(
        terminalId: report.terminalId,
        openedAt: report.openedAt,
        currentReportId: report.id,
      );
      final DateTime movementEnd = report.closedAt ?? DateTime.now();

      await _recalculateIpvReportLines(
        report: report,
        movementStart: movementStart,
        movementEnd: movementEnd,
      );

      final String? note = _mergeNotes(
        report.note,
        'Reconciliado ${DateTime.now().toIso8601String()} por $safeUserId',
      );
      await (_db.update(_db.ipvReports)
            ..where((IpvReports tbl) => tbl.id.equals(report.id)))
          .write(
        IpvReportsCompanion(
          note: Value(note),
          closedBy: report.status == 'closed'
              ? Value(safeUserId)
              : const Value.absent(),
        ),
      );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'IPV_RECONCILED',
              entity: 'ipv_report',
              entityId: report.id,
              payloadJson: jsonEncode(<String, Object?>{
                'sessionId': report.sessionId,
                'status': report.status,
                'movementStart': movementStart.toIso8601String(),
                'movementEnd': movementEnd.toIso8601String(),
              }),
            ),
          );
    });
  }

  Future<List<TpvSessionCashBreakdown>> listSessionCashBreakdown(
    String sessionId,
  ) async {
    final List<PosSessionCashBreakdown> rows =
        await (_db.select(_db.posSessionCashBreakdowns)
              ..where((PosSessionCashBreakdowns tbl) =>
                  tbl.sessionId.equals(sessionId))
              ..orderBy(<OrderingTerm Function(PosSessionCashBreakdowns)>[
                (PosSessionCashBreakdowns tbl) =>
                    OrderingTerm.desc(tbl.denominationCents),
              ]))
            .get();

    return rows
        .map(
          (PosSessionCashBreakdown row) => TpvSessionCashBreakdown(
            denominationCents: row.denominationCents,
            unitCount: row.unitCount,
          ),
        )
        .toList();
  }

  Future<Map<String, List<TpvSessionCashBreakdown>>>
      listCashBreakdownForSessions(Iterable<String> sessionIds) async {
    final Set<String> ids = sessionIds.toSet();
    if (ids.isEmpty) {
      return <String, List<TpvSessionCashBreakdown>>{};
    }

    final List<PosSessionCashBreakdown> rows =
        await (_db.select(_db.posSessionCashBreakdowns)
              ..where((PosSessionCashBreakdowns tbl) => tbl.sessionId.isIn(ids))
              ..orderBy(<OrderingTerm Function(PosSessionCashBreakdowns)>[
                (PosSessionCashBreakdowns tbl) =>
                    OrderingTerm.desc(tbl.denominationCents),
              ]))
            .get();

    final Map<String, List<TpvSessionCashBreakdown>> result =
        <String, List<TpvSessionCashBreakdown>>{};
    for (final PosSessionCashBreakdown row in rows) {
      result.putIfAbsent(row.sessionId, () => <TpvSessionCashBreakdown>[]).add(
            TpvSessionCashBreakdown(
              denominationCents: row.denominationCents,
              unitCount: row.unitCount,
            ),
          );
    }
    return result;
  }

  Future<List<TpvSessionWithUser>> listSessionHistory(
    String terminalId, {
    int limit = 50,
  }) async {
    final List<PosSession> sessions = await (_db.select(_db.posSessions)
          ..where((PosSessions tbl) => tbl.terminalId.equals(terminalId))
          ..orderBy(<OrderingTerm Function(PosSessions)>[
            (PosSessions tbl) => OrderingTerm.desc(tbl.openedAt),
          ])
          ..limit(limit))
        .get();

    if (sessions.isEmpty) {
      return <TpvSessionWithUser>[];
    }

    final Set<String> userIds =
        sessions.map((PosSession session) => session.userId).toSet();
    final List<User> users = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.isIn(userIds)))
        .get();
    final Map<String, User> userById = <String, User>{
      for (final User user in users) user.id: user,
    };
    final Map<String, List<TpvEmployee>> responsibleBySessionId =
        await listResponsibleEmployeesForSessions(
      sessions.map((PosSession session) => session.id),
    );

    final List<TpvSessionWithUser> result = <TpvSessionWithUser>[];
    for (final PosSession session in sessions) {
      final User? user = userById[session.userId];
      if (user == null) {
        continue;
      }
      result.add(
        TpvSessionWithUser(
          session: session,
          user: user,
          responsibleEmployees:
              responsibleBySessionId[session.id] ?? const <TpvEmployee>[],
        ),
      );
    }
    return result;
  }

  Future<String> suggestTerminalCode(String name) {
    final String cleanName = name.trim();
    if (cleanName.isEmpty) {
      return Future<String>.value('TPV-01');
    }
    return _resolveTerminalCode(
      name: cleanName,
      code: null,
      excludeTerminalId: null,
    );
  }

  Future<String> _resolveTerminalCode({
    required String name,
    required String? code,
    required String? excludeTerminalId,
  }) async {
    final String explicit = _normalizeCode(code);
    if (explicit.isNotEmpty) {
      final bool exists = await _terminalCodeExists(
        explicit,
        excludeTerminalId: excludeTerminalId,
      );
      if (exists) {
        throw Exception('El codigo del TPV ya existe.');
      }
      return explicit;
    }

    final String seed = _generateCodeSeed(name);
    String candidate = seed;
    int suffix = 2;
    while (await _terminalCodeExists(
      candidate,
      excludeTerminalId: excludeTerminalId,
    )) {
      candidate = '$seed-$suffix';
      suffix += 1;
    }
    return candidate;
  }

  Future<bool> _terminalCodeExists(
    String code, {
    required String? excludeTerminalId,
  }) async {
    final String normalized = _normalizeCode(code);
    final List<PosTerminal> rows = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.code.equals(normalized)))
        .get();
    if (rows.isEmpty) {
      return false;
    }
    for (final PosTerminal row in rows) {
      if (excludeTerminalId == null || row.id != excludeTerminalId) {
        return true;
      }
    }
    return false;
  }

  Future<String> suggestEmployeeCode(String name) {
    final String cleanName = _normalizeEmployeeName(name);
    if (cleanName.isEmpty) {
      return Future<String>.value('EMP-01');
    }
    return _resolveEmployeeCode(
      preferredCode: null,
      name: cleanName,
      excludeEmployeeId: null,
    );
  }

  Future<String> _resolveEmployeeCode({
    required String? preferredCode,
    required String name,
    required String? excludeEmployeeId,
  }) async {
    final String explicit = _normalizeEmployeeCode(preferredCode);
    if (explicit.isNotEmpty) {
      final bool exists = await _employeeCodeExists(
        explicit,
        excludeEmployeeId: excludeEmployeeId,
      );
      if (exists) {
        throw Exception('El codigo del empleado ya existe.');
      }
      return explicit;
    }

    final String slug = _slug(name).toUpperCase();
    final String seed = slug.isEmpty
        ? 'EMP'
        : 'EMP-${slug.substring(0, math.min(6, slug.length))}';
    String code = seed;
    int suffix = 2;
    while (
        await _employeeCodeExists(code, excludeEmployeeId: excludeEmployeeId)) {
      code = '$seed-$suffix';
      suffix += 1;
    }
    return code;
  }

  Future<bool> _employeeCodeExists(
    String code, {
    required String? excludeEmployeeId,
  }) async {
    final String normalized = _normalizeEmployeeCode(code);
    final List<Employee> rows = await (_db.select(_db.employees)
          ..where((Employees tbl) => tbl.code.equals(normalized)))
        .get();
    if (rows.isEmpty) {
      return false;
    }
    for (final Employee row in rows) {
      if (excludeEmployeeId == null || row.id != excludeEmployeeId) {
        return true;
      }
    }
    return false;
  }

  String _normalizeEmployeeName(String raw) {
    return raw.trim();
  }

  String _normalizeEmployeeCode(String? raw) {
    return (raw ?? '').trim().toUpperCase();
  }

  String? _normalizeEmployeeSex(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    if (value.isEmpty) {
      return null;
    }
    if (value == 'M' || value == 'F' || value == 'X') {
      return value;
    }
    return null;
  }

  Future<_IpvOpeningSnapshot> _buildIpvOpeningSnapshot({
    required String terminalId,
    required String warehouseId,
  }) async {
    final IpvReport? previous = await (_db.select(_db.ipvReports)
          ..where((IpvReports tbl) =>
              tbl.terminalId.equals(terminalId) &
              tbl.status.equals('closed') &
              tbl.closedAt.isNotNull())
          ..orderBy(<OrderingTerm Function(IpvReports)>[
            (IpvReports tbl) => OrderingTerm.desc(tbl.closedAt),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (previous != null) {
      final List<IpvReportLine> previousLines = await (_db
              .select(_db.ipvReportLines)
            ..where((IpvReportLines tbl) => tbl.reportId.equals(previous.id)))
          .get();
      final Map<String, double> byProduct = <String, double>{};
      for (final IpvReportLine line in previousLines) {
        byProduct[line.productId] = line.finalQty;
      }
      return _IpvOpeningSnapshot(
        source: 'previous_final',
        startQtyByProduct: byProduct,
      );
    }

    final List<StockBalance> balances = await (_db.select(_db.stockBalances)
          ..where((StockBalances tbl) => tbl.warehouseId.equals(warehouseId)))
        .get();
    final Map<String, double> byProduct = <String, double>{};
    for (final StockBalance row in balances) {
      if (row.qty.abs() < 0.000001) {
        continue;
      }
      byProduct[row.productId] = row.qty;
    }
    return _IpvOpeningSnapshot(
      source: 'initial_stock',
      startQtyByProduct: byProduct,
    );
  }

  Future<void> _closeIpvForSession({
    required PosSession session,
    required PosTerminal terminal,
    required DateTime closedAt,
    required String? closeNote,
    required String closedByUserId,
  }) async {
    IpvReport? report = await (_db.select(_db.ipvReports)
          ..where((IpvReports tbl) => tbl.sessionId.equals(session.id)))
        .getSingleOrNull();
    if (report == null) {
      final _IpvOpeningSnapshot snapshot = await _buildIpvOpeningSnapshot(
        terminalId: terminal.id,
        warehouseId: terminal.warehouseId,
      );
      final String reportId = _uuid.v4();
      await _db.into(_db.ipvReports).insert(
            IpvReportsCompanion.insert(
              id: reportId,
              terminalId: terminal.id,
              warehouseId: terminal.warehouseId,
              sessionId: session.id,
              openedAt: Value(session.openedAt),
              openedBy: session.userId,
              openingSource: Value(snapshot.source),
              note: Value(_normalizeOptional(session.note)),
            ),
          );
      report = await (_db.select(_db.ipvReports)
            ..where((IpvReports tbl) => tbl.id.equals(reportId)))
          .getSingle();
    }
    final IpvReport activeReport = report;
    if (activeReport.status != 'open') {
      return;
    }

    final IpvReport? previousClosed = await (_db.select(_db.ipvReports)
          ..where((IpvReports tbl) =>
              tbl.terminalId.equals(terminal.id) &
              tbl.status.equals('closed') &
              tbl.closedAt.isNotNull() &
              tbl.id.isNotValue(activeReport.id))
          ..orderBy(<OrderingTerm Function(IpvReports)>[
            (IpvReports tbl) => OrderingTerm.desc(tbl.closedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
    final DateTime movementStart =
        previousClosed?.closedAt ?? activeReport.openedAt;

    await _recalculateIpvReportLines(
      report: activeReport,
      movementStart: movementStart,
      movementEnd: closedAt,
    );

    await (_db.update(_db.ipvReports)
          ..where((IpvReports tbl) => tbl.id.equals(activeReport.id)))
        .write(
      IpvReportsCompanion(
        status: const Value('closed'),
        closedAt: Value(closedAt),
        closedBy: Value(closedByUserId),
        note: Value(_mergeNotes(activeReport.note, closeNote)),
      ),
    );
  }

  Future<void> _recalculateIpvReportLines({
    required IpvReport report,
    required DateTime movementStart,
    required DateTime movementEnd,
  }) async {
    final List<IpvReportLine> existingLines =
        await (_db.select(_db.ipvReportLines)
              ..where((IpvReportLines tbl) => tbl.reportId.equals(report.id)))
            .get();
    final Map<String, double> resolvedStartQtyByProduct =
        await _resolveStartQtyForReconciliation(
      report: report,
      existingLines: existingLines,
    );
    final Map<String, _IpvLineAccumulator> byProduct =
        <String, _IpvLineAccumulator>{
      for (final MapEntry<String, double> entry
          in resolvedStartQtyByProduct.entries)
        entry.key: _IpvLineAccumulator(startQty: entry.value),
    };

    final List<QueryRow> movementRows = await _db.customSelect(
      '''
      SELECT
        sm.product_id AS product_id,
        COALESCE(SUM(
          CASE
            WHEN (
              (sm.type = 'in')
              OR (sm.type = 'adjust' AND sm.qty >= 0)
            )
            AND LOWER(COALESCE(sm.reason_code, '')) <> 'sale'
              THEN ABS(sm.qty)
            ELSE 0
          END
        ), 0) AS entries_qty,
        COALESCE(SUM(
          CASE
            WHEN (
              (sm.type = 'out')
              OR (sm.type = 'adjust' AND sm.qty < 0)
            )
            AND NOT (
              (
                LOWER(COALESCE(sm.reason_code, '')) IN (
                  'sale',
                  'consignment_sale'
                )
                OR LOWER(COALESCE(sm.ref_type, '')) IN (
                  'sale',
                  'sale_pos',
                  'sale_direct',
                  'consignment_sale',
                  'consignment_sale_pos',
                  'consignment_sale_direct'
                )
                OR LOWER(COALESCE(sm.movement_source, '')) IN (
                  'pos',
                  'direct_sale',
                  'pos_consignment',
                  'direct_consignment'
                )
              )
            )
              THEN ABS(sm.qty)
            ELSE 0
          END
        ), 0) AS outputs_qty,
        COALESCE(SUM(
          CASE
            WHEN (
              (sm.type = 'out')
              OR (sm.type = 'adjust' AND sm.qty < 0)
            )
            AND (
              (
                LOWER(COALESCE(sm.reason_code, '')) IN (
                  'sale',
                  'consignment_sale'
                )
                OR LOWER(COALESCE(sm.ref_type, '')) IN (
                  'sale',
                  'sale_pos',
                  'sale_direct',
                  'consignment_sale',
                  'consignment_sale_pos',
                  'consignment_sale_direct'
                )
                OR LOWER(COALESCE(sm.movement_source, '')) IN (
                  'pos',
                  'direct_sale',
                  'pos_consignment',
                  'direct_consignment'
                )
              )
            )
              THEN ABS(sm.qty)
            ELSE 0
          END
        ), 0) AS sales_qty
      FROM stock_movements sm
      WHERE sm.warehouse_id = ?
        AND sm.created_at > ?
        AND sm.created_at <= ?
        AND COALESCE(sm.is_voided, 0) = 0
      GROUP BY sm.product_id
      ''',
      variables: <Variable<Object>>[
        Variable<String>(report.warehouseId),
        Variable<DateTime>(movementStart),
        Variable<DateTime>(movementEnd),
      ],
    ).get();

    for (final QueryRow row in movementRows) {
      final String productId =
          (row.readNullable<String>('product_id') ?? '').trim();
      if (productId.isEmpty) {
        continue;
      }
      final _IpvLineAccumulator acc = byProduct.putIfAbsent(
        productId,
        () => _IpvLineAccumulator(startQty: 0),
      );
      acc.entriesQty = (row.data['entries_qty'] as num?)?.toDouble() ?? 0;
      acc.outputsQty = (row.data['outputs_qty'] as num?)?.toDouble() ?? 0;
      acc.salesQty = (row.data['sales_qty'] as num?)?.toDouble() ?? 0;
    }

    final Map<String, _IpvSalesAggregate> salesByProduct =
        await _loadSessionSalesByProduct(report.sessionId);
    for (final MapEntry<String, _IpvSalesAggregate> entry
        in salesByProduct.entries) {
      final _IpvLineAccumulator acc = byProduct.putIfAbsent(
        entry.key,
        () => _IpvLineAccumulator(startQty: 0),
      );
      if (acc.salesQty.abs() <= 0.000001) {
        acc.salesQty = entry.value.qty;
      }
    }

    final Set<String> productIds = byProduct.keys.toSet();
    final Map<String, _IpvProductFrozenInfo> productSnapshotById =
        await _loadProductSnapshotByProduct(productIds);
    final Set<String> existingProductIds =
        existingLines.map((IpvReportLine row) => row.productId).toSet();

    for (final MapEntry<String, _IpvLineAccumulator> entry
        in byProduct.entries) {
      final String productId = entry.key;
      final _IpvLineAccumulator acc = entry.value;
      final _IpvProductFrozenInfo productSnapshot =
          productSnapshotById[productId] ?? _IpvProductFrozenInfo.empty;
      final _IpvSalesAggregate? salesAgg = salesByProduct[productId];
      final int amountCents = salesAgg?.totalAmountCents ??
          (acc.salesQty * productSnapshot.priceCents).round();
      double qtyForPrice = acc.salesQty;
      if (qtyForPrice.abs() <= 0.000001) {
        qtyForPrice = salesAgg?.qty ?? 0;
      }
      final int priceCents = qtyForPrice.abs() > 0.000001
          ? (amountCents / qtyForPrice).round()
          : productSnapshot.priceCents;
      final int realProfitCents = salesAgg?.profitCents ?? 0;
      final int marginCents = salesAgg?.unitMarginCents ?? 0;
      final double finalQty =
          acc.startQty + acc.entriesQty - acc.outputsQty - acc.salesQty;
      final IpvReportLinesCompanion payload = IpvReportLinesCompanion(
        reportId: Value(report.id),
        productId: Value(productId),
        productNameSnapshot: Value(productSnapshot.name),
        productSkuSnapshot: Value(productSnapshot.sku),
        startQty: Value(acc.startQty),
        entriesQty: Value(acc.entriesQty),
        outputsQty: Value(acc.outputsQty),
        salesQty: Value(acc.salesQty),
        finalQty: Value(finalQty),
        salePriceCents: Value(priceCents),
        totalAmountCents: Value(amountCents),
        profitMarginCents: Value(marginCents),
        realProfitCents: Value(realProfitCents),
      );
      if (existingProductIds.contains(productId)) {
        await (_db.update(_db.ipvReportLines)
              ..where((IpvReportLines tbl) =>
                  tbl.reportId.equals(report.id) &
                  tbl.productId.equals(productId)))
            .write(payload);
      } else {
        await _db.into(_db.ipvReportLines).insert(
              IpvReportLinesCompanion.insert(
                reportId: report.id,
                productId: productId,
                productNameSnapshot: Value(productSnapshot.name),
                productSkuSnapshot: Value(productSnapshot.sku),
                startQty: Value(acc.startQty),
                entriesQty: Value(acc.entriesQty),
                outputsQty: Value(acc.outputsQty),
                salesQty: Value(acc.salesQty),
                finalQty: Value(finalQty),
                salePriceCents: Value(priceCents),
                totalAmountCents: Value(amountCents),
                profitMarginCents: Value(marginCents),
                realProfitCents: Value(realProfitCents),
              ),
            );
      }
    }
  }

  Future<Map<String, double>> _resolveStartQtyForReconciliation({
    required IpvReport report,
    required List<IpvReportLine> existingLines,
  }) async {
    final Map<String, double> fallback = <String, double>{
      for (final IpvReportLine line in existingLines)
        line.productId: line.startQty,
    };
    final QueryRow? previousRow = await _db.customSelect(
      '''
      SELECT r.id AS report_id
      FROM ipv_reports r
      WHERE r.terminal_id = ?
        AND r.status = 'closed'
        AND r.closed_at IS NOT NULL
        AND r.id <> ?
        AND r.closed_at <= ?
      ORDER BY r.closed_at DESC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(report.terminalId),
        Variable<String>(report.id),
        Variable<DateTime>(report.openedAt),
      ],
    ).getSingleOrNull();
    final String previousReportId =
        (previousRow?.readNullable<String>('report_id') ?? '').trim();
    if (previousReportId.isEmpty) {
      return fallback;
    }

    final List<IpvReportLine> previousLines = await (_db
            .select(_db.ipvReportLines)
          ..where(
              (IpvReportLines tbl) => tbl.reportId.equals(previousReportId)))
        .get();
    if (previousLines.isEmpty) {
      return fallback;
    }

    final Map<String, double> resolved = <String, double>{
      for (final IpvReportLine line in previousLines)
        line.productId: line.finalQty,
    };
    for (final IpvReportLine line in existingLines) {
      resolved.putIfAbsent(line.productId, () => line.startQty);
    }
    return resolved;
  }

  Future<DateTime> _resolveMovementStartForReport({
    required String terminalId,
    required DateTime openedAt,
    required String currentReportId,
  }) async {
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT r.closed_at AS closed_at
      FROM ipv_reports r
      WHERE r.terminal_id = ?
        AND r.status = 'closed'
        AND r.closed_at IS NOT NULL
        AND r.id <> ?
        AND r.closed_at <= ?
      ORDER BY r.closed_at DESC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(terminalId),
        Variable<String>(currentReportId),
        Variable<DateTime>(openedAt),
      ],
    ).getSingleOrNull();
    return row?.read<DateTime>('closed_at') ?? openedAt;
  }

  Future<Map<String, _IpvSalesAggregate>> _loadSessionSalesByProduct(
    String sessionId,
  ) async {
    final String safeSessionId = sessionId.trim();
    if (safeSessionId.isEmpty) {
      return <String, _IpvSalesAggregate>{};
    }

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        si.product_id AS product_id,
        COALESCE(SUM(si.qty), 0) AS sales_qty,
        COALESCE(SUM(si.line_total_cents), 0) AS total_amount_cents,
        COALESCE(
          SUM(
            COALESCE(
              si.line_subtotal_cents,
              CAST(ROUND(COALESCE(si.qty, 0) * COALESCE(si.unit_price_cents, 0)) AS INTEGER)
            )
          ),
          0
        ) AS subtotal_cents,
        COALESCE(
          SUM(
            COALESCE(
              si.line_cost_cents,
              CAST(ROUND(COALESCE(si.qty, 0) * COALESCE(si.unit_cost_cents, 0)) AS INTEGER)
            )
          ),
          0
        ) AS cost_cents
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE s.terminal_session_id = ?
        AND s.status = 'posted'
      GROUP BY si.product_id
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeSessionId),
      ],
    ).get();

    return <String, _IpvSalesAggregate>{
      for (final QueryRow row in rows)
        (row.readNullable<String>('product_id') ?? '').trim():
            _IpvSalesAggregate(
          qty: (row.data['sales_qty'] as num?)?.toDouble() ?? 0,
          totalAmountCents:
              (row.data['total_amount_cents'] as num?)?.toInt() ?? 0,
          subtotalCents: (row.data['subtotal_cents'] as num?)?.toInt() ?? 0,
          costCents: (row.data['cost_cents'] as num?)?.toInt() ?? 0,
        ),
    }..removeWhere((String key, _IpvSalesAggregate value) => key.isEmpty);
  }

  Future<Map<String, _IpvProductFrozenInfo>> _loadProductSnapshotByProduct(
    Set<String> productIds,
  ) async {
    if (productIds.isEmpty) {
      return <String, _IpvProductFrozenInfo>{};
    }
    final List<Product> rows = await (_db.select(_db.products)
          ..where((Products tbl) => tbl.id.isIn(productIds)))
        .get();
    return <String, _IpvProductFrozenInfo>{
      for (final Product product in rows)
        product.id: _IpvProductFrozenInfo(
          name: product.name.trim().isEmpty ? 'Producto' : product.name.trim(),
          sku: product.sku.trim().isEmpty ? '-' : product.sku.trim(),
          priceCents: product.priceCents,
        ),
    };
  }

  String _generateCodeSeed(String name) {
    final String slug = _slug(name).toUpperCase();
    if (slug.isEmpty) {
      return 'TPV-01';
    }
    final int max = math.min(8, slug.length);
    return 'TPV-${slug.substring(0, max)}';
  }

  String _slug(String value) {
    final String cleaned = value.trim().toLowerCase();
    return cleaned
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _normalizeCode(String? value) {
    return (value ?? '').trim().toUpperCase();
  }

  TpvTerminalConfig _sanitizeConfig(TpvTerminalConfig? raw) {
    final TpvTerminalConfig safe = raw ?? TpvTerminalConfig.defaults;
    return TpvTerminalConfig(
      currencyCode: _sanitizeCurrencyCode(safe.currencyCode),
      currencySymbol: _sanitizeCurrencySymbol(safe.currencySymbol),
      paymentMethods: _sanitizePaymentMethods(safe.paymentMethods),
      cashDenominationsCents:
          _sanitizeDenominations(safe.cashDenominationsCents),
      useCashDenominationsOnClose: safe.useCashDenominationsOnClose,
      allowDiscounts: safe.allowDiscounts,
    );
  }

  String _encodeCashDenominationsConfig(TpvTerminalConfig config) {
    return jsonEncode(
      <String, Object>{
        'denominations': config.cashDenominationsCents,
        'useOnClose': config.useCashDenominationsOnClose,
        'allowDiscounts': config.allowDiscounts,
      },
    );
  }

  ({List<int> denominations, bool useOnClose, bool allowDiscounts})
      _decodeCashDenominationsConfig(
    String raw,
  ) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List<Object?>) {
        return (
          denominations: decoded
              .whereType<num>()
              .map((num item) => item.toInt())
              .toList(growable: false),
          useOnClose: true,
          allowDiscounts: false,
        );
      }
      if (decoded is Map<String, Object?>) {
        final Object? rawDenominations = decoded['denominations'];
        final List<int> denominations = rawDenominations is List<Object?>
            ? rawDenominations
                .whereType<num>()
                .map((num item) => item.toInt())
                .toList(growable: false)
            : <int>[];
        final bool useOnClose = decoded['useOnClose'] != false &&
            decoded['useCashDenominationsOnClose'] != false;
        final bool allowDiscounts = decoded['allowDiscounts'] == true ||
            decoded['allowSaleDiscounts'] == true;
        return (
          denominations: denominations,
          useOnClose: useOnClose,
          allowDiscounts: allowDiscounts,
        );
      }
    } catch (_) {}
    return (
      denominations: _decodeIntList(raw),
      useOnClose: true,
      allowDiscounts: false,
    );
  }

  String _sanitizeCurrencyCode(String raw) {
    final String value = raw.trim().toUpperCase();
    if (value.isEmpty) {
      return TpvTerminalConfig.defaults.currencyCode;
    }
    return value.length > 6 ? value.substring(0, 6) : value;
  }

  String _sanitizeCurrencySymbol(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return TpvTerminalConfig.defaults.currencySymbol;
    }
    return value.length > 4 ? value.substring(0, 4) : value;
  }

  List<String> _sanitizePaymentMethods(List<String> raw) {
    final List<String> normalized = <String>[];
    for (final String method in raw) {
      final String clean = method.trim().toLowerCase();
      if (clean.isEmpty || !kAllowedPaymentMethods.contains(clean)) {
        continue;
      }
      if (!normalized.contains(clean)) {
        normalized.add(clean);
      }
    }
    if (normalized.isEmpty) {
      return <String>['cash'];
    }
    return normalized;
  }

  List<int> _sanitizeDenominations(List<int> raw) {
    final List<int> normalized = raw
        .where((int value) => value > 0)
        .toSet()
        .toList()
      ..sort((int a, int b) => b.compareTo(a));
    if (normalized.isEmpty) {
      return List<int>.from(TpvTerminalConfig.defaults.cashDenominationsCents);
    }
    return normalized;
  }

  List<String> _decodeStringList(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) {
        return <String>[];
      }
      return decoded
          .whereType<String>()
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toList();
    } catch (_) {
      return <String>[];
    }
  }

  List<int> _decodeIntList(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) {
        return <int>[];
      }
      final List<int> values = <int>[];
      for (final Object? item in decoded) {
        if (item is int) {
          values.add(item);
          continue;
        }
        if (item is double) {
          values.add(item.round());
          continue;
        }
        if (item is String) {
          final int? parsed = int.tryParse(item.trim());
          if (parsed != null) {
            values.add(parsed);
          }
        }
      }
      return values;
    } catch (_) {
      return <int>[];
    }
  }

  String? _normalizeOptional(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
  }

  String? _mergeNotes(String? original, String? extra) {
    final String? cleanOriginal = _normalizeOptional(original);
    final String? cleanExtra = _normalizeOptional(extra);
    if (cleanOriginal == null) {
      return cleanExtra;
    }
    if (cleanExtra == null) {
      return cleanOriginal;
    }
    return '$cleanOriginal | $cleanExtra';
  }

  Map<int, int> _sanitizeBreakdown(Map<int, int>? raw) {
    if (raw == null || raw.isEmpty) {
      return <int, int>{};
    }
    final Map<int, int> result = <int, int>{};
    for (final MapEntry<int, int> entry in raw.entries) {
      if (entry.key <= 0 || entry.value <= 0) {
        continue;
      }
      result[entry.key] = entry.value;
    }
    return result;
  }

  int _computeClosingCashFromBreakdown(Map<int, int> breakdown) {
    int total = 0;
    for (final MapEntry<int, int> entry in breakdown.entries) {
      total += entry.key * entry.value;
    }
    return total;
  }
}

class _IpvOpeningSnapshot {
  const _IpvOpeningSnapshot({
    required this.source,
    required this.startQtyByProduct,
  });

  final String source;
  final Map<String, double> startQtyByProduct;
}

class _IpvLineAccumulator {
  _IpvLineAccumulator({
    required this.startQty,
  });

  final double startQty;
  double entriesQty = 0;
  double outputsQty = 0;
  double salesQty = 0;
}

class _IpvSalesAggregate {
  const _IpvSalesAggregate({
    required this.qty,
    required this.totalAmountCents,
    required this.subtotalCents,
    required this.costCents,
  });

  final double qty;
  final int totalAmountCents;
  final int subtotalCents;
  final int costCents;

  int get profitCents => subtotalCents - costCents;

  int get unitMarginCents {
    if (qty.abs() <= 0.000001) {
      return 0;
    }
    return (profitCents / qty).round();
  }
}

class _IpvProductFrozenInfo {
  const _IpvProductFrozenInfo({
    required this.name,
    required this.sku,
    required this.priceCents,
  });

  static const _IpvProductFrozenInfo empty = _IpvProductFrozenInfo(
    name: 'Producto',
    sku: '-',
    priceCents: 0,
  );

  final String name;
  final String sku;
  final int priceCents;
}
