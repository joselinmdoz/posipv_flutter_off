import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';

class ClienteListItem {
  const ClienteListItem({
    required this.id,
    required this.code,
    required this.fullName,
    required this.identityNumber,
    required this.phone,
    required this.email,
    required this.avatarPath,
    required this.customerType,
    required this.isVip,
    required this.creditAvailableCents,
    required this.discountBps,
    required this.lifetimeSpentCents,
    required this.lastPurchaseAt,
    required this.lastPurchaseCents,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String fullName;
  final String? identityNumber;
  final String? phone;
  final String? email;
  final String? avatarPath;
  final String customerType;
  final bool isVip;
  final int creditAvailableCents;
  final int discountBps;
  final int lifetimeSpentCents;
  final DateTime? lastPurchaseAt;
  final int? lastPurchaseCents;
  final DateTime createdAt;

  bool get isFrequent => customerType == 'frecuente';
  bool get isWholesale => customerType == 'mayorista';
  bool get isNew => customerType == 'nuevo';
}

class ClienteTransactionItem {
  const ClienteTransactionItem({
    required this.saleId,
    required this.folio,
    required this.title,
    required this.totalCents,
    required this.createdAt,
    required this.iconKey,
  });

  final String saleId;
  final String folio;
  final String title;
  final int totalCents;
  final DateTime createdAt;
  final String iconKey;
}

class ClienteDetail {
  const ClienteDetail({
    required this.id,
    required this.code,
    required this.fullName,
    required this.identityNumber,
    required this.phone,
    required this.email,
    required this.address,
    required this.company,
    required this.avatarPath,
    required this.customerType,
    required this.isVip,
    required this.creditAvailableCents,
    required this.discountBps,
    required this.adminNote,
    required this.lifetimeSpentCents,
    required this.lastPurchaseAt,
    required this.lastPurchaseCents,
    required this.createdAt,
    required this.transactions,
  });

  final String id;
  final String code;
  final String fullName;
  final String? identityNumber;
  final String? phone;
  final String? email;
  final String? address;
  final String? company;
  final String? avatarPath;
  final String customerType;
  final bool isVip;
  final int creditAvailableCents;
  final int discountBps;
  final String? adminNote;
  final int lifetimeSpentCents;
  final DateTime? lastPurchaseAt;
  final int? lastPurchaseCents;
  final DateTime createdAt;
  final List<ClienteTransactionItem> transactions;
}

class ClienteUpsertInput {
  const ClienteUpsertInput({
    required this.fullName,
    this.identityNumber,
    this.phone,
    this.email,
    this.address,
    this.company,
    this.avatarPath,
    this.customerType = 'general',
    this.isVip = false,
    this.creditAvailableCents = 0,
    this.discountBps = 0,
    this.adminNote,
  });

  final String fullName;
  final String? identityNumber;
  final String? phone;
  final String? email;
  final String? address;
  final String? company;
  final String? avatarPath;
  final String customerType;
  final bool isVip;
  final int creditAvailableCents;
  final int discountBps;
  final String? adminNote;
}

class ClientesLocalDataSource {
  ClientesLocalDataSource(this._db, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;
  final Random _random = Random.secure();

  Future<List<ClienteListItem>> listClients({
    String searchQuery = '',
    String typeFilter = 'todos',
    int limit = 200,
  }) async {
    final String search = searchQuery.trim().toLowerCase();
    final String normalizedFilter = _normalizeTypeFilter(typeFilter);

    final List<Variable<Object>> variables = <Variable<Object>>[];
    final List<String> where = <String>['c.is_active = 1'];

    if (search.isNotEmpty) {
      where.add(
        '''
        (
          LOWER(c.full_name) LIKE ?
          OR LOWER(COALESCE(c.phone, '')) LIKE ?
          OR LOWER(COALESCE(c.email, '')) LIKE ?
          OR LOWER(COALESCE(c.identity_number, '')) LIKE ?
          OR LOWER(c.code) LIKE ?
        )
        ''',
      );
      final String like = '%$search%';
      variables.add(Variable<String>(like));
      variables.add(Variable<String>(like));
      variables.add(Variable<String>(like));
      variables.add(Variable<String>(like));
      variables.add(Variable<String>(like));
    }

    if (normalizedFilter == 'vip') {
      where.add('c.is_vip = 1');
    } else if (normalizedFilter != 'todos') {
      where.add('c.customer_type = ?');
      variables.add(Variable<String>(normalizedFilter));
    }

    final String whereSql = where.join(' AND ');
    variables.add(Variable<int>(limit));

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        c.id,
        c.code,
        c.full_name,
        c.identity_number,
        c.phone,
        c.email,
        c.avatar_path,
        c.customer_type,
        c.is_vip,
        c.credit_available_cents,
        c.discount_bps,
        c.created_at,
        COALESCE(
          (
            SELECT SUM(s.total_cents)
            FROM sales s
            WHERE s.customer_id = c.id
              AND s.status = 'posted'
          ),
          0
        ) AS lifetime_spent_cents,
        (
          SELECT MAX(s.created_at)
          FROM sales s
          WHERE s.customer_id = c.id
            AND s.status = 'posted'
        ) AS last_purchase_at,
        (
          SELECT s.total_cents
          FROM sales s
          WHERE s.customer_id = c.id
            AND s.status = 'posted'
          ORDER BY s.created_at DESC
          LIMIT 1
        ) AS last_purchase_cents
      FROM customers c
      WHERE $whereSql
      ORDER BY
        c.is_vip DESC,
        CASE c.customer_type
          WHEN 'frecuente' THEN 0
          WHEN 'mayorista' THEN 1
          WHEN 'nuevo' THEN 2
          ELSE 3
        END,
        c.updated_at DESC,
        c.created_at DESC
      LIMIT ?
      ''',
      variables: variables,
    ).get();

    return rows.map(_mapListItem).toList(growable: false);
  }

  Future<ClienteDetail?> getClientById(String clientId) async {
    final String cleanId = clientId.trim();
    if (cleanId.isEmpty) {
      return null;
    }

    final QueryRow? header = await _db.customSelect(
      '''
      SELECT
        c.id,
        c.code,
        c.full_name,
        c.identity_number,
        c.phone,
        c.email,
        c.address,
        c.company,
        c.avatar_path,
        c.customer_type,
        c.is_vip,
        c.credit_available_cents,
        c.discount_bps,
        c.admin_note,
        c.created_at,
        COALESCE(
          (
            SELECT SUM(s.total_cents)
            FROM sales s
            WHERE s.customer_id = c.id
              AND s.status = 'posted'
          ),
          0
        ) AS lifetime_spent_cents,
        (
          SELECT MAX(s.created_at)
          FROM sales s
          WHERE s.customer_id = c.id
            AND s.status = 'posted'
        ) AS last_purchase_at,
        (
          SELECT s.total_cents
          FROM sales s
          WHERE s.customer_id = c.id
            AND s.status = 'posted'
          ORDER BY s.created_at DESC
          LIMIT 1
        ) AS last_purchase_cents
      FROM customers c
      WHERE c.id = ?
        AND c.is_active = 1
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanId)],
    ).getSingleOrNull();

    if (header == null) {
      return null;
    }

    final List<QueryRow> transactionRows = await _db.customSelect(
      '''
      SELECT
        s.id AS sale_id,
        s.folio AS sale_folio,
        s.total_cents AS total_cents,
        s.created_at AS created_at,
        COALESCE(
          (
            SELECT p.name
            FROM sale_items si
            INNER JOIN products p ON p.id = si.product_id
            WHERE si.sale_id = s.id
            ORDER BY si.rowid ASC
            LIMIT 1
          ),
          'Venta'
        ) AS first_item_name,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM sale_items si2
            WHERE si2.sale_id = s.id
          ),
          0
        ) AS items_count
      FROM sales s
      WHERE s.customer_id = ?
        AND s.status = 'posted'
      ORDER BY s.created_at DESC
      LIMIT 20
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanId)],
    ).get();

    final List<ClienteTransactionItem> transactions =
        transactionRows.map((QueryRow row) {
      final String titleBase =
          (row.readNullable<String>('first_item_name') ?? '').trim();
      final int count = row.read<int>('items_count');
      final String title;
      if (titleBase.isEmpty) {
        title = 'Venta ${row.read<String>('sale_folio')}';
      } else if (count <= 1) {
        title = titleBase;
      } else {
        title = '$titleBase +${count - 1}';
      }
      return ClienteTransactionItem(
        saleId: row.read<String>('sale_id'),
        folio: row.read<String>('sale_folio'),
        title: title,
        totalCents: row.read<int>('total_cents'),
        createdAt: row.read<DateTime>('created_at'),
        iconKey: _transactionIconForTitle(titleBase),
      );
    }).toList(growable: false);

    return ClienteDetail(
      id: header.read<String>('id'),
      code: header.read<String>('code'),
      fullName: header.read<String>('full_name'),
      identityNumber:
          _normalizeOptional(header.readNullable<String>('identity_number')),
      phone: _normalizeOptional(header.readNullable<String>('phone')),
      email: _normalizeOptional(header.readNullable<String>('email')),
      address: _normalizeOptional(header.readNullable<String>('address')),
      company: _normalizeOptional(header.readNullable<String>('company')),
      avatarPath:
          _normalizeOptional(header.readNullable<String>('avatar_path')),
      customerType:
          _normalizeCustomerType(header.readNullable<String>('customer_type')),
      isVip: header.read<bool>('is_vip'),
      creditAvailableCents: header.read<int>('credit_available_cents'),
      discountBps: header.read<int>('discount_bps'),
      adminNote: _normalizeOptional(header.readNullable<String>('admin_note')),
      lifetimeSpentCents: header.read<int>('lifetime_spent_cents'),
      lastPurchaseAt: header.readNullable<DateTime>('last_purchase_at'),
      lastPurchaseCents: header.readNullable<int>('last_purchase_cents'),
      createdAt: header.read<DateTime>('created_at'),
      transactions: transactions,
    );
  }

  Future<String> createClient(ClienteUpsertInput input) async {
    final String fullName = input.fullName.trim();
    if (fullName.isEmpty) {
      throw Exception('El nombre completo del cliente es obligatorio.');
    }

    final String id = _uuid.v4();
    final String code = await _generateClientCode();
    await _db.into(_db.customers).insert(
          CustomersCompanion.insert(
            id: id,
            code: code,
            fullName: fullName,
            identityNumber: Value(_normalizeOptional(input.identityNumber)),
            phone: Value(_normalizeOptional(input.phone)),
            email: Value(_normalizeOptional(input.email)),
            address: Value(_normalizeOptional(input.address)),
            company: Value(_normalizeOptional(input.company)),
            avatarPath: Value(_normalizeOptional(input.avatarPath)),
            customerType: Value(_normalizeCustomerType(input.customerType)),
            isVip: Value(input.isVip),
            creditAvailableCents: Value(
              input.creditAvailableCents < 0 ? 0 : input.creditAvailableCents,
            ),
            discountBps: Value(_normalizeDiscountBps(input.discountBps)),
            adminNote: Value(_normalizeOptional(input.adminNote)),
          ),
        );
    return id;
  }

  Future<void> updateClient({
    required String clientId,
    required ClienteUpsertInput input,
  }) async {
    final String cleanId = clientId.trim();
    if (cleanId.isEmpty) {
      throw Exception('Cliente invalido.');
    }
    final String fullName = input.fullName.trim();
    if (fullName.isEmpty) {
      throw Exception('El nombre completo del cliente es obligatorio.');
    }

    final int updated = await (_db.update(_db.customers)
          ..where((Customers tbl) => tbl.id.equals(cleanId)))
        .write(
      CustomersCompanion(
        fullName: Value(fullName),
        identityNumber: Value(_normalizeOptional(input.identityNumber)),
        phone: Value(_normalizeOptional(input.phone)),
        email: Value(_normalizeOptional(input.email)),
        address: Value(_normalizeOptional(input.address)),
        company: Value(_normalizeOptional(input.company)),
        avatarPath: Value(_normalizeOptional(input.avatarPath)),
        customerType: Value(_normalizeCustomerType(input.customerType)),
        isVip: Value(input.isVip),
        creditAvailableCents: Value(
          input.creditAvailableCents < 0 ? 0 : input.creditAvailableCents,
        ),
        discountBps: Value(_normalizeDiscountBps(input.discountBps)),
        adminNote: Value(_normalizeOptional(input.adminNote)),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (updated == 0) {
      throw Exception('No se encontro el cliente para editar.');
    }
  }

  Future<void> deactivateClient(String clientId) async {
    final String cleanId = clientId.trim();
    if (cleanId.isEmpty) {
      return;
    }
    await (_db.update(_db.customers)
          ..where((Customers tbl) => tbl.id.equals(cleanId)))
        .write(
      CustomersCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  ClienteListItem _mapListItem(QueryRow row) {
    return ClienteListItem(
      id: row.read<String>('id'),
      code: row.read<String>('code'),
      fullName: row.read<String>('full_name'),
      identityNumber:
          _normalizeOptional(row.readNullable<String>('identity_number')),
      phone: _normalizeOptional(row.readNullable<String>('phone')),
      email: _normalizeOptional(row.readNullable<String>('email')),
      avatarPath: _normalizeOptional(row.readNullable<String>('avatar_path')),
      customerType:
          _normalizeCustomerType(row.readNullable<String>('customer_type')),
      isVip: row.read<bool>('is_vip'),
      creditAvailableCents: row.read<int>('credit_available_cents'),
      discountBps: row.read<int>('discount_bps'),
      lifetimeSpentCents: row.read<int>('lifetime_spent_cents'),
      lastPurchaseAt: row.readNullable<DateTime>('last_purchase_at'),
      lastPurchaseCents: row.readNullable<int>('last_purchase_cents'),
      createdAt: row.read<DateTime>('created_at'),
    );
  }

  Future<String> _generateClientCode() async {
    for (int i = 0; i < 60; i++) {
      final int blockA = _random.nextInt(9000) + 1000;
      final int blockB = _random.nextInt(90) + 10;
      final String code = 'NEX-$blockA-$blockB';
      final QueryRow? exists = await _db.customSelect(
        '''
        SELECT 1
        FROM customers c
        WHERE c.code = ?
        LIMIT 1
        ''',
        variables: <Variable<Object>>[Variable<String>(code)],
      ).getSingleOrNull();
      if (exists == null) {
        return code;
      }
    }

    final int fallback = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'NEX-${fallback.toString().padLeft(5, '0')}-00';
  }

  String _normalizeCustomerType(String? value) {
    final String raw = (value ?? '').trim().toLowerCase();
    switch (raw) {
      case 'frecuente':
      case 'mayorista':
      case 'nuevo':
      case 'general':
        return raw;
      default:
        return 'general';
    }
  }

  String _normalizeTypeFilter(String? value) {
    final String raw = (value ?? '').trim().toLowerCase();
    switch (raw) {
      case 'todos':
      case 'frecuente':
      case 'mayorista':
      case 'nuevo':
      case 'vip':
        return raw;
      default:
        return 'todos';
    }
  }

  String? _normalizeOptional(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
  }

  int _normalizeDiscountBps(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 10000) {
      return 10000;
    }
    return value;
  }

  String _transactionIconForTitle(String title) {
    final String text = title.toLowerCase();
    if (text.contains('licencia') || text.contains('software')) {
      return 'receipt';
    }
    if (text.contains('hardware') || text.contains('equipo')) {
      return 'devices';
    }
    if (text.contains('soporte') || text.contains('servicio')) {
      return 'support';
    }
    return 'receipt';
  }
}
