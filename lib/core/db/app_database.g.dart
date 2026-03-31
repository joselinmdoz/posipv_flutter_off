// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<String> salt = GeneratedColumn<String>(
      'salt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cajero'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, username, passwordHash, salt, role, isActive, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('salt')) {
      context.handle(
          _saltMeta, salt.isAcceptableOrUnknown(data['salt']!, _saltMeta));
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      salt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}salt'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String username;
  final String passwordHash;
  final String salt;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const User(
      {required this.id,
      required this.username,
      required this.passwordHash,
      required this.salt,
      required this.role,
      required this.isActive,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    map['salt'] = Variable<String>(salt);
    map['role'] = Variable<String>(role);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      passwordHash: Value(passwordHash),
      salt: Value(salt),
      role: Value(role),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      salt: serializer.fromJson<String>(json['salt']),
      role: serializer.fromJson<String>(json['role']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'salt': serializer.toJson<String>(salt),
      'role': serializer.toJson<String>(role),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  User copyWith(
          {String? id,
          String? username,
          String? passwordHash,
          String? salt,
          String? role,
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        salt: salt ?? this.salt,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      salt: data.salt.present ? data.salt.value : this.salt,
      role: data.role.present ? data.role.value : this.role,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, username, passwordHash, salt, role, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.salt == this.salt &&
          other.role == this.role &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<String> salt;
  final Value<String> role;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.salt = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String username,
    required String passwordHash,
    required String salt,
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        username = Value(username),
        passwordHash = Value(passwordHash),
        salt = Value(salt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? salt,
    Expression<String>? role,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (salt != null) 'salt': salt,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? username,
      Value<String>? passwordHash,
      Value<String>? salt,
      Value<String>? role,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (salt.present) {
      map['salt'] = Variable<String>(salt.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolesTable extends Roles with TableInfo<$RolesTable, Role> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSystemMeta =
      const VerificationMeta('isSystem');
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
      'is_system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_system" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, isSystem, isActive, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roles';
  @override
  VerificationContext validateIntegrity(Insertable<Role> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('is_system')) {
      context.handle(_isSystemMeta,
          isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Role map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Role(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      isSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $RolesTable createAlias(String alias) {
    return $RolesTable(attachedDatabase, alias);
  }
}

class Role extends DataClass implements Insertable<Role> {
  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const Role(
      {required this.id,
      required this.name,
      this.description,
      required this.isSystem,
      required this.isActive,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_system'] = Variable<bool>(isSystem);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  RolesCompanion toCompanion(bool nullToAbsent) {
    return RolesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isSystem: Value(isSystem),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Role.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Role(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isSystem': serializer.toJson<bool>(isSystem),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Role copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          bool? isSystem,
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Role(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        isSystem: isSystem ?? this.isSystem,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Role copyWithCompanion(RolesCompanion data) {
    return Role(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Role(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, description, isSystem, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Role &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.isSystem == this.isSystem &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RolesCompanion extends UpdateCompanion<Role> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isSystem;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const RolesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Role> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isSystem,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isSystem != null) 'is_system': isSystem,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<bool>? isSystem,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return RolesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PermissionsTable extends Permissions
    with TableInfo<$PermissionsTable, Permission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
      'module', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSystemMeta =
      const VerificationMeta('isSystem');
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
      'is_system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_system" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [key, module, label, description, isSystem];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'permissions';
  @override
  VerificationContext validateIntegrity(Insertable<Permission> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('module')) {
      context.handle(_moduleMeta,
          module.isAcceptableOrUnknown(data['module']!, _moduleMeta));
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('is_system')) {
      context.handle(_isSystemMeta,
          isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Permission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Permission(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      module: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}module'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      isSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system'])!,
    );
  }

  @override
  $PermissionsTable createAlias(String alias) {
    return $PermissionsTable(attachedDatabase, alias);
  }
}

class Permission extends DataClass implements Insertable<Permission> {
  final String key;
  final String module;
  final String label;
  final String? description;
  final bool isSystem;
  const Permission(
      {required this.key,
      required this.module,
      required this.label,
      this.description,
      required this.isSystem});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['module'] = Variable<String>(module);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_system'] = Variable<bool>(isSystem);
    return map;
  }

  PermissionsCompanion toCompanion(bool nullToAbsent) {
    return PermissionsCompanion(
      key: Value(key),
      module: Value(module),
      label: Value(label),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isSystem: Value(isSystem),
    );
  }

  factory Permission.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Permission(
      key: serializer.fromJson<String>(json['key']),
      module: serializer.fromJson<String>(json['module']),
      label: serializer.fromJson<String>(json['label']),
      description: serializer.fromJson<String?>(json['description']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'module': serializer.toJson<String>(module),
      'label': serializer.toJson<String>(label),
      'description': serializer.toJson<String?>(description),
      'isSystem': serializer.toJson<bool>(isSystem),
    };
  }

  Permission copyWith(
          {String? key,
          String? module,
          String? label,
          Value<String?> description = const Value.absent(),
          bool? isSystem}) =>
      Permission(
        key: key ?? this.key,
        module: module ?? this.module,
        label: label ?? this.label,
        description: description.present ? description.value : this.description,
        isSystem: isSystem ?? this.isSystem,
      );
  Permission copyWithCompanion(PermissionsCompanion data) {
    return Permission(
      key: data.key.present ? data.key.value : this.key,
      module: data.module.present ? data.module.value : this.module,
      label: data.label.present ? data.label.value : this.label,
      description:
          data.description.present ? data.description.value : this.description,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Permission(')
          ..write('key: $key, ')
          ..write('module: $module, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, module, label, description, isSystem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Permission &&
          other.key == this.key &&
          other.module == this.module &&
          other.label == this.label &&
          other.description == this.description &&
          other.isSystem == this.isSystem);
}

class PermissionsCompanion extends UpdateCompanion<Permission> {
  final Value<String> key;
  final Value<String> module;
  final Value<String> label;
  final Value<String?> description;
  final Value<bool> isSystem;
  final Value<int> rowid;
  const PermissionsCompanion({
    this.key = const Value.absent(),
    this.module = const Value.absent(),
    this.label = const Value.absent(),
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PermissionsCompanion.insert({
    required String key,
    required String module,
    required String label,
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        module = Value(module),
        label = Value(label);
  static Insertable<Permission> custom({
    Expression<String>? key,
    Expression<String>? module,
    Expression<String>? label,
    Expression<String>? description,
    Expression<bool>? isSystem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (module != null) 'module': module,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (isSystem != null) 'is_system': isSystem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PermissionsCompanion copyWith(
      {Value<String>? key,
      Value<String>? module,
      Value<String>? label,
      Value<String?>? description,
      Value<bool>? isSystem,
      Value<int>? rowid}) {
    return PermissionsCompanion(
      key: key ?? this.key,
      module: module ?? this.module,
      label: label ?? this.label,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PermissionsCompanion(')
          ..write('key: $key, ')
          ..write('module: $module, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolePermissionsTable extends RolePermissions
    with TableInfo<$RolePermissionsTable, RolePermission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolePermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
      'role_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES roles (id)'));
  static const VerificationMeta _permissionKeyMeta =
      const VerificationMeta('permissionKey');
  @override
  late final GeneratedColumn<String> permissionKey = GeneratedColumn<String>(
      'permission_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES permissions ("key")'));
  static const VerificationMeta _grantedAtMeta =
      const VerificationMeta('grantedAt');
  @override
  late final GeneratedColumn<DateTime> grantedAt = GeneratedColumn<DateTime>(
      'granted_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [roleId, permissionKey, grantedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'role_permissions';
  @override
  VerificationContext validateIntegrity(Insertable<RolePermission> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('role_id')) {
      context.handle(_roleIdMeta,
          roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta));
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('permission_key')) {
      context.handle(
          _permissionKeyMeta,
          permissionKey.isAcceptableOrUnknown(
              data['permission_key']!, _permissionKeyMeta));
    } else if (isInserting) {
      context.missing(_permissionKeyMeta);
    }
    if (data.containsKey('granted_at')) {
      context.handle(_grantedAtMeta,
          grantedAt.isAcceptableOrUnknown(data['granted_at']!, _grantedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {roleId, permissionKey};
  @override
  RolePermission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RolePermission(
      roleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role_id'])!,
      permissionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}permission_key'])!,
      grantedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}granted_at'])!,
    );
  }

  @override
  $RolePermissionsTable createAlias(String alias) {
    return $RolePermissionsTable(attachedDatabase, alias);
  }
}

class RolePermission extends DataClass implements Insertable<RolePermission> {
  final String roleId;
  final String permissionKey;
  final DateTime grantedAt;
  const RolePermission(
      {required this.roleId,
      required this.permissionKey,
      required this.grantedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['role_id'] = Variable<String>(roleId);
    map['permission_key'] = Variable<String>(permissionKey);
    map['granted_at'] = Variable<DateTime>(grantedAt);
    return map;
  }

  RolePermissionsCompanion toCompanion(bool nullToAbsent) {
    return RolePermissionsCompanion(
      roleId: Value(roleId),
      permissionKey: Value(permissionKey),
      grantedAt: Value(grantedAt),
    );
  }

  factory RolePermission.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RolePermission(
      roleId: serializer.fromJson<String>(json['roleId']),
      permissionKey: serializer.fromJson<String>(json['permissionKey']),
      grantedAt: serializer.fromJson<DateTime>(json['grantedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'roleId': serializer.toJson<String>(roleId),
      'permissionKey': serializer.toJson<String>(permissionKey),
      'grantedAt': serializer.toJson<DateTime>(grantedAt),
    };
  }

  RolePermission copyWith(
          {String? roleId, String? permissionKey, DateTime? grantedAt}) =>
      RolePermission(
        roleId: roleId ?? this.roleId,
        permissionKey: permissionKey ?? this.permissionKey,
        grantedAt: grantedAt ?? this.grantedAt,
      );
  RolePermission copyWithCompanion(RolePermissionsCompanion data) {
    return RolePermission(
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      permissionKey: data.permissionKey.present
          ? data.permissionKey.value
          : this.permissionKey,
      grantedAt: data.grantedAt.present ? data.grantedAt.value : this.grantedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RolePermission(')
          ..write('roleId: $roleId, ')
          ..write('permissionKey: $permissionKey, ')
          ..write('grantedAt: $grantedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(roleId, permissionKey, grantedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RolePermission &&
          other.roleId == this.roleId &&
          other.permissionKey == this.permissionKey &&
          other.grantedAt == this.grantedAt);
}

class RolePermissionsCompanion extends UpdateCompanion<RolePermission> {
  final Value<String> roleId;
  final Value<String> permissionKey;
  final Value<DateTime> grantedAt;
  final Value<int> rowid;
  const RolePermissionsCompanion({
    this.roleId = const Value.absent(),
    this.permissionKey = const Value.absent(),
    this.grantedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolePermissionsCompanion.insert({
    required String roleId,
    required String permissionKey,
    this.grantedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : roleId = Value(roleId),
        permissionKey = Value(permissionKey);
  static Insertable<RolePermission> custom({
    Expression<String>? roleId,
    Expression<String>? permissionKey,
    Expression<DateTime>? grantedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (roleId != null) 'role_id': roleId,
      if (permissionKey != null) 'permission_key': permissionKey,
      if (grantedAt != null) 'granted_at': grantedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolePermissionsCompanion copyWith(
      {Value<String>? roleId,
      Value<String>? permissionKey,
      Value<DateTime>? grantedAt,
      Value<int>? rowid}) {
    return RolePermissionsCompanion(
      roleId: roleId ?? this.roleId,
      permissionKey: permissionKey ?? this.permissionKey,
      grantedAt: grantedAt ?? this.grantedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (permissionKey.present) {
      map['permission_key'] = Variable<String>(permissionKey.value);
    }
    if (grantedAt.present) {
      map['granted_at'] = Variable<DateTime>(grantedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolePermissionsCompanion(')
          ..write('roleId: $roleId, ')
          ..write('permissionKey: $permissionKey, ')
          ..write('grantedAt: $grantedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserRolesTable extends UserRoles
    with TableInfo<$UserRolesTable, UserRole> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
      'role_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES roles (id)'));
  static const VerificationMeta _assignedAtMeta =
      const VerificationMeta('assignedAt');
  @override
  late final GeneratedColumn<DateTime> assignedAt = GeneratedColumn<DateTime>(
      'assigned_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [userId, roleId, assignedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_roles';
  @override
  VerificationContext validateIntegrity(Insertable<UserRole> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(_roleIdMeta,
          roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta));
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
          _assignedAtMeta,
          assignedAt.isAcceptableOrUnknown(
              data['assigned_at']!, _assignedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, roleId};
  @override
  UserRole map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRole(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      roleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role_id'])!,
      assignedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}assigned_at'])!,
    );
  }

  @override
  $UserRolesTable createAlias(String alias) {
    return $UserRolesTable(attachedDatabase, alias);
  }
}

class UserRole extends DataClass implements Insertable<UserRole> {
  final String userId;
  final String roleId;
  final DateTime assignedAt;
  const UserRole(
      {required this.userId, required this.roleId, required this.assignedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['role_id'] = Variable<String>(roleId);
    map['assigned_at'] = Variable<DateTime>(assignedAt);
    return map;
  }

  UserRolesCompanion toCompanion(bool nullToAbsent) {
    return UserRolesCompanion(
      userId: Value(userId),
      roleId: Value(roleId),
      assignedAt: Value(assignedAt),
    );
  }

  factory UserRole.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRole(
      userId: serializer.fromJson<String>(json['userId']),
      roleId: serializer.fromJson<String>(json['roleId']),
      assignedAt: serializer.fromJson<DateTime>(json['assignedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'roleId': serializer.toJson<String>(roleId),
      'assignedAt': serializer.toJson<DateTime>(assignedAt),
    };
  }

  UserRole copyWith({String? userId, String? roleId, DateTime? assignedAt}) =>
      UserRole(
        userId: userId ?? this.userId,
        roleId: roleId ?? this.roleId,
        assignedAt: assignedAt ?? this.assignedAt,
      );
  UserRole copyWithCompanion(UserRolesCompanion data) {
    return UserRole(
      userId: data.userId.present ? data.userId.value : this.userId,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      assignedAt:
          data.assignedAt.present ? data.assignedAt.value : this.assignedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRole(')
          ..write('userId: $userId, ')
          ..write('roleId: $roleId, ')
          ..write('assignedAt: $assignedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, roleId, assignedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRole &&
          other.userId == this.userId &&
          other.roleId == this.roleId &&
          other.assignedAt == this.assignedAt);
}

class UserRolesCompanion extends UpdateCompanion<UserRole> {
  final Value<String> userId;
  final Value<String> roleId;
  final Value<DateTime> assignedAt;
  final Value<int> rowid;
  const UserRolesCompanion({
    this.userId = const Value.absent(),
    this.roleId = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserRolesCompanion.insert({
    required String userId,
    required String roleId,
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        roleId = Value(roleId);
  static Insertable<UserRole> custom({
    Expression<String>? userId,
    Expression<String>? roleId,
    Expression<DateTime>? assignedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (roleId != null) 'role_id': roleId,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserRolesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? roleId,
      Value<DateTime>? assignedAt,
      Value<int>? rowid}) {
    return UserRolesCompanion(
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
      assignedAt: assignedAt ?? this.assignedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<DateTime>(assignedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRolesCompanion(')
          ..write('userId: $userId, ')
          ..write('roleId: $roleId, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceCentsMeta =
      const VerificationMeta('priceCents');
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
      'price_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxRateBpsMeta =
      const VerificationMeta('taxRateBps');
  @override
  late final GeneratedColumn<int> taxRateBps = GeneratedColumn<int>(
      'tax_rate_bps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _costPriceCentsMeta =
      const VerificationMeta('costPriceCents');
  @override
  late final GeneratedColumn<int> costPriceCents = GeneratedColumn<int>(
      'cost_price_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('General'));
  static const VerificationMeta _productTypeMeta =
      const VerificationMeta('productType');
  @override
  late final GeneratedColumn<String> productType = GeneratedColumn<String>(
      'product_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Fisico'));
  static const VerificationMeta _unitMeasureMeta =
      const VerificationMeta('unitMeasure');
  @override
  late final GeneratedColumn<String> unitMeasure = GeneratedColumn<String>(
      'unit_measure', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Unidad'));
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sku,
        barcode,
        name,
        priceCents,
        taxRateBps,
        imagePath,
        costPriceCents,
        category,
        productType,
        unitMeasure,
        currencyCode,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_cents')) {
      context.handle(
          _priceCentsMeta,
          priceCents.isAcceptableOrUnknown(
              data['price_cents']!, _priceCentsMeta));
    }
    if (data.containsKey('tax_rate_bps')) {
      context.handle(
          _taxRateBpsMeta,
          taxRateBps.isAcceptableOrUnknown(
              data['tax_rate_bps']!, _taxRateBpsMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('cost_price_cents')) {
      context.handle(
          _costPriceCentsMeta,
          costPriceCents.isAcceptableOrUnknown(
              data['cost_price_cents']!, _costPriceCentsMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('product_type')) {
      context.handle(
          _productTypeMeta,
          productType.isAcceptableOrUnknown(
              data['product_type']!, _productTypeMeta));
    }
    if (data.containsKey('unit_measure')) {
      context.handle(
          _unitMeasureMeta,
          unitMeasure.isAcceptableOrUnknown(
              data['unit_measure']!, _unitMeasureMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      priceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_cents'])!,
      taxRateBps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tax_rate_bps'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      costPriceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cost_price_cents'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      productType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_type'])!,
      unitMeasure: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_measure'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final int priceCents;
  final int taxRateBps;
  final String? imagePath;
  final int costPriceCents;
  final String category;
  final String productType;
  final String unitMeasure;
  final String currencyCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const Product(
      {required this.id,
      required this.sku,
      this.barcode,
      required this.name,
      required this.priceCents,
      required this.taxRateBps,
      this.imagePath,
      required this.costPriceCents,
      required this.category,
      required this.productType,
      required this.unitMeasure,
      required this.currencyCode,
      required this.isActive,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sku'] = Variable<String>(sku);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['name'] = Variable<String>(name);
    map['price_cents'] = Variable<int>(priceCents);
    map['tax_rate_bps'] = Variable<int>(taxRateBps);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['cost_price_cents'] = Variable<int>(costPriceCents);
    map['category'] = Variable<String>(category);
    map['product_type'] = Variable<String>(productType);
    map['unit_measure'] = Variable<String>(unitMeasure);
    map['currency_code'] = Variable<String>(currencyCode);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      sku: Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      name: Value(name),
      priceCents: Value(priceCents),
      taxRateBps: Value(taxRateBps),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      costPriceCents: Value(costPriceCents),
      category: Value(category),
      productType: Value(productType),
      unitMeasure: Value(unitMeasure),
      currencyCode: Value(currencyCode),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      priceCents: serializer.fromJson<int>(json['priceCents']),
      taxRateBps: serializer.fromJson<int>(json['taxRateBps']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      costPriceCents: serializer.fromJson<int>(json['costPriceCents']),
      category: serializer.fromJson<String>(json['category']),
      productType: serializer.fromJson<String>(json['productType']),
      unitMeasure: serializer.fromJson<String>(json['unitMeasure']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sku': serializer.toJson<String>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'name': serializer.toJson<String>(name),
      'priceCents': serializer.toJson<int>(priceCents),
      'taxRateBps': serializer.toJson<int>(taxRateBps),
      'imagePath': serializer.toJson<String?>(imagePath),
      'costPriceCents': serializer.toJson<int>(costPriceCents),
      'category': serializer.toJson<String>(category),
      'productType': serializer.toJson<String>(productType),
      'unitMeasure': serializer.toJson<String>(unitMeasure),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Product copyWith(
          {String? id,
          String? sku,
          Value<String?> barcode = const Value.absent(),
          String? name,
          int? priceCents,
          int? taxRateBps,
          Value<String?> imagePath = const Value.absent(),
          int? costPriceCents,
          String? category,
          String? productType,
          String? unitMeasure,
          String? currencyCode,
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Product(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        barcode: barcode.present ? barcode.value : this.barcode,
        name: name ?? this.name,
        priceCents: priceCents ?? this.priceCents,
        taxRateBps: taxRateBps ?? this.taxRateBps,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        costPriceCents: costPriceCents ?? this.costPriceCents,
        category: category ?? this.category,
        productType: productType ?? this.productType,
        unitMeasure: unitMeasure ?? this.unitMeasure,
        currencyCode: currencyCode ?? this.currencyCode,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      priceCents:
          data.priceCents.present ? data.priceCents.value : this.priceCents,
      taxRateBps:
          data.taxRateBps.present ? data.taxRateBps.value : this.taxRateBps,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      costPriceCents: data.costPriceCents.present
          ? data.costPriceCents.value
          : this.costPriceCents,
      category: data.category.present ? data.category.value : this.category,
      productType:
          data.productType.present ? data.productType.value : this.productType,
      unitMeasure:
          data.unitMeasure.present ? data.unitMeasure.value : this.unitMeasure,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('priceCents: $priceCents, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('imagePath: $imagePath, ')
          ..write('costPriceCents: $costPriceCents, ')
          ..write('category: $category, ')
          ..write('productType: $productType, ')
          ..write('unitMeasure: $unitMeasure, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sku,
      barcode,
      name,
      priceCents,
      taxRateBps,
      imagePath,
      costPriceCents,
      category,
      productType,
      unitMeasure,
      currencyCode,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.priceCents == this.priceCents &&
          other.taxRateBps == this.taxRateBps &&
          other.imagePath == this.imagePath &&
          other.costPriceCents == this.costPriceCents &&
          other.category == this.category &&
          other.productType == this.productType &&
          other.unitMeasure == this.unitMeasure &&
          other.currencyCode == this.currencyCode &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> sku;
  final Value<String?> barcode;
  final Value<String> name;
  final Value<int> priceCents;
  final Value<int> taxRateBps;
  final Value<String?> imagePath;
  final Value<int> costPriceCents;
  final Value<String> category;
  final Value<String> productType;
  final Value<String> unitMeasure;
  final Value<String> currencyCode;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.taxRateBps = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.costPriceCents = const Value.absent(),
    this.category = const Value.absent(),
    this.productType = const Value.absent(),
    this.unitMeasure = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String sku,
    this.barcode = const Value.absent(),
    required String name,
    this.priceCents = const Value.absent(),
    this.taxRateBps = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.costPriceCents = const Value.absent(),
    this.category = const Value.absent(),
    this.productType = const Value.absent(),
    this.unitMeasure = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sku = Value(sku),
        name = Value(name);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<int>? priceCents,
    Expression<int>? taxRateBps,
    Expression<String>? imagePath,
    Expression<int>? costPriceCents,
    Expression<String>? category,
    Expression<String>? productType,
    Expression<String>? unitMeasure,
    Expression<String>? currencyCode,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (priceCents != null) 'price_cents': priceCents,
      if (taxRateBps != null) 'tax_rate_bps': taxRateBps,
      if (imagePath != null) 'image_path': imagePath,
      if (costPriceCents != null) 'cost_price_cents': costPriceCents,
      if (category != null) 'category': category,
      if (productType != null) 'product_type': productType,
      if (unitMeasure != null) 'unit_measure': unitMeasure,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sku,
      Value<String?>? barcode,
      Value<String>? name,
      Value<int>? priceCents,
      Value<int>? taxRateBps,
      Value<String?>? imagePath,
      Value<int>? costPriceCents,
      Value<String>? category,
      Value<String>? productType,
      Value<String>? unitMeasure,
      Value<String>? currencyCode,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      taxRateBps: taxRateBps ?? this.taxRateBps,
      imagePath: imagePath ?? this.imagePath,
      costPriceCents: costPriceCents ?? this.costPriceCents,
      category: category ?? this.category,
      productType: productType ?? this.productType,
      unitMeasure: unitMeasure ?? this.unitMeasure,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (taxRateBps.present) {
      map['tax_rate_bps'] = Variable<int>(taxRateBps.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (costPriceCents.present) {
      map['cost_price_cents'] = Variable<int>(costPriceCents.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (productType.present) {
      map['product_type'] = Variable<String>(productType.value);
    }
    if (unitMeasure.present) {
      map['unit_measure'] = Variable<String>(unitMeasure.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('priceCents: $priceCents, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('imagePath: $imagePath, ')
          ..write('costPriceCents: $costPriceCents, ')
          ..write('category: $category, ')
          ..write('productType: $productType, ')
          ..write('unitMeasure: $unitMeasure, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductCatalogItemsTable extends ProductCatalogItems
    with TableInfo<$ProductCatalogItemsTable, ProductCatalogItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductCatalogItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, kind, value, isActive, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_catalog_items';
  @override
  VerificationContext validateIntegrity(Insertable<ProductCatalogItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {kind, value},
      ];
  @override
  ProductCatalogItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductCatalogItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ProductCatalogItemsTable createAlias(String alias) {
    return $ProductCatalogItemsTable(attachedDatabase, alias);
  }
}

class ProductCatalogItem extends DataClass
    implements Insertable<ProductCatalogItem> {
  final String id;
  final String kind;
  final String value;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const ProductCatalogItem(
      {required this.id,
      required this.kind,
      required this.value,
      required this.isActive,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<String>(value);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ProductCatalogItemsCompanion toCompanion(bool nullToAbsent) {
    return ProductCatalogItemsCompanion(
      id: Value(id),
      kind: Value(kind),
      value: Value(value),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ProductCatalogItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductCatalogItem(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<String>(json['value']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<String>(value),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ProductCatalogItem copyWith(
          {String? id,
          String? kind,
          String? value,
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      ProductCatalogItem(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        value: value ?? this.value,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  ProductCatalogItem copyWithCompanion(ProductCatalogItemsCompanion data) {
    return ProductCatalogItem(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductCatalogItem(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, value, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductCatalogItem &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductCatalogItemsCompanion extends UpdateCompanion<ProductCatalogItem> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> value;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ProductCatalogItemsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductCatalogItemsCompanion.insert({
    required String id,
    required String kind,
    required String value,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        value = Value(value);
  static Insertable<ProductCatalogItem> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? value,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductCatalogItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String>? value,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return ProductCatalogItemsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCatalogItemsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WarehousesTable extends Warehouses
    with TableInfo<$WarehousesTable, Warehouse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WarehousesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _warehouseTypeMeta =
      const VerificationMeta('warehouseType');
  @override
  late final GeneratedColumn<String> warehouseType = GeneratedColumn<String>(
      'warehouse_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Central'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, warehouseType, isActive, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'warehouses';
  @override
  VerificationContext validateIntegrity(Insertable<Warehouse> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('warehouse_type')) {
      context.handle(
          _warehouseTypeMeta,
          warehouseType.isAcceptableOrUnknown(
              data['warehouse_type']!, _warehouseTypeMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Warehouse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Warehouse(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      warehouseType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}warehouse_type'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WarehousesTable createAlias(String alias) {
    return $WarehousesTable(attachedDatabase, alias);
  }
}

class Warehouse extends DataClass implements Insertable<Warehouse> {
  final String id;
  final String name;
  final String warehouseType;
  final bool isActive;
  final DateTime createdAt;
  const Warehouse(
      {required this.id,
      required this.name,
      required this.warehouseType,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['warehouse_type'] = Variable<String>(warehouseType);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WarehousesCompanion toCompanion(bool nullToAbsent) {
    return WarehousesCompanion(
      id: Value(id),
      name: Value(name),
      warehouseType: Value(warehouseType),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Warehouse.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Warehouse(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      warehouseType: serializer.fromJson<String>(json['warehouseType']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'warehouseType': serializer.toJson<String>(warehouseType),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Warehouse copyWith(
          {String? id,
          String? name,
          String? warehouseType,
          bool? isActive,
          DateTime? createdAt}) =>
      Warehouse(
        id: id ?? this.id,
        name: name ?? this.name,
        warehouseType: warehouseType ?? this.warehouseType,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  Warehouse copyWithCompanion(WarehousesCompanion data) {
    return Warehouse(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      warehouseType: data.warehouseType.present
          ? data.warehouseType.value
          : this.warehouseType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Warehouse(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('warehouseType: $warehouseType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, warehouseType, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Warehouse &&
          other.id == this.id &&
          other.name == this.name &&
          other.warehouseType == this.warehouseType &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class WarehousesCompanion extends UpdateCompanion<Warehouse> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> warehouseType;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WarehousesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.warehouseType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WarehousesCompanion.insert({
    required String id,
    required String name,
    this.warehouseType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Warehouse> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? warehouseType,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (warehouseType != null) 'warehouse_type': warehouseType,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WarehousesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? warehouseType,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return WarehousesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      warehouseType: warehouseType ?? this.warehouseType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (warehouseType.present) {
      map['warehouse_type'] = Variable<String>(warehouseType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WarehousesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('warehouseType: $warehouseType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PosTerminalsTable extends PosTerminals
    with TableInfo<$PosTerminalsTable, PosTerminal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PosTerminalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _warehouseIdMeta =
      const VerificationMeta('warehouseId');
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
      'warehouse_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'UNIQUE REFERENCES warehouses (id)'));
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _currencySymbolMeta =
      const VerificationMeta('currencySymbol');
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
      'currency_symbol', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(r'$'));
  static const VerificationMeta _paymentMethodsJsonMeta =
      const VerificationMeta('paymentMethodsJson');
  @override
  late final GeneratedColumn<String> paymentMethodsJson =
      GeneratedColumn<String>('payment_methods_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('["cash"]'));
  static const VerificationMeta _cashDenominationsJsonMeta =
      const VerificationMeta('cashDenominationsJson');
  @override
  late final GeneratedColumn<String> cashDenominationsJson =
      GeneratedColumn<String>('cash_denominations_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[10000,5000,2000,1000,500,100]'));
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        code,
        name,
        warehouseId,
        currencyCode,
        currencySymbol,
        paymentMethodsJson,
        cashDenominationsJson,
        imagePath,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pos_terminals';
  @override
  VerificationContext validateIntegrity(Insertable<PosTerminal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
          _warehouseIdMeta,
          warehouseId.isAcceptableOrUnknown(
              data['warehouse_id']!, _warehouseIdMeta));
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
          _currencySymbolMeta,
          currencySymbol.isAcceptableOrUnknown(
              data['currency_symbol']!, _currencySymbolMeta));
    }
    if (data.containsKey('payment_methods_json')) {
      context.handle(
          _paymentMethodsJsonMeta,
          paymentMethodsJson.isAcceptableOrUnknown(
              data['payment_methods_json']!, _paymentMethodsJsonMeta));
    }
    if (data.containsKey('cash_denominations_json')) {
      context.handle(
          _cashDenominationsJsonMeta,
          cashDenominationsJson.isAcceptableOrUnknown(
              data['cash_denominations_json']!, _cashDenominationsJsonMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PosTerminal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PosTerminal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      warehouseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}warehouse_id'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      currencySymbol: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}currency_symbol'])!,
      paymentMethodsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}payment_methods_json'])!,
      cashDenominationsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cash_denominations_json'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $PosTerminalsTable createAlias(String alias) {
    return $PosTerminalsTable(attachedDatabase, alias);
  }
}

class PosTerminal extends DataClass implements Insertable<PosTerminal> {
  final String id;
  final String code;
  final String name;
  final String warehouseId;
  final String currencyCode;
  final String currencySymbol;
  final String paymentMethodsJson;
  final String cashDenominationsJson;
  final String? imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const PosTerminal(
      {required this.id,
      required this.code,
      required this.name,
      required this.warehouseId,
      required this.currencyCode,
      required this.currencySymbol,
      required this.paymentMethodsJson,
      required this.cashDenominationsJson,
      this.imagePath,
      required this.isActive,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['currency_code'] = Variable<String>(currencyCode);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    map['payment_methods_json'] = Variable<String>(paymentMethodsJson);
    map['cash_denominations_json'] = Variable<String>(cashDenominationsJson);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PosTerminalsCompanion toCompanion(bool nullToAbsent) {
    return PosTerminalsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      warehouseId: Value(warehouseId),
      currencyCode: Value(currencyCode),
      currencySymbol: Value(currencySymbol),
      paymentMethodsJson: Value(paymentMethodsJson),
      cashDenominationsJson: Value(cashDenominationsJson),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory PosTerminal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PosTerminal(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
      paymentMethodsJson:
          serializer.fromJson<String>(json['paymentMethodsJson']),
      cashDenominationsJson:
          serializer.fromJson<String>(json['cashDenominationsJson']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
      'paymentMethodsJson': serializer.toJson<String>(paymentMethodsJson),
      'cashDenominationsJson': serializer.toJson<String>(cashDenominationsJson),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  PosTerminal copyWith(
          {String? id,
          String? code,
          String? name,
          String? warehouseId,
          String? currencyCode,
          String? currencySymbol,
          String? paymentMethodsJson,
          String? cashDenominationsJson,
          Value<String?> imagePath = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      PosTerminal(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        warehouseId: warehouseId ?? this.warehouseId,
        currencyCode: currencyCode ?? this.currencyCode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        paymentMethodsJson: paymentMethodsJson ?? this.paymentMethodsJson,
        cashDenominationsJson:
            cashDenominationsJson ?? this.cashDenominationsJson,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  PosTerminal copyWithCompanion(PosTerminalsCompanion data) {
    return PosTerminal(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      warehouseId:
          data.warehouseId.present ? data.warehouseId.value : this.warehouseId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      paymentMethodsJson: data.paymentMethodsJson.present
          ? data.paymentMethodsJson.value
          : this.paymentMethodsJson,
      cashDenominationsJson: data.cashDenominationsJson.present
          ? data.cashDenominationsJson.value
          : this.cashDenominationsJson,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PosTerminal(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('paymentMethodsJson: $paymentMethodsJson, ')
          ..write('cashDenominationsJson: $cashDenominationsJson, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      code,
      name,
      warehouseId,
      currencyCode,
      currencySymbol,
      paymentMethodsJson,
      cashDenominationsJson,
      imagePath,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PosTerminal &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.warehouseId == this.warehouseId &&
          other.currencyCode == this.currencyCode &&
          other.currencySymbol == this.currencySymbol &&
          other.paymentMethodsJson == this.paymentMethodsJson &&
          other.cashDenominationsJson == this.cashDenominationsJson &&
          other.imagePath == this.imagePath &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PosTerminalsCompanion extends UpdateCompanion<PosTerminal> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> warehouseId;
  final Value<String> currencyCode;
  final Value<String> currencySymbol;
  final Value<String> paymentMethodsJson;
  final Value<String> cashDenominationsJson;
  final Value<String?> imagePath;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const PosTerminalsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.paymentMethodsJson = const Value.absent(),
    this.cashDenominationsJson = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PosTerminalsCompanion.insert({
    required String id,
    required String code,
    required String name,
    required String warehouseId,
    this.currencyCode = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.paymentMethodsJson = const Value.absent(),
    this.cashDenominationsJson = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        code = Value(code),
        name = Value(name),
        warehouseId = Value(warehouseId);
  static Insertable<PosTerminal> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? warehouseId,
    Expression<String>? currencyCode,
    Expression<String>? currencySymbol,
    Expression<String>? paymentMethodsJson,
    Expression<String>? cashDenominationsJson,
    Expression<String>? imagePath,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (paymentMethodsJson != null)
        'payment_methods_json': paymentMethodsJson,
      if (cashDenominationsJson != null)
        'cash_denominations_json': cashDenominationsJson,
      if (imagePath != null) 'image_path': imagePath,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PosTerminalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? code,
      Value<String>? name,
      Value<String>? warehouseId,
      Value<String>? currencyCode,
      Value<String>? currencySymbol,
      Value<String>? paymentMethodsJson,
      Value<String>? cashDenominationsJson,
      Value<String?>? imagePath,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return PosTerminalsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      warehouseId: warehouseId ?? this.warehouseId,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      paymentMethodsJson: paymentMethodsJson ?? this.paymentMethodsJson,
      cashDenominationsJson:
          cashDenominationsJson ?? this.cashDenominationsJson,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (paymentMethodsJson.present) {
      map['payment_methods_json'] = Variable<String>(paymentMethodsJson.value);
    }
    if (cashDenominationsJson.present) {
      map['cash_denominations_json'] =
          Variable<String>(cashDenominationsJson.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PosTerminalsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('paymentMethodsJson: $paymentMethodsJson, ')
          ..write('cashDenominationsJson: $cashDenominationsJson, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PosSessionsTable extends PosSessions
    with TableInfo<$PosSessionsTable, PosSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PosSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _terminalIdMeta =
      const VerificationMeta('terminalId');
  @override
  late final GeneratedColumn<String> terminalId = GeneratedColumn<String>(
      'terminal_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pos_terminals (id)'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _openingFloatCentsMeta =
      const VerificationMeta('openingFloatCents');
  @override
  late final GeneratedColumn<int> openingFloatCents = GeneratedColumn<int>(
      'opening_float_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _closingCashCentsMeta =
      const VerificationMeta('closingCashCents');
  @override
  late final GeneratedColumn<int> closingCashCents = GeneratedColumn<int>(
      'closing_cash_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        terminalId,
        userId,
        openedAt,
        openingFloatCents,
        closedAt,
        closingCashCents,
        status,
        note
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pos_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<PosSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('terminal_id')) {
      context.handle(
          _terminalIdMeta,
          terminalId.isAcceptableOrUnknown(
              data['terminal_id']!, _terminalIdMeta));
    } else if (isInserting) {
      context.missing(_terminalIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    }
    if (data.containsKey('opening_float_cents')) {
      context.handle(
          _openingFloatCentsMeta,
          openingFloatCents.isAcceptableOrUnknown(
              data['opening_float_cents']!, _openingFloatCentsMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    if (data.containsKey('closing_cash_cents')) {
      context.handle(
          _closingCashCentsMeta,
          closingCashCents.isAcceptableOrUnknown(
              data['closing_cash_cents']!, _closingCashCentsMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PosSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PosSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      terminalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terminal_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at'])!,
      openingFloatCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}opening_float_cents'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at']),
      closingCashCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}closing_cash_cents']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $PosSessionsTable createAlias(String alias) {
    return $PosSessionsTable(attachedDatabase, alias);
  }
}

class PosSession extends DataClass implements Insertable<PosSession> {
  final String id;
  final String terminalId;
  final String userId;
  final DateTime openedAt;
  final int openingFloatCents;
  final DateTime? closedAt;
  final int? closingCashCents;
  final String status;
  final String? note;
  const PosSession(
      {required this.id,
      required this.terminalId,
      required this.userId,
      required this.openedAt,
      required this.openingFloatCents,
      this.closedAt,
      this.closingCashCents,
      required this.status,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['terminal_id'] = Variable<String>(terminalId);
    map['user_id'] = Variable<String>(userId);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['opening_float_cents'] = Variable<int>(openingFloatCents);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || closingCashCents != null) {
      map['closing_cash_cents'] = Variable<int>(closingCashCents);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PosSessionsCompanion toCompanion(bool nullToAbsent) {
    return PosSessionsCompanion(
      id: Value(id),
      terminalId: Value(terminalId),
      userId: Value(userId),
      openedAt: Value(openedAt),
      openingFloatCents: Value(openingFloatCents),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      closingCashCents: closingCashCents == null && nullToAbsent
          ? const Value.absent()
          : Value(closingCashCents),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PosSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PosSession(
      id: serializer.fromJson<String>(json['id']),
      terminalId: serializer.fromJson<String>(json['terminalId']),
      userId: serializer.fromJson<String>(json['userId']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      openingFloatCents: serializer.fromJson<int>(json['openingFloatCents']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      closingCashCents: serializer.fromJson<int?>(json['closingCashCents']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'terminalId': serializer.toJson<String>(terminalId),
      'userId': serializer.toJson<String>(userId),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'openingFloatCents': serializer.toJson<int>(openingFloatCents),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'closingCashCents': serializer.toJson<int?>(closingCashCents),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
    };
  }

  PosSession copyWith(
          {String? id,
          String? terminalId,
          String? userId,
          DateTime? openedAt,
          int? openingFloatCents,
          Value<DateTime?> closedAt = const Value.absent(),
          Value<int?> closingCashCents = const Value.absent(),
          String? status,
          Value<String?> note = const Value.absent()}) =>
      PosSession(
        id: id ?? this.id,
        terminalId: terminalId ?? this.terminalId,
        userId: userId ?? this.userId,
        openedAt: openedAt ?? this.openedAt,
        openingFloatCents: openingFloatCents ?? this.openingFloatCents,
        closedAt: closedAt.present ? closedAt.value : this.closedAt,
        closingCashCents: closingCashCents.present
            ? closingCashCents.value
            : this.closingCashCents,
        status: status ?? this.status,
        note: note.present ? note.value : this.note,
      );
  PosSession copyWithCompanion(PosSessionsCompanion data) {
    return PosSession(
      id: data.id.present ? data.id.value : this.id,
      terminalId:
          data.terminalId.present ? data.terminalId.value : this.terminalId,
      userId: data.userId.present ? data.userId.value : this.userId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openingFloatCents: data.openingFloatCents.present
          ? data.openingFloatCents.value
          : this.openingFloatCents,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      closingCashCents: data.closingCashCents.present
          ? data.closingCashCents.value
          : this.closingCashCents,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PosSession(')
          ..write('id: $id, ')
          ..write('terminalId: $terminalId, ')
          ..write('userId: $userId, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingFloatCents: $openingFloatCents, ')
          ..write('closedAt: $closedAt, ')
          ..write('closingCashCents: $closingCashCents, ')
          ..write('status: $status, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, terminalId, userId, openedAt,
      openingFloatCents, closedAt, closingCashCents, status, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PosSession &&
          other.id == this.id &&
          other.terminalId == this.terminalId &&
          other.userId == this.userId &&
          other.openedAt == this.openedAt &&
          other.openingFloatCents == this.openingFloatCents &&
          other.closedAt == this.closedAt &&
          other.closingCashCents == this.closingCashCents &&
          other.status == this.status &&
          other.note == this.note);
}

class PosSessionsCompanion extends UpdateCompanion<PosSession> {
  final Value<String> id;
  final Value<String> terminalId;
  final Value<String> userId;
  final Value<DateTime> openedAt;
  final Value<int> openingFloatCents;
  final Value<DateTime?> closedAt;
  final Value<int?> closingCashCents;
  final Value<String> status;
  final Value<String?> note;
  final Value<int> rowid;
  const PosSessionsCompanion({
    this.id = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.userId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openingFloatCents = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closingCashCents = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PosSessionsCompanion.insert({
    required String id,
    required String terminalId,
    required String userId,
    this.openedAt = const Value.absent(),
    this.openingFloatCents = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closingCashCents = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        terminalId = Value(terminalId),
        userId = Value(userId);
  static Insertable<PosSession> custom({
    Expression<String>? id,
    Expression<String>? terminalId,
    Expression<String>? userId,
    Expression<DateTime>? openedAt,
    Expression<int>? openingFloatCents,
    Expression<DateTime>? closedAt,
    Expression<int>? closingCashCents,
    Expression<String>? status,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (terminalId != null) 'terminal_id': terminalId,
      if (userId != null) 'user_id': userId,
      if (openedAt != null) 'opened_at': openedAt,
      if (openingFloatCents != null) 'opening_float_cents': openingFloatCents,
      if (closedAt != null) 'closed_at': closedAt,
      if (closingCashCents != null) 'closing_cash_cents': closingCashCents,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PosSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? terminalId,
      Value<String>? userId,
      Value<DateTime>? openedAt,
      Value<int>? openingFloatCents,
      Value<DateTime?>? closedAt,
      Value<int?>? closingCashCents,
      Value<String>? status,
      Value<String?>? note,
      Value<int>? rowid}) {
    return PosSessionsCompanion(
      id: id ?? this.id,
      terminalId: terminalId ?? this.terminalId,
      userId: userId ?? this.userId,
      openedAt: openedAt ?? this.openedAt,
      openingFloatCents: openingFloatCents ?? this.openingFloatCents,
      closedAt: closedAt ?? this.closedAt,
      closingCashCents: closingCashCents ?? this.closingCashCents,
      status: status ?? this.status,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (terminalId.present) {
      map['terminal_id'] = Variable<String>(terminalId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (openingFloatCents.present) {
      map['opening_float_cents'] = Variable<int>(openingFloatCents.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (closingCashCents.present) {
      map['closing_cash_cents'] = Variable<int>(closingCashCents.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PosSessionsCompanion(')
          ..write('id: $id, ')
          ..write('terminalId: $terminalId, ')
          ..write('userId: $userId, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingFloatCents: $openingFloatCents, ')
          ..write('closedAt: $closedAt, ')
          ..write('closingCashCents: $closingCashCents, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PosSessionCashBreakdownsTable extends PosSessionCashBreakdowns
    with TableInfo<$PosSessionCashBreakdownsTable, PosSessionCashBreakdown> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PosSessionCashBreakdownsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pos_sessions (id)'));
  static const VerificationMeta _denominationCentsMeta =
      const VerificationMeta('denominationCents');
  @override
  late final GeneratedColumn<int> denominationCents = GeneratedColumn<int>(
      'denomination_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitCountMeta =
      const VerificationMeta('unitCount');
  @override
  late final GeneratedColumn<int> unitCount = GeneratedColumn<int>(
      'unit_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _subtotalCentsMeta =
      const VerificationMeta('subtotalCents');
  @override
  late final GeneratedColumn<int> subtotalCents = GeneratedColumn<int>(
      'subtotal_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [sessionId, denominationCents, unitCount, subtotalCents];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pos_session_cash_breakdowns';
  @override
  VerificationContext validateIntegrity(
      Insertable<PosSessionCashBreakdown> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('denomination_cents')) {
      context.handle(
          _denominationCentsMeta,
          denominationCents.isAcceptableOrUnknown(
              data['denomination_cents']!, _denominationCentsMeta));
    } else if (isInserting) {
      context.missing(_denominationCentsMeta);
    }
    if (data.containsKey('unit_count')) {
      context.handle(_unitCountMeta,
          unitCount.isAcceptableOrUnknown(data['unit_count']!, _unitCountMeta));
    }
    if (data.containsKey('subtotal_cents')) {
      context.handle(
          _subtotalCentsMeta,
          subtotalCents.isAcceptableOrUnknown(
              data['subtotal_cents']!, _subtotalCentsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, denominationCents};
  @override
  PosSessionCashBreakdown map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PosSessionCashBreakdown(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      denominationCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}denomination_cents'])!,
      unitCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_count'])!,
      subtotalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subtotal_cents'])!,
    );
  }

  @override
  $PosSessionCashBreakdownsTable createAlias(String alias) {
    return $PosSessionCashBreakdownsTable(attachedDatabase, alias);
  }
}

class PosSessionCashBreakdown extends DataClass
    implements Insertable<PosSessionCashBreakdown> {
  final String sessionId;
  final int denominationCents;
  final int unitCount;
  final int subtotalCents;
  const PosSessionCashBreakdown(
      {required this.sessionId,
      required this.denominationCents,
      required this.unitCount,
      required this.subtotalCents});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['denomination_cents'] = Variable<int>(denominationCents);
    map['unit_count'] = Variable<int>(unitCount);
    map['subtotal_cents'] = Variable<int>(subtotalCents);
    return map;
  }

  PosSessionCashBreakdownsCompanion toCompanion(bool nullToAbsent) {
    return PosSessionCashBreakdownsCompanion(
      sessionId: Value(sessionId),
      denominationCents: Value(denominationCents),
      unitCount: Value(unitCount),
      subtotalCents: Value(subtotalCents),
    );
  }

  factory PosSessionCashBreakdown.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PosSessionCashBreakdown(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      denominationCents: serializer.fromJson<int>(json['denominationCents']),
      unitCount: serializer.fromJson<int>(json['unitCount']),
      subtotalCents: serializer.fromJson<int>(json['subtotalCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'denominationCents': serializer.toJson<int>(denominationCents),
      'unitCount': serializer.toJson<int>(unitCount),
      'subtotalCents': serializer.toJson<int>(subtotalCents),
    };
  }

  PosSessionCashBreakdown copyWith(
          {String? sessionId,
          int? denominationCents,
          int? unitCount,
          int? subtotalCents}) =>
      PosSessionCashBreakdown(
        sessionId: sessionId ?? this.sessionId,
        denominationCents: denominationCents ?? this.denominationCents,
        unitCount: unitCount ?? this.unitCount,
        subtotalCents: subtotalCents ?? this.subtotalCents,
      );
  PosSessionCashBreakdown copyWithCompanion(
      PosSessionCashBreakdownsCompanion data) {
    return PosSessionCashBreakdown(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      denominationCents: data.denominationCents.present
          ? data.denominationCents.value
          : this.denominationCents,
      unitCount: data.unitCount.present ? data.unitCount.value : this.unitCount,
      subtotalCents: data.subtotalCents.present
          ? data.subtotalCents.value
          : this.subtotalCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PosSessionCashBreakdown(')
          ..write('sessionId: $sessionId, ')
          ..write('denominationCents: $denominationCents, ')
          ..write('unitCount: $unitCount, ')
          ..write('subtotalCents: $subtotalCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sessionId, denominationCents, unitCount, subtotalCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PosSessionCashBreakdown &&
          other.sessionId == this.sessionId &&
          other.denominationCents == this.denominationCents &&
          other.unitCount == this.unitCount &&
          other.subtotalCents == this.subtotalCents);
}

class PosSessionCashBreakdownsCompanion
    extends UpdateCompanion<PosSessionCashBreakdown> {
  final Value<String> sessionId;
  final Value<int> denominationCents;
  final Value<int> unitCount;
  final Value<int> subtotalCents;
  final Value<int> rowid;
  const PosSessionCashBreakdownsCompanion({
    this.sessionId = const Value.absent(),
    this.denominationCents = const Value.absent(),
    this.unitCount = const Value.absent(),
    this.subtotalCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PosSessionCashBreakdownsCompanion.insert({
    required String sessionId,
    required int denominationCents,
    this.unitCount = const Value.absent(),
    this.subtotalCents = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        denominationCents = Value(denominationCents);
  static Insertable<PosSessionCashBreakdown> custom({
    Expression<String>? sessionId,
    Expression<int>? denominationCents,
    Expression<int>? unitCount,
    Expression<int>? subtotalCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (denominationCents != null) 'denomination_cents': denominationCents,
      if (unitCount != null) 'unit_count': unitCount,
      if (subtotalCents != null) 'subtotal_cents': subtotalCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PosSessionCashBreakdownsCompanion copyWith(
      {Value<String>? sessionId,
      Value<int>? denominationCents,
      Value<int>? unitCount,
      Value<int>? subtotalCents,
      Value<int>? rowid}) {
    return PosSessionCashBreakdownsCompanion(
      sessionId: sessionId ?? this.sessionId,
      denominationCents: denominationCents ?? this.denominationCents,
      unitCount: unitCount ?? this.unitCount,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (denominationCents.present) {
      map['denomination_cents'] = Variable<int>(denominationCents.value);
    }
    if (unitCount.present) {
      map['unit_count'] = Variable<int>(unitCount.value);
    }
    if (subtotalCents.present) {
      map['subtotal_cents'] = Variable<int>(subtotalCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PosSessionCashBreakdownsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('denominationCents: $denominationCents, ')
          ..write('unitCount: $unitCount, ')
          ..write('subtotalCents: $subtotalCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTable extends Employees
    with TableInfo<$EmployeesTable, Employee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
      'sex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _identityNumberMeta =
      const VerificationMeta('identityNumber');
  @override
  late final GeneratedColumn<String> identityNumber = GeneratedColumn<String>(
      'identity_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _associatedUserIdMeta =
      const VerificationMeta('associatedUserId');
  @override
  late final GeneratedColumn<String> associatedUserId = GeneratedColumn<String>(
      'associated_user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        code,
        name,
        sex,
        identityNumber,
        address,
        imagePath,
        associatedUserId,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(Insertable<Employee> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sex')) {
      context.handle(
          _sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    }
    if (data.containsKey('identity_number')) {
      context.handle(
          _identityNumberMeta,
          identityNumber.isAcceptableOrUnknown(
              data['identity_number']!, _identityNumberMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('associated_user_id')) {
      context.handle(
          _associatedUserIdMeta,
          associatedUserId.isAcceptableOrUnknown(
              data['associated_user_id']!, _associatedUserIdMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Employee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Employee(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex']),
      identityNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identity_number']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      associatedUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}associated_user_id']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $EmployeesTable createAlias(String alias) {
    return $EmployeesTable(attachedDatabase, alias);
  }
}

class Employee extends DataClass implements Insertable<Employee> {
  final String id;
  final String code;
  final String name;
  final String? sex;
  final String? identityNumber;
  final String? address;
  final String? imagePath;
  final String? associatedUserId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const Employee(
      {required this.id,
      required this.code,
      required this.name,
      this.sex,
      this.identityNumber,
      this.address,
      this.imagePath,
      this.associatedUserId,
      required this.isActive,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || identityNumber != null) {
      map['identity_number'] = Variable<String>(identityNumber);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || associatedUserId != null) {
      map['associated_user_id'] = Variable<String>(associatedUserId);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  EmployeesCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      identityNumber: identityNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(identityNumber),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      associatedUserId: associatedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(associatedUserId),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Employee(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      sex: serializer.fromJson<String?>(json['sex']),
      identityNumber: serializer.fromJson<String?>(json['identityNumber']),
      address: serializer.fromJson<String?>(json['address']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      associatedUserId: serializer.fromJson<String?>(json['associatedUserId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'sex': serializer.toJson<String?>(sex),
      'identityNumber': serializer.toJson<String?>(identityNumber),
      'address': serializer.toJson<String?>(address),
      'imagePath': serializer.toJson<String?>(imagePath),
      'associatedUserId': serializer.toJson<String?>(associatedUserId),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Employee copyWith(
          {String? id,
          String? code,
          String? name,
          Value<String?> sex = const Value.absent(),
          Value<String?> identityNumber = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          Value<String?> associatedUserId = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Employee(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        sex: sex.present ? sex.value : this.sex,
        identityNumber:
            identityNumber.present ? identityNumber.value : this.identityNumber,
        address: address.present ? address.value : this.address,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        associatedUserId: associatedUserId.present
            ? associatedUserId.value
            : this.associatedUserId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Employee copyWithCompanion(EmployeesCompanion data) {
    return Employee(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      sex: data.sex.present ? data.sex.value : this.sex,
      identityNumber: data.identityNumber.present
          ? data.identityNumber.value
          : this.identityNumber,
      address: data.address.present ? data.address.value : this.address,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      associatedUserId: data.associatedUserId.present
          ? data.associatedUserId.value
          : this.associatedUserId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Employee(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('address: $address, ')
          ..write('imagePath: $imagePath, ')
          ..write('associatedUserId: $associatedUserId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, sex, identityNumber, address,
      imagePath, associatedUserId, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employee &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.sex == this.sex &&
          other.identityNumber == this.identityNumber &&
          other.address == this.address &&
          other.imagePath == this.imagePath &&
          other.associatedUserId == this.associatedUserId &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EmployeesCompanion extends UpdateCompanion<Employee> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> sex;
  final Value<String?> identityNumber;
  final Value<String?> address;
  final Value<String?> imagePath;
  final Value<String?> associatedUserId;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const EmployeesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.sex = const Value.absent(),
    this.identityNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.associatedUserId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeesCompanion.insert({
    required String id,
    required String code,
    required String name,
    this.sex = const Value.absent(),
    this.identityNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.associatedUserId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        code = Value(code),
        name = Value(name);
  static Insertable<Employee> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? sex,
    Expression<String>? identityNumber,
    Expression<String>? address,
    Expression<String>? imagePath,
    Expression<String>? associatedUserId,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (sex != null) 'sex': sex,
      if (identityNumber != null) 'identity_number': identityNumber,
      if (address != null) 'address': address,
      if (imagePath != null) 'image_path': imagePath,
      if (associatedUserId != null) 'associated_user_id': associatedUserId,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeesCompanion copyWith(
      {Value<String>? id,
      Value<String>? code,
      Value<String>? name,
      Value<String?>? sex,
      Value<String?>? identityNumber,
      Value<String?>? address,
      Value<String?>? imagePath,
      Value<String?>? associatedUserId,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return EmployeesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      identityNumber: identityNumber ?? this.identityNumber,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      associatedUserId: associatedUserId ?? this.associatedUserId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (identityNumber.present) {
      map['identity_number'] = Variable<String>(identityNumber.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (associatedUserId.present) {
      map['associated_user_id'] = Variable<String>(associatedUserId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('address: $address, ')
          ..write('imagePath: $imagePath, ')
          ..write('associatedUserId: $associatedUserId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PosSessionEmployeesTable extends PosSessionEmployees
    with TableInfo<$PosSessionEmployeesTable, PosSessionEmployee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PosSessionEmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pos_sessions (id)'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _assignedAtMeta =
      const VerificationMeta('assignedAt');
  @override
  late final GeneratedColumn<DateTime> assignedAt = GeneratedColumn<DateTime>(
      'assigned_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [sessionId, employeeId, assignedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pos_session_employees';
  @override
  VerificationContext validateIntegrity(Insertable<PosSessionEmployee> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
          _assignedAtMeta,
          assignedAt.isAcceptableOrUnknown(
              data['assigned_at']!, _assignedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, employeeId};
  @override
  PosSessionEmployee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PosSessionEmployee(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      assignedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}assigned_at'])!,
    );
  }

  @override
  $PosSessionEmployeesTable createAlias(String alias) {
    return $PosSessionEmployeesTable(attachedDatabase, alias);
  }
}

class PosSessionEmployee extends DataClass
    implements Insertable<PosSessionEmployee> {
  final String sessionId;
  final String employeeId;
  final DateTime assignedAt;
  const PosSessionEmployee(
      {required this.sessionId,
      required this.employeeId,
      required this.assignedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['employee_id'] = Variable<String>(employeeId);
    map['assigned_at'] = Variable<DateTime>(assignedAt);
    return map;
  }

  PosSessionEmployeesCompanion toCompanion(bool nullToAbsent) {
    return PosSessionEmployeesCompanion(
      sessionId: Value(sessionId),
      employeeId: Value(employeeId),
      assignedAt: Value(assignedAt),
    );
  }

  factory PosSessionEmployee.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PosSessionEmployee(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      assignedAt: serializer.fromJson<DateTime>(json['assignedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'employeeId': serializer.toJson<String>(employeeId),
      'assignedAt': serializer.toJson<DateTime>(assignedAt),
    };
  }

  PosSessionEmployee copyWith(
          {String? sessionId, String? employeeId, DateTime? assignedAt}) =>
      PosSessionEmployee(
        sessionId: sessionId ?? this.sessionId,
        employeeId: employeeId ?? this.employeeId,
        assignedAt: assignedAt ?? this.assignedAt,
      );
  PosSessionEmployee copyWithCompanion(PosSessionEmployeesCompanion data) {
    return PosSessionEmployee(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      assignedAt:
          data.assignedAt.present ? data.assignedAt.value : this.assignedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PosSessionEmployee(')
          ..write('sessionId: $sessionId, ')
          ..write('employeeId: $employeeId, ')
          ..write('assignedAt: $assignedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, employeeId, assignedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PosSessionEmployee &&
          other.sessionId == this.sessionId &&
          other.employeeId == this.employeeId &&
          other.assignedAt == this.assignedAt);
}

class PosSessionEmployeesCompanion extends UpdateCompanion<PosSessionEmployee> {
  final Value<String> sessionId;
  final Value<String> employeeId;
  final Value<DateTime> assignedAt;
  final Value<int> rowid;
  const PosSessionEmployeesCompanion({
    this.sessionId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PosSessionEmployeesCompanion.insert({
    required String sessionId,
    required String employeeId,
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        employeeId = Value(employeeId);
  static Insertable<PosSessionEmployee> custom({
    Expression<String>? sessionId,
    Expression<String>? employeeId,
    Expression<DateTime>? assignedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (employeeId != null) 'employee_id': employeeId,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PosSessionEmployeesCompanion copyWith(
      {Value<String>? sessionId,
      Value<String>? employeeId,
      Value<DateTime>? assignedAt,
      Value<int>? rowid}) {
    return PosSessionEmployeesCompanion(
      sessionId: sessionId ?? this.sessionId,
      employeeId: employeeId ?? this.employeeId,
      assignedAt: assignedAt ?? this.assignedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<DateTime>(assignedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PosSessionEmployeesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('employeeId: $employeeId, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PosTerminalEmployeesTable extends PosTerminalEmployees
    with TableInfo<$PosTerminalEmployeesTable, PosTerminalEmployee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PosTerminalEmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _terminalIdMeta =
      const VerificationMeta('terminalId');
  @override
  late final GeneratedColumn<String> terminalId = GeneratedColumn<String>(
      'terminal_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pos_terminals (id)'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _assignedAtMeta =
      const VerificationMeta('assignedAt');
  @override
  late final GeneratedColumn<DateTime> assignedAt = GeneratedColumn<DateTime>(
      'assigned_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [terminalId, employeeId, assignedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pos_terminal_employees';
  @override
  VerificationContext validateIntegrity(
      Insertable<PosTerminalEmployee> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('terminal_id')) {
      context.handle(
          _terminalIdMeta,
          terminalId.isAcceptableOrUnknown(
              data['terminal_id']!, _terminalIdMeta));
    } else if (isInserting) {
      context.missing(_terminalIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
          _assignedAtMeta,
          assignedAt.isAcceptableOrUnknown(
              data['assigned_at']!, _assignedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {terminalId, employeeId};
  @override
  PosTerminalEmployee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PosTerminalEmployee(
      terminalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terminal_id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      assignedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}assigned_at'])!,
    );
  }

  @override
  $PosTerminalEmployeesTable createAlias(String alias) {
    return $PosTerminalEmployeesTable(attachedDatabase, alias);
  }
}

class PosTerminalEmployee extends DataClass
    implements Insertable<PosTerminalEmployee> {
  final String terminalId;
  final String employeeId;
  final DateTime assignedAt;
  const PosTerminalEmployee(
      {required this.terminalId,
      required this.employeeId,
      required this.assignedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['terminal_id'] = Variable<String>(terminalId);
    map['employee_id'] = Variable<String>(employeeId);
    map['assigned_at'] = Variable<DateTime>(assignedAt);
    return map;
  }

  PosTerminalEmployeesCompanion toCompanion(bool nullToAbsent) {
    return PosTerminalEmployeesCompanion(
      terminalId: Value(terminalId),
      employeeId: Value(employeeId),
      assignedAt: Value(assignedAt),
    );
  }

  factory PosTerminalEmployee.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PosTerminalEmployee(
      terminalId: serializer.fromJson<String>(json['terminalId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      assignedAt: serializer.fromJson<DateTime>(json['assignedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'terminalId': serializer.toJson<String>(terminalId),
      'employeeId': serializer.toJson<String>(employeeId),
      'assignedAt': serializer.toJson<DateTime>(assignedAt),
    };
  }

  PosTerminalEmployee copyWith(
          {String? terminalId, String? employeeId, DateTime? assignedAt}) =>
      PosTerminalEmployee(
        terminalId: terminalId ?? this.terminalId,
        employeeId: employeeId ?? this.employeeId,
        assignedAt: assignedAt ?? this.assignedAt,
      );
  PosTerminalEmployee copyWithCompanion(PosTerminalEmployeesCompanion data) {
    return PosTerminalEmployee(
      terminalId:
          data.terminalId.present ? data.terminalId.value : this.terminalId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      assignedAt:
          data.assignedAt.present ? data.assignedAt.value : this.assignedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PosTerminalEmployee(')
          ..write('terminalId: $terminalId, ')
          ..write('employeeId: $employeeId, ')
          ..write('assignedAt: $assignedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(terminalId, employeeId, assignedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PosTerminalEmployee &&
          other.terminalId == this.terminalId &&
          other.employeeId == this.employeeId &&
          other.assignedAt == this.assignedAt);
}

class PosTerminalEmployeesCompanion
    extends UpdateCompanion<PosTerminalEmployee> {
  final Value<String> terminalId;
  final Value<String> employeeId;
  final Value<DateTime> assignedAt;
  final Value<int> rowid;
  const PosTerminalEmployeesCompanion({
    this.terminalId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PosTerminalEmployeesCompanion.insert({
    required String terminalId,
    required String employeeId,
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : terminalId = Value(terminalId),
        employeeId = Value(employeeId);
  static Insertable<PosTerminalEmployee> custom({
    Expression<String>? terminalId,
    Expression<String>? employeeId,
    Expression<DateTime>? assignedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (terminalId != null) 'terminal_id': terminalId,
      if (employeeId != null) 'employee_id': employeeId,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PosTerminalEmployeesCompanion copyWith(
      {Value<String>? terminalId,
      Value<String>? employeeId,
      Value<DateTime>? assignedAt,
      Value<int>? rowid}) {
    return PosTerminalEmployeesCompanion(
      terminalId: terminalId ?? this.terminalId,
      employeeId: employeeId ?? this.employeeId,
      assignedAt: assignedAt ?? this.assignedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (terminalId.present) {
      map['terminal_id'] = Variable<String>(terminalId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<DateTime>(assignedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PosTerminalEmployeesCompanion(')
          ..write('terminalId: $terminalId, ')
          ..write('employeeId: $employeeId, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockBalancesTable extends StockBalances
    with TableInfo<$StockBalancesTable, StockBalance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockBalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _warehouseIdMeta =
      const VerificationMeta('warehouseId');
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
      'warehouse_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES warehouses (id)'));
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
      'qty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [productId, warehouseId, qty, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_balances';
  @override
  VerificationContext validateIntegrity(Insertable<StockBalance> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
          _warehouseIdMeta,
          warehouseId.isAcceptableOrUnknown(
              data['warehouse_id']!, _warehouseIdMeta));
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, warehouseId};
  @override
  StockBalance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockBalance(
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      warehouseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}warehouse_id'])!,
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StockBalancesTable createAlias(String alias) {
    return $StockBalancesTable(attachedDatabase, alias);
  }
}

class StockBalance extends DataClass implements Insertable<StockBalance> {
  final String productId;
  final String warehouseId;
  final double qty;
  final DateTime updatedAt;
  const StockBalance(
      {required this.productId,
      required this.warehouseId,
      required this.qty,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['qty'] = Variable<double>(qty);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StockBalancesCompanion toCompanion(bool nullToAbsent) {
    return StockBalancesCompanion(
      productId: Value(productId),
      warehouseId: Value(warehouseId),
      qty: Value(qty),
      updatedAt: Value(updatedAt),
    );
  }

  factory StockBalance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockBalance(
      productId: serializer.fromJson<String>(json['productId']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      qty: serializer.fromJson<double>(json['qty']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'qty': serializer.toJson<double>(qty),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StockBalance copyWith(
          {String? productId,
          String? warehouseId,
          double? qty,
          DateTime? updatedAt}) =>
      StockBalance(
        productId: productId ?? this.productId,
        warehouseId: warehouseId ?? this.warehouseId,
        qty: qty ?? this.qty,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  StockBalance copyWithCompanion(StockBalancesCompanion data) {
    return StockBalance(
      productId: data.productId.present ? data.productId.value : this.productId,
      warehouseId:
          data.warehouseId.present ? data.warehouseId.value : this.warehouseId,
      qty: data.qty.present ? data.qty.value : this.qty,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockBalance(')
          ..write('productId: $productId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('qty: $qty, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, warehouseId, qty, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockBalance &&
          other.productId == this.productId &&
          other.warehouseId == this.warehouseId &&
          other.qty == this.qty &&
          other.updatedAt == this.updatedAt);
}

class StockBalancesCompanion extends UpdateCompanion<StockBalance> {
  final Value<String> productId;
  final Value<String> warehouseId;
  final Value<double> qty;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StockBalancesCompanion({
    this.productId = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.qty = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockBalancesCompanion.insert({
    required String productId,
    required String warehouseId,
    this.qty = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : productId = Value(productId),
        warehouseId = Value(warehouseId);
  static Insertable<StockBalance> custom({
    Expression<String>? productId,
    Expression<String>? warehouseId,
    Expression<double>? qty,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (qty != null) 'qty': qty,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockBalancesCompanion copyWith(
      {Value<String>? productId,
      Value<String>? warehouseId,
      Value<double>? qty,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return StockBalancesCompanion(
      productId: productId ?? this.productId,
      warehouseId: warehouseId ?? this.warehouseId,
      qty: qty ?? this.qty,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockBalancesCompanion(')
          ..write('productId: $productId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('qty: $qty, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _warehouseIdMeta =
      const VerificationMeta('warehouseId');
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
      'warehouse_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES warehouses (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
      'qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reasonCodeMeta =
      const VerificationMeta('reasonCode');
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
      'reason_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _movementSourceMeta =
      const VerificationMeta('movementSource');
  @override
  late final GeneratedColumn<String> movementSource = GeneratedColumn<String>(
      'movement_source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _refTypeMeta =
      const VerificationMeta('refType');
  @override
  late final GeneratedColumn<String> refType = GeneratedColumn<String>(
      'ref_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
      'ref_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isVoidedMeta =
      const VerificationMeta('isVoided');
  @override
  late final GeneratedColumn<bool> isVoided = GeneratedColumn<bool>(
      'is_voided', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_voided" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _voidedAtMeta =
      const VerificationMeta('voidedAt');
  @override
  late final GeneratedColumn<DateTime> voidedAt = GeneratedColumn<DateTime>(
      'voided_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _voidedByMeta =
      const VerificationMeta('voidedBy');
  @override
  late final GeneratedColumn<String> voidedBy = GeneratedColumn<String>(
      'voided_by', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _voidNoteMeta =
      const VerificationMeta('voidNote');
  @override
  late final GeneratedColumn<String> voidNote = GeneratedColumn<String>(
      'void_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        productId,
        warehouseId,
        type,
        qty,
        reasonCode,
        movementSource,
        refType,
        refId,
        note,
        isVoided,
        voidedAt,
        voidedBy,
        voidNote,
        createdBy,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(Insertable<StockMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
          _warehouseIdMeta,
          warehouseId.isAcceptableOrUnknown(
              data['warehouse_id']!, _warehouseIdMeta));
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
          _reasonCodeMeta,
          reasonCode.isAcceptableOrUnknown(
              data['reason_code']!, _reasonCodeMeta));
    }
    if (data.containsKey('movement_source')) {
      context.handle(
          _movementSourceMeta,
          movementSource.isAcceptableOrUnknown(
              data['movement_source']!, _movementSourceMeta));
    }
    if (data.containsKey('ref_type')) {
      context.handle(_refTypeMeta,
          refType.isAcceptableOrUnknown(data['ref_type']!, _refTypeMeta));
    }
    if (data.containsKey('ref_id')) {
      context.handle(
          _refIdMeta, refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('is_voided')) {
      context.handle(_isVoidedMeta,
          isVoided.isAcceptableOrUnknown(data['is_voided']!, _isVoidedMeta));
    }
    if (data.containsKey('voided_at')) {
      context.handle(_voidedAtMeta,
          voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta));
    }
    if (data.containsKey('voided_by')) {
      context.handle(_voidedByMeta,
          voidedBy.isAcceptableOrUnknown(data['voided_by']!, _voidedByMeta));
    }
    if (data.containsKey('void_note')) {
      context.handle(_voidNoteMeta,
          voidNote.isAcceptableOrUnknown(data['void_note']!, _voidNoteMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      warehouseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}warehouse_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty'])!,
      reasonCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason_code']),
      movementSource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}movement_source'])!,
      refType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_type']),
      refId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      isVoided: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_voided'])!,
      voidedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}voided_at']),
      voidedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voided_by']),
      voidNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}void_note']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final String id;
  final String productId;
  final String warehouseId;
  final String type;
  final double qty;
  final String? reasonCode;
  final String movementSource;
  final String? refType;
  final String? refId;
  final String? note;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidNote;
  final String createdBy;
  final DateTime createdAt;
  const StockMovement(
      {required this.id,
      required this.productId,
      required this.warehouseId,
      required this.type,
      required this.qty,
      this.reasonCode,
      required this.movementSource,
      this.refType,
      this.refId,
      this.note,
      required this.isVoided,
      this.voidedAt,
      this.voidedBy,
      this.voidNote,
      required this.createdBy,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['type'] = Variable<String>(type);
    map['qty'] = Variable<double>(qty);
    if (!nullToAbsent || reasonCode != null) {
      map['reason_code'] = Variable<String>(reasonCode);
    }
    map['movement_source'] = Variable<String>(movementSource);
    if (!nullToAbsent || refType != null) {
      map['ref_type'] = Variable<String>(refType);
    }
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<String>(refId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_voided'] = Variable<bool>(isVoided);
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    if (!nullToAbsent || voidedBy != null) {
      map['voided_by'] = Variable<String>(voidedBy);
    }
    if (!nullToAbsent || voidNote != null) {
      map['void_note'] = Variable<String>(voidNote);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      warehouseId: Value(warehouseId),
      type: Value(type),
      qty: Value(qty),
      reasonCode: reasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonCode),
      movementSource: Value(movementSource),
      refType: refType == null && nullToAbsent
          ? const Value.absent()
          : Value(refType),
      refId:
          refId == null && nullToAbsent ? const Value.absent() : Value(refId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isVoided: Value(isVoided),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
      voidedBy: voidedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedBy),
      voidNote: voidNote == null && nullToAbsent
          ? const Value.absent()
          : Value(voidNote),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
    );
  }

  factory StockMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      type: serializer.fromJson<String>(json['type']),
      qty: serializer.fromJson<double>(json['qty']),
      reasonCode: serializer.fromJson<String?>(json['reasonCode']),
      movementSource: serializer.fromJson<String>(json['movementSource']),
      refType: serializer.fromJson<String?>(json['refType']),
      refId: serializer.fromJson<String?>(json['refId']),
      note: serializer.fromJson<String?>(json['note']),
      isVoided: serializer.fromJson<bool>(json['isVoided']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
      voidedBy: serializer.fromJson<String?>(json['voidedBy']),
      voidNote: serializer.fromJson<String?>(json['voidNote']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'type': serializer.toJson<String>(type),
      'qty': serializer.toJson<double>(qty),
      'reasonCode': serializer.toJson<String?>(reasonCode),
      'movementSource': serializer.toJson<String>(movementSource),
      'refType': serializer.toJson<String?>(refType),
      'refId': serializer.toJson<String?>(refId),
      'note': serializer.toJson<String?>(note),
      'isVoided': serializer.toJson<bool>(isVoided),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
      'voidedBy': serializer.toJson<String?>(voidedBy),
      'voidNote': serializer.toJson<String?>(voidNote),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StockMovement copyWith(
          {String? id,
          String? productId,
          String? warehouseId,
          String? type,
          double? qty,
          Value<String?> reasonCode = const Value.absent(),
          String? movementSource,
          Value<String?> refType = const Value.absent(),
          Value<String?> refId = const Value.absent(),
          Value<String?> note = const Value.absent(),
          bool? isVoided,
          Value<DateTime?> voidedAt = const Value.absent(),
          Value<String?> voidedBy = const Value.absent(),
          Value<String?> voidNote = const Value.absent(),
          String? createdBy,
          DateTime? createdAt}) =>
      StockMovement(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        warehouseId: warehouseId ?? this.warehouseId,
        type: type ?? this.type,
        qty: qty ?? this.qty,
        reasonCode: reasonCode.present ? reasonCode.value : this.reasonCode,
        movementSource: movementSource ?? this.movementSource,
        refType: refType.present ? refType.value : this.refType,
        refId: refId.present ? refId.value : this.refId,
        note: note.present ? note.value : this.note,
        isVoided: isVoided ?? this.isVoided,
        voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
        voidedBy: voidedBy.present ? voidedBy.value : this.voidedBy,
        voidNote: voidNote.present ? voidNote.value : this.voidNote,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      warehouseId:
          data.warehouseId.present ? data.warehouseId.value : this.warehouseId,
      type: data.type.present ? data.type.value : this.type,
      qty: data.qty.present ? data.qty.value : this.qty,
      reasonCode:
          data.reasonCode.present ? data.reasonCode.value : this.reasonCode,
      movementSource: data.movementSource.present
          ? data.movementSource.value
          : this.movementSource,
      refType: data.refType.present ? data.refType.value : this.refType,
      refId: data.refId.present ? data.refId.value : this.refId,
      note: data.note.present ? data.note.value : this.note,
      isVoided: data.isVoided.present ? data.isVoided.value : this.isVoided,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      voidedBy: data.voidedBy.present ? data.voidedBy.value : this.voidedBy,
      voidNote: data.voidNote.present ? data.voidNote.value : this.voidNote,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('type: $type, ')
          ..write('qty: $qty, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('movementSource: $movementSource, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('note: $note, ')
          ..write('isVoided: $isVoided, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidedBy: $voidedBy, ')
          ..write('voidNote: $voidNote, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      productId,
      warehouseId,
      type,
      qty,
      reasonCode,
      movementSource,
      refType,
      refId,
      note,
      isVoided,
      voidedAt,
      voidedBy,
      voidNote,
      createdBy,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.warehouseId == this.warehouseId &&
          other.type == this.type &&
          other.qty == this.qty &&
          other.reasonCode == this.reasonCode &&
          other.movementSource == this.movementSource &&
          other.refType == this.refType &&
          other.refId == this.refId &&
          other.note == this.note &&
          other.isVoided == this.isVoided &&
          other.voidedAt == this.voidedAt &&
          other.voidedBy == this.voidedBy &&
          other.voidNote == this.voidNote &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> warehouseId;
  final Value<String> type;
  final Value<double> qty;
  final Value<String?> reasonCode;
  final Value<String> movementSource;
  final Value<String?> refType;
  final Value<String?> refId;
  final Value<String?> note;
  final Value<bool> isVoided;
  final Value<DateTime?> voidedAt;
  final Value<String?> voidedBy;
  final Value<String?> voidNote;
  final Value<String> createdBy;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.type = const Value.absent(),
    this.qty = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.movementSource = const Value.absent(),
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.note = const Value.absent(),
    this.isVoided = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.voidedBy = const Value.absent(),
    this.voidNote = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String productId,
    required String warehouseId,
    required String type,
    required double qty,
    this.reasonCode = const Value.absent(),
    this.movementSource = const Value.absent(),
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.note = const Value.absent(),
    this.isVoided = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.voidedBy = const Value.absent(),
    this.voidNote = const Value.absent(),
    required String createdBy,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        productId = Value(productId),
        warehouseId = Value(warehouseId),
        type = Value(type),
        qty = Value(qty),
        createdBy = Value(createdBy);
  static Insertable<StockMovement> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? warehouseId,
    Expression<String>? type,
    Expression<double>? qty,
    Expression<String>? reasonCode,
    Expression<String>? movementSource,
    Expression<String>? refType,
    Expression<String>? refId,
    Expression<String>? note,
    Expression<bool>? isVoided,
    Expression<DateTime>? voidedAt,
    Expression<String>? voidedBy,
    Expression<String>? voidNote,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (type != null) 'type': type,
      if (qty != null) 'qty': qty,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (movementSource != null) 'movement_source': movementSource,
      if (refType != null) 'ref_type': refType,
      if (refId != null) 'ref_id': refId,
      if (note != null) 'note': note,
      if (isVoided != null) 'is_voided': isVoided,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (voidedBy != null) 'voided_by': voidedBy,
      if (voidNote != null) 'void_note': voidNote,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? productId,
      Value<String>? warehouseId,
      Value<String>? type,
      Value<double>? qty,
      Value<String?>? reasonCode,
      Value<String>? movementSource,
      Value<String?>? refType,
      Value<String?>? refId,
      Value<String?>? note,
      Value<bool>? isVoided,
      Value<DateTime?>? voidedAt,
      Value<String?>? voidedBy,
      Value<String?>? voidNote,
      Value<String>? createdBy,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      warehouseId: warehouseId ?? this.warehouseId,
      type: type ?? this.type,
      qty: qty ?? this.qty,
      reasonCode: reasonCode ?? this.reasonCode,
      movementSource: movementSource ?? this.movementSource,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      note: note ?? this.note,
      isVoided: isVoided ?? this.isVoided,
      voidedAt: voidedAt ?? this.voidedAt,
      voidedBy: voidedBy ?? this.voidedBy,
      voidNote: voidNote ?? this.voidNote,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (movementSource.present) {
      map['movement_source'] = Variable<String>(movementSource.value);
    }
    if (refType.present) {
      map['ref_type'] = Variable<String>(refType.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isVoided.present) {
      map['is_voided'] = Variable<bool>(isVoided.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    if (voidedBy.present) {
      map['voided_by'] = Variable<String>(voidedBy.value);
    }
    if (voidNote.present) {
      map['void_note'] = Variable<String>(voidNote.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('type: $type, ')
          ..write('qty: $qty, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('movementSource: $movementSource, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('note: $note, ')
          ..write('isVoided: $isVoided, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidedBy: $voidedBy, ')
          ..write('voidNote: $voidNote, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _identityNumberMeta =
      const VerificationMeta('identityNumber');
  @override
  late final GeneratedColumn<String> identityNumber = GeneratedColumn<String>(
      'identity_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerTypeMeta =
      const VerificationMeta('customerType');
  @override
  late final GeneratedColumn<String> customerType = GeneratedColumn<String>(
      'customer_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('general'));
  static const VerificationMeta _isVipMeta = const VerificationMeta('isVip');
  @override
  late final GeneratedColumn<bool> isVip = GeneratedColumn<bool>(
      'is_vip', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_vip" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _creditAvailableCentsMeta =
      const VerificationMeta('creditAvailableCents');
  @override
  late final GeneratedColumn<int> creditAvailableCents = GeneratedColumn<int>(
      'credit_available_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountBpsMeta =
      const VerificationMeta('discountBps');
  @override
  late final GeneratedColumn<int> discountBps = GeneratedColumn<int>(
      'discount_bps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _adminNoteMeta =
      const VerificationMeta('adminNote');
  @override
  late final GeneratedColumn<String> adminNote = GeneratedColumn<String>(
      'admin_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        code,
        fullName,
        identityNumber,
        phone,
        email,
        address,
        company,
        avatarPath,
        customerType,
        isVip,
        creditAvailableCents,
        discountBps,
        adminNote,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('identity_number')) {
      context.handle(
          _identityNumberMeta,
          identityNumber.isAcceptableOrUnknown(
              data['identity_number']!, _identityNumberMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('customer_type')) {
      context.handle(
          _customerTypeMeta,
          customerType.isAcceptableOrUnknown(
              data['customer_type']!, _customerTypeMeta));
    }
    if (data.containsKey('is_vip')) {
      context.handle(
          _isVipMeta, isVip.isAcceptableOrUnknown(data['is_vip']!, _isVipMeta));
    }
    if (data.containsKey('credit_available_cents')) {
      context.handle(
          _creditAvailableCentsMeta,
          creditAvailableCents.isAcceptableOrUnknown(
              data['credit_available_cents']!, _creditAvailableCentsMeta));
    }
    if (data.containsKey('discount_bps')) {
      context.handle(
          _discountBpsMeta,
          discountBps.isAcceptableOrUnknown(
              data['discount_bps']!, _discountBpsMeta));
    }
    if (data.containsKey('admin_note')) {
      context.handle(_adminNoteMeta,
          adminNote.isAcceptableOrUnknown(data['admin_note']!, _adminNoteMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      identityNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identity_number']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company']),
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      customerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_type'])!,
      isVip: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_vip'])!,
      creditAvailableCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}credit_available_cents'])!,
      discountBps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}discount_bps'])!,
      adminNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}admin_note']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
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
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const Customer(
      {required this.id,
      required this.code,
      required this.fullName,
      this.identityNumber,
      this.phone,
      this.email,
      this.address,
      this.company,
      this.avatarPath,
      required this.customerType,
      required this.isVip,
      required this.creditAvailableCents,
      required this.discountBps,
      this.adminNote,
      required this.isActive,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || identityNumber != null) {
      map['identity_number'] = Variable<String>(identityNumber);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['customer_type'] = Variable<String>(customerType);
    map['is_vip'] = Variable<bool>(isVip);
    map['credit_available_cents'] = Variable<int>(creditAvailableCents);
    map['discount_bps'] = Variable<int>(discountBps);
    if (!nullToAbsent || adminNote != null) {
      map['admin_note'] = Variable<String>(adminNote);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      code: Value(code),
      fullName: Value(fullName),
      identityNumber: identityNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(identityNumber),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      customerType: Value(customerType),
      isVip: Value(isVip),
      creditAvailableCents: Value(creditAvailableCents),
      discountBps: Value(discountBps),
      adminNote: adminNote == null && nullToAbsent
          ? const Value.absent()
          : Value(adminNote),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      fullName: serializer.fromJson<String>(json['fullName']),
      identityNumber: serializer.fromJson<String?>(json['identityNumber']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      company: serializer.fromJson<String?>(json['company']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      customerType: serializer.fromJson<String>(json['customerType']),
      isVip: serializer.fromJson<bool>(json['isVip']),
      creditAvailableCents:
          serializer.fromJson<int>(json['creditAvailableCents']),
      discountBps: serializer.fromJson<int>(json['discountBps']),
      adminNote: serializer.fromJson<String?>(json['adminNote']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'fullName': serializer.toJson<String>(fullName),
      'identityNumber': serializer.toJson<String?>(identityNumber),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'company': serializer.toJson<String?>(company),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'customerType': serializer.toJson<String>(customerType),
      'isVip': serializer.toJson<bool>(isVip),
      'creditAvailableCents': serializer.toJson<int>(creditAvailableCents),
      'discountBps': serializer.toJson<int>(discountBps),
      'adminNote': serializer.toJson<String?>(adminNote),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Customer copyWith(
          {String? id,
          String? code,
          String? fullName,
          Value<String?> identityNumber = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> company = const Value.absent(),
          Value<String?> avatarPath = const Value.absent(),
          String? customerType,
          bool? isVip,
          int? creditAvailableCents,
          int? discountBps,
          Value<String?> adminNote = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Customer(
        id: id ?? this.id,
        code: code ?? this.code,
        fullName: fullName ?? this.fullName,
        identityNumber:
            identityNumber.present ? identityNumber.value : this.identityNumber,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        address: address.present ? address.value : this.address,
        company: company.present ? company.value : this.company,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        customerType: customerType ?? this.customerType,
        isVip: isVip ?? this.isVip,
        creditAvailableCents: creditAvailableCents ?? this.creditAvailableCents,
        discountBps: discountBps ?? this.discountBps,
        adminNote: adminNote.present ? adminNote.value : this.adminNote,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      identityNumber: data.identityNumber.present
          ? data.identityNumber.value
          : this.identityNumber,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      company: data.company.present ? data.company.value : this.company,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      customerType: data.customerType.present
          ? data.customerType.value
          : this.customerType,
      isVip: data.isVip.present ? data.isVip.value : this.isVip,
      creditAvailableCents: data.creditAvailableCents.present
          ? data.creditAvailableCents.value
          : this.creditAvailableCents,
      discountBps:
          data.discountBps.present ? data.discountBps.value : this.discountBps,
      adminNote: data.adminNote.present ? data.adminNote.value : this.adminNote,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('fullName: $fullName, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('company: $company, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('customerType: $customerType, ')
          ..write('isVip: $isVip, ')
          ..write('creditAvailableCents: $creditAvailableCents, ')
          ..write('discountBps: $discountBps, ')
          ..write('adminNote: $adminNote, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      code,
      fullName,
      identityNumber,
      phone,
      email,
      address,
      company,
      avatarPath,
      customerType,
      isVip,
      creditAvailableCents,
      discountBps,
      adminNote,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.code == this.code &&
          other.fullName == this.fullName &&
          other.identityNumber == this.identityNumber &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.company == this.company &&
          other.avatarPath == this.avatarPath &&
          other.customerType == this.customerType &&
          other.isVip == this.isVip &&
          other.creditAvailableCents == this.creditAvailableCents &&
          other.discountBps == this.discountBps &&
          other.adminNote == this.adminNote &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> fullName;
  final Value<String?> identityNumber;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> company;
  final Value<String?> avatarPath;
  final Value<String> customerType;
  final Value<bool> isVip;
  final Value<int> creditAvailableCents;
  final Value<int> discountBps;
  final Value<String?> adminNote;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.fullName = const Value.absent(),
    this.identityNumber = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.company = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.customerType = const Value.absent(),
    this.isVip = const Value.absent(),
    this.creditAvailableCents = const Value.absent(),
    this.discountBps = const Value.absent(),
    this.adminNote = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String code,
    required String fullName,
    this.identityNumber = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.company = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.customerType = const Value.absent(),
    this.isVip = const Value.absent(),
    this.creditAvailableCents = const Value.absent(),
    this.discountBps = const Value.absent(),
    this.adminNote = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        code = Value(code),
        fullName = Value(fullName);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? fullName,
    Expression<String>? identityNumber,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? company,
    Expression<String>? avatarPath,
    Expression<String>? customerType,
    Expression<bool>? isVip,
    Expression<int>? creditAvailableCents,
    Expression<int>? discountBps,
    Expression<String>? adminNote,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (fullName != null) 'full_name': fullName,
      if (identityNumber != null) 'identity_number': identityNumber,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (company != null) 'company': company,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (customerType != null) 'customer_type': customerType,
      if (isVip != null) 'is_vip': isVip,
      if (creditAvailableCents != null)
        'credit_available_cents': creditAvailableCents,
      if (discountBps != null) 'discount_bps': discountBps,
      if (adminNote != null) 'admin_note': adminNote,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? code,
      Value<String>? fullName,
      Value<String?>? identityNumber,
      Value<String?>? phone,
      Value<String?>? email,
      Value<String?>? address,
      Value<String?>? company,
      Value<String?>? avatarPath,
      Value<String>? customerType,
      Value<bool>? isVip,
      Value<int>? creditAvailableCents,
      Value<int>? discountBps,
      Value<String?>? adminNote,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return CustomersCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      fullName: fullName ?? this.fullName,
      identityNumber: identityNumber ?? this.identityNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      company: company ?? this.company,
      avatarPath: avatarPath ?? this.avatarPath,
      customerType: customerType ?? this.customerType,
      isVip: isVip ?? this.isVip,
      creditAvailableCents: creditAvailableCents ?? this.creditAvailableCents,
      discountBps: discountBps ?? this.discountBps,
      adminNote: adminNote ?? this.adminNote,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (identityNumber.present) {
      map['identity_number'] = Variable<String>(identityNumber.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (customerType.present) {
      map['customer_type'] = Variable<String>(customerType.value);
    }
    if (isVip.present) {
      map['is_vip'] = Variable<bool>(isVip.value);
    }
    if (creditAvailableCents.present) {
      map['credit_available_cents'] = Variable<int>(creditAvailableCents.value);
    }
    if (discountBps.present) {
      map['discount_bps'] = Variable<int>(discountBps.value);
    }
    if (adminNote.present) {
      map['admin_note'] = Variable<String>(adminNote.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('fullName: $fullName, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('company: $company, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('customerType: $customerType, ')
          ..write('isVip: $isVip, ')
          ..write('creditAvailableCents: $creditAvailableCents, ')
          ..write('discountBps: $discountBps, ')
          ..write('adminNote: $adminNote, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folioMeta = const VerificationMeta('folio');
  @override
  late final GeneratedColumn<String> folio = GeneratedColumn<String>(
      'folio', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _warehouseIdMeta =
      const VerificationMeta('warehouseId');
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
      'warehouse_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES warehouses (id)'));
  static const VerificationMeta _cashierIdMeta =
      const VerificationMeta('cashierId');
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
      'cashier_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES customers (id)'));
  static const VerificationMeta _terminalIdMeta =
      const VerificationMeta('terminalId');
  @override
  late final GeneratedColumn<String> terminalId = GeneratedColumn<String>(
      'terminal_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pos_terminals (id)'));
  static const VerificationMeta _terminalSessionIdMeta =
      const VerificationMeta('terminalSessionId');
  @override
  late final GeneratedColumn<String> terminalSessionId =
      GeneratedColumn<String>('terminal_session_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES pos_sessions (id)'));
  static const VerificationMeta _subtotalCentsMeta =
      const VerificationMeta('subtotalCents');
  @override
  late final GeneratedColumn<int> subtotalCents = GeneratedColumn<int>(
      'subtotal_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _taxCentsMeta =
      const VerificationMeta('taxCents');
  @override
  late final GeneratedColumn<int> taxCents = GeneratedColumn<int>(
      'tax_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalCentsMeta =
      const VerificationMeta('totalCents');
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
      'total_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('posted'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        folio,
        warehouseId,
        cashierId,
        customerId,
        terminalId,
        terminalSessionId,
        subtotalCents,
        taxCents,
        totalCents,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(Insertable<Sale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folio')) {
      context.handle(
          _folioMeta, folio.isAcceptableOrUnknown(data['folio']!, _folioMeta));
    } else if (isInserting) {
      context.missing(_folioMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
          _warehouseIdMeta,
          warehouseId.isAcceptableOrUnknown(
              data['warehouse_id']!, _warehouseIdMeta));
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(_cashierIdMeta,
          cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta));
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('terminal_id')) {
      context.handle(
          _terminalIdMeta,
          terminalId.isAcceptableOrUnknown(
              data['terminal_id']!, _terminalIdMeta));
    }
    if (data.containsKey('terminal_session_id')) {
      context.handle(
          _terminalSessionIdMeta,
          terminalSessionId.isAcceptableOrUnknown(
              data['terminal_session_id']!, _terminalSessionIdMeta));
    }
    if (data.containsKey('subtotal_cents')) {
      context.handle(
          _subtotalCentsMeta,
          subtotalCents.isAcceptableOrUnknown(
              data['subtotal_cents']!, _subtotalCentsMeta));
    } else if (isInserting) {
      context.missing(_subtotalCentsMeta);
    }
    if (data.containsKey('tax_cents')) {
      context.handle(_taxCentsMeta,
          taxCents.isAcceptableOrUnknown(data['tax_cents']!, _taxCentsMeta));
    } else if (isInserting) {
      context.missing(_taxCentsMeta);
    }
    if (data.containsKey('total_cents')) {
      context.handle(
          _totalCentsMeta,
          totalCents.isAcceptableOrUnknown(
              data['total_cents']!, _totalCentsMeta));
    } else if (isInserting) {
      context.missing(_totalCentsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      folio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folio'])!,
      warehouseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}warehouse_id'])!,
      cashierId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cashier_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      terminalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terminal_id']),
      terminalSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}terminal_session_id']),
      subtotalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subtotal_cents'])!,
      taxCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tax_cents'])!,
      totalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_cents'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String id;
  final String folio;
  final String warehouseId;
  final String cashierId;
  final String? customerId;
  final String? terminalId;
  final String? terminalSessionId;
  final int subtotalCents;
  final int taxCents;
  final int totalCents;
  final String status;
  final DateTime createdAt;
  const Sale(
      {required this.id,
      required this.folio,
      required this.warehouseId,
      required this.cashierId,
      this.customerId,
      this.terminalId,
      this.terminalSessionId,
      required this.subtotalCents,
      required this.taxCents,
      required this.totalCents,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['folio'] = Variable<String>(folio);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    if (!nullToAbsent || terminalId != null) {
      map['terminal_id'] = Variable<String>(terminalId);
    }
    if (!nullToAbsent || terminalSessionId != null) {
      map['terminal_session_id'] = Variable<String>(terminalSessionId);
    }
    map['subtotal_cents'] = Variable<int>(subtotalCents);
    map['tax_cents'] = Variable<int>(taxCents);
    map['total_cents'] = Variable<int>(totalCents);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      folio: Value(folio),
      warehouseId: Value(warehouseId),
      cashierId: Value(cashierId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      terminalId: terminalId == null && nullToAbsent
          ? const Value.absent()
          : Value(terminalId),
      terminalSessionId: terminalSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(terminalSessionId),
      subtotalCents: Value(subtotalCents),
      taxCents: Value(taxCents),
      totalCents: Value(totalCents),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Sale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<String>(json['id']),
      folio: serializer.fromJson<String>(json['folio']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      terminalId: serializer.fromJson<String?>(json['terminalId']),
      terminalSessionId:
          serializer.fromJson<String?>(json['terminalSessionId']),
      subtotalCents: serializer.fromJson<int>(json['subtotalCents']),
      taxCents: serializer.fromJson<int>(json['taxCents']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folio': serializer.toJson<String>(folio),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'cashierId': serializer.toJson<String>(cashierId),
      'customerId': serializer.toJson<String?>(customerId),
      'terminalId': serializer.toJson<String?>(terminalId),
      'terminalSessionId': serializer.toJson<String?>(terminalSessionId),
      'subtotalCents': serializer.toJson<int>(subtotalCents),
      'taxCents': serializer.toJson<int>(taxCents),
      'totalCents': serializer.toJson<int>(totalCents),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sale copyWith(
          {String? id,
          String? folio,
          String? warehouseId,
          String? cashierId,
          Value<String?> customerId = const Value.absent(),
          Value<String?> terminalId = const Value.absent(),
          Value<String?> terminalSessionId = const Value.absent(),
          int? subtotalCents,
          int? taxCents,
          int? totalCents,
          String? status,
          DateTime? createdAt}) =>
      Sale(
        id: id ?? this.id,
        folio: folio ?? this.folio,
        warehouseId: warehouseId ?? this.warehouseId,
        cashierId: cashierId ?? this.cashierId,
        customerId: customerId.present ? customerId.value : this.customerId,
        terminalId: terminalId.present ? terminalId.value : this.terminalId,
        terminalSessionId: terminalSessionId.present
            ? terminalSessionId.value
            : this.terminalSessionId,
        subtotalCents: subtotalCents ?? this.subtotalCents,
        taxCents: taxCents ?? this.taxCents,
        totalCents: totalCents ?? this.totalCents,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      folio: data.folio.present ? data.folio.value : this.folio,
      warehouseId:
          data.warehouseId.present ? data.warehouseId.value : this.warehouseId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      terminalId:
          data.terminalId.present ? data.terminalId.value : this.terminalId,
      terminalSessionId: data.terminalSessionId.present
          ? data.terminalSessionId.value
          : this.terminalSessionId,
      subtotalCents: data.subtotalCents.present
          ? data.subtotalCents.value
          : this.subtotalCents,
      taxCents: data.taxCents.present ? data.taxCents.value : this.taxCents,
      totalCents:
          data.totalCents.present ? data.totalCents.value : this.totalCents,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('folio: $folio, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerId: $customerId, ')
          ..write('terminalId: $terminalId, ')
          ..write('terminalSessionId: $terminalSessionId, ')
          ..write('subtotalCents: $subtotalCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      folio,
      warehouseId,
      cashierId,
      customerId,
      terminalId,
      terminalSessionId,
      subtotalCents,
      taxCents,
      totalCents,
      status,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.folio == this.folio &&
          other.warehouseId == this.warehouseId &&
          other.cashierId == this.cashierId &&
          other.customerId == this.customerId &&
          other.terminalId == this.terminalId &&
          other.terminalSessionId == this.terminalSessionId &&
          other.subtotalCents == this.subtotalCents &&
          other.taxCents == this.taxCents &&
          other.totalCents == this.totalCents &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> id;
  final Value<String> folio;
  final Value<String> warehouseId;
  final Value<String> cashierId;
  final Value<String?> customerId;
  final Value<String?> terminalId;
  final Value<String?> terminalSessionId;
  final Value<int> subtotalCents;
  final Value<int> taxCents;
  final Value<int> totalCents;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.folio = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.terminalSessionId = const Value.absent(),
    this.subtotalCents = const Value.absent(),
    this.taxCents = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String id,
    required String folio,
    required String warehouseId,
    required String cashierId,
    this.customerId = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.terminalSessionId = const Value.absent(),
    required int subtotalCents,
    required int taxCents,
    required int totalCents,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        folio = Value(folio),
        warehouseId = Value(warehouseId),
        cashierId = Value(cashierId),
        subtotalCents = Value(subtotalCents),
        taxCents = Value(taxCents),
        totalCents = Value(totalCents);
  static Insertable<Sale> custom({
    Expression<String>? id,
    Expression<String>? folio,
    Expression<String>? warehouseId,
    Expression<String>? cashierId,
    Expression<String>? customerId,
    Expression<String>? terminalId,
    Expression<String>? terminalSessionId,
    Expression<int>? subtotalCents,
    Expression<int>? taxCents,
    Expression<int>? totalCents,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folio != null) 'folio': folio,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (customerId != null) 'customer_id': customerId,
      if (terminalId != null) 'terminal_id': terminalId,
      if (terminalSessionId != null) 'terminal_session_id': terminalSessionId,
      if (subtotalCents != null) 'subtotal_cents': subtotalCents,
      if (taxCents != null) 'tax_cents': taxCents,
      if (totalCents != null) 'total_cents': totalCents,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith(
      {Value<String>? id,
      Value<String>? folio,
      Value<String>? warehouseId,
      Value<String>? cashierId,
      Value<String?>? customerId,
      Value<String?>? terminalId,
      Value<String?>? terminalSessionId,
      Value<int>? subtotalCents,
      Value<int>? taxCents,
      Value<int>? totalCents,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SalesCompanion(
      id: id ?? this.id,
      folio: folio ?? this.folio,
      warehouseId: warehouseId ?? this.warehouseId,
      cashierId: cashierId ?? this.cashierId,
      customerId: customerId ?? this.customerId,
      terminalId: terminalId ?? this.terminalId,
      terminalSessionId: terminalSessionId ?? this.terminalSessionId,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      taxCents: taxCents ?? this.taxCents,
      totalCents: totalCents ?? this.totalCents,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folio.present) {
      map['folio'] = Variable<String>(folio.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (terminalId.present) {
      map['terminal_id'] = Variable<String>(terminalId.value);
    }
    if (terminalSessionId.present) {
      map['terminal_session_id'] = Variable<String>(terminalSessionId.value);
    }
    if (subtotalCents.present) {
      map['subtotal_cents'] = Variable<int>(subtotalCents.value);
    }
    if (taxCents.present) {
      map['tax_cents'] = Variable<int>(taxCents.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('folio: $folio, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerId: $customerId, ')
          ..write('terminalId: $terminalId, ')
          ..write('terminalSessionId: $terminalSessionId, ')
          ..write('subtotalCents: $subtotalCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTable extends SaleItems
    with TableInfo<$SaleItemsTable, SaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
      'sale_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sales (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
      'qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceCentsMeta =
      const VerificationMeta('unitPriceCents');
  @override
  late final GeneratedColumn<int> unitPriceCents = GeneratedColumn<int>(
      'unit_price_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitCostCentsMeta =
      const VerificationMeta('unitCostCents');
  @override
  late final GeneratedColumn<int> unitCostCents = GeneratedColumn<int>(
      'unit_cost_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxRateBpsMeta =
      const VerificationMeta('taxRateBps');
  @override
  late final GeneratedColumn<int> taxRateBps = GeneratedColumn<int>(
      'tax_rate_bps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lineSubtotalCentsMeta =
      const VerificationMeta('lineSubtotalCents');
  @override
  late final GeneratedColumn<int> lineSubtotalCents = GeneratedColumn<int>(
      'line_subtotal_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lineTaxCentsMeta =
      const VerificationMeta('lineTaxCents');
  @override
  late final GeneratedColumn<int> lineTaxCents = GeneratedColumn<int>(
      'line_tax_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lineCostCentsMeta =
      const VerificationMeta('lineCostCents');
  @override
  late final GeneratedColumn<int> lineCostCents = GeneratedColumn<int>(
      'line_cost_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lineTotalCentsMeta =
      const VerificationMeta('lineTotalCents');
  @override
  late final GeneratedColumn<int> lineTotalCents = GeneratedColumn<int>(
      'line_total_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        saleId,
        productId,
        qty,
        unitPriceCents,
        unitCostCents,
        taxRateBps,
        lineSubtotalCents,
        lineTaxCents,
        lineCostCents,
        lineTotalCents
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(Insertable<SaleItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_price_cents')) {
      context.handle(
          _unitPriceCentsMeta,
          unitPriceCents.isAcceptableOrUnknown(
              data['unit_price_cents']!, _unitPriceCentsMeta));
    } else if (isInserting) {
      context.missing(_unitPriceCentsMeta);
    }
    if (data.containsKey('unit_cost_cents')) {
      context.handle(
          _unitCostCentsMeta,
          unitCostCents.isAcceptableOrUnknown(
              data['unit_cost_cents']!, _unitCostCentsMeta));
    }
    if (data.containsKey('tax_rate_bps')) {
      context.handle(
          _taxRateBpsMeta,
          taxRateBps.isAcceptableOrUnknown(
              data['tax_rate_bps']!, _taxRateBpsMeta));
    } else if (isInserting) {
      context.missing(_taxRateBpsMeta);
    }
    if (data.containsKey('line_subtotal_cents')) {
      context.handle(
          _lineSubtotalCentsMeta,
          lineSubtotalCents.isAcceptableOrUnknown(
              data['line_subtotal_cents']!, _lineSubtotalCentsMeta));
    } else if (isInserting) {
      context.missing(_lineSubtotalCentsMeta);
    }
    if (data.containsKey('line_tax_cents')) {
      context.handle(
          _lineTaxCentsMeta,
          lineTaxCents.isAcceptableOrUnknown(
              data['line_tax_cents']!, _lineTaxCentsMeta));
    } else if (isInserting) {
      context.missing(_lineTaxCentsMeta);
    }
    if (data.containsKey('line_cost_cents')) {
      context.handle(
          _lineCostCentsMeta,
          lineCostCents.isAcceptableOrUnknown(
              data['line_cost_cents']!, _lineCostCentsMeta));
    }
    if (data.containsKey('line_total_cents')) {
      context.handle(
          _lineTotalCentsMeta,
          lineTotalCents.isAcceptableOrUnknown(
              data['line_total_cents']!, _lineTotalCentsMeta));
    } else if (isInserting) {
      context.missing(_lineTotalCentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty'])!,
      unitPriceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_price_cents'])!,
      unitCostCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_cost_cents'])!,
      taxRateBps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tax_rate_bps'])!,
      lineSubtotalCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}line_subtotal_cents'])!,
      lineTaxCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_tax_cents'])!,
      lineCostCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_cost_cents'])!,
      lineTotalCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_total_cents'])!,
    );
  }

  @override
  $SaleItemsTable createAlias(String alias) {
    return $SaleItemsTable(attachedDatabase, alias);
  }
}

class SaleItem extends DataClass implements Insertable<SaleItem> {
  final String id;
  final String saleId;
  final String productId;
  final double qty;
  final int unitPriceCents;
  final int unitCostCents;
  final int taxRateBps;
  final int lineSubtotalCents;
  final int lineTaxCents;
  final int lineCostCents;
  final int lineTotalCents;
  const SaleItem(
      {required this.id,
      required this.saleId,
      required this.productId,
      required this.qty,
      required this.unitPriceCents,
      required this.unitCostCents,
      required this.taxRateBps,
      required this.lineSubtotalCents,
      required this.lineTaxCents,
      required this.lineCostCents,
      required this.lineTotalCents});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['product_id'] = Variable<String>(productId);
    map['qty'] = Variable<double>(qty);
    map['unit_price_cents'] = Variable<int>(unitPriceCents);
    map['unit_cost_cents'] = Variable<int>(unitCostCents);
    map['tax_rate_bps'] = Variable<int>(taxRateBps);
    map['line_subtotal_cents'] = Variable<int>(lineSubtotalCents);
    map['line_tax_cents'] = Variable<int>(lineTaxCents);
    map['line_cost_cents'] = Variable<int>(lineCostCents);
    map['line_total_cents'] = Variable<int>(lineTotalCents);
    return map;
  }

  SaleItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      qty: Value(qty),
      unitPriceCents: Value(unitPriceCents),
      unitCostCents: Value(unitCostCents),
      taxRateBps: Value(taxRateBps),
      lineSubtotalCents: Value(lineSubtotalCents),
      lineTaxCents: Value(lineTaxCents),
      lineCostCents: Value(lineCostCents),
      lineTotalCents: Value(lineTotalCents),
    );
  }

  factory SaleItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItem(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String>(json['productId']),
      qty: serializer.fromJson<double>(json['qty']),
      unitPriceCents: serializer.fromJson<int>(json['unitPriceCents']),
      unitCostCents: serializer.fromJson<int>(json['unitCostCents']),
      taxRateBps: serializer.fromJson<int>(json['taxRateBps']),
      lineSubtotalCents: serializer.fromJson<int>(json['lineSubtotalCents']),
      lineTaxCents: serializer.fromJson<int>(json['lineTaxCents']),
      lineCostCents: serializer.fromJson<int>(json['lineCostCents']),
      lineTotalCents: serializer.fromJson<int>(json['lineTotalCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String>(productId),
      'qty': serializer.toJson<double>(qty),
      'unitPriceCents': serializer.toJson<int>(unitPriceCents),
      'unitCostCents': serializer.toJson<int>(unitCostCents),
      'taxRateBps': serializer.toJson<int>(taxRateBps),
      'lineSubtotalCents': serializer.toJson<int>(lineSubtotalCents),
      'lineTaxCents': serializer.toJson<int>(lineTaxCents),
      'lineCostCents': serializer.toJson<int>(lineCostCents),
      'lineTotalCents': serializer.toJson<int>(lineTotalCents),
    };
  }

  SaleItem copyWith(
          {String? id,
          String? saleId,
          String? productId,
          double? qty,
          int? unitPriceCents,
          int? unitCostCents,
          int? taxRateBps,
          int? lineSubtotalCents,
          int? lineTaxCents,
          int? lineCostCents,
          int? lineTotalCents}) =>
      SaleItem(
        id: id ?? this.id,
        saleId: saleId ?? this.saleId,
        productId: productId ?? this.productId,
        qty: qty ?? this.qty,
        unitPriceCents: unitPriceCents ?? this.unitPriceCents,
        unitCostCents: unitCostCents ?? this.unitCostCents,
        taxRateBps: taxRateBps ?? this.taxRateBps,
        lineSubtotalCents: lineSubtotalCents ?? this.lineSubtotalCents,
        lineTaxCents: lineTaxCents ?? this.lineTaxCents,
        lineCostCents: lineCostCents ?? this.lineCostCents,
        lineTotalCents: lineTotalCents ?? this.lineTotalCents,
      );
  SaleItem copyWithCompanion(SaleItemsCompanion data) {
    return SaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitPriceCents: data.unitPriceCents.present
          ? data.unitPriceCents.value
          : this.unitPriceCents,
      unitCostCents: data.unitCostCents.present
          ? data.unitCostCents.value
          : this.unitCostCents,
      taxRateBps:
          data.taxRateBps.present ? data.taxRateBps.value : this.taxRateBps,
      lineSubtotalCents: data.lineSubtotalCents.present
          ? data.lineSubtotalCents.value
          : this.lineSubtotalCents,
      lineTaxCents: data.lineTaxCents.present
          ? data.lineTaxCents.value
          : this.lineTaxCents,
      lineCostCents: data.lineCostCents.present
          ? data.lineCostCents.value
          : this.lineCostCents,
      lineTotalCents: data.lineTotalCents.present
          ? data.lineTotalCents.value
          : this.lineTotalCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('unitCostCents: $unitCostCents, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('lineSubtotalCents: $lineSubtotalCents, ')
          ..write('lineTaxCents: $lineTaxCents, ')
          ..write('lineCostCents: $lineCostCents, ')
          ..write('lineTotalCents: $lineTotalCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      saleId,
      productId,
      qty,
      unitPriceCents,
      unitCostCents,
      taxRateBps,
      lineSubtotalCents,
      lineTaxCents,
      lineCostCents,
      lineTotalCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.qty == this.qty &&
          other.unitPriceCents == this.unitPriceCents &&
          other.unitCostCents == this.unitCostCents &&
          other.taxRateBps == this.taxRateBps &&
          other.lineSubtotalCents == this.lineSubtotalCents &&
          other.lineTaxCents == this.lineTaxCents &&
          other.lineCostCents == this.lineCostCents &&
          other.lineTotalCents == this.lineTotalCents);
}

class SaleItemsCompanion extends UpdateCompanion<SaleItem> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> productId;
  final Value<double> qty;
  final Value<int> unitPriceCents;
  final Value<int> unitCostCents;
  final Value<int> taxRateBps;
  final Value<int> lineSubtotalCents;
  final Value<int> lineTaxCents;
  final Value<int> lineCostCents;
  final Value<int> lineTotalCents;
  final Value<int> rowid;
  const SaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitPriceCents = const Value.absent(),
    this.unitCostCents = const Value.absent(),
    this.taxRateBps = const Value.absent(),
    this.lineSubtotalCents = const Value.absent(),
    this.lineTaxCents = const Value.absent(),
    this.lineCostCents = const Value.absent(),
    this.lineTotalCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleItemsCompanion.insert({
    required String id,
    required String saleId,
    required String productId,
    required double qty,
    required int unitPriceCents,
    this.unitCostCents = const Value.absent(),
    required int taxRateBps,
    required int lineSubtotalCents,
    required int lineTaxCents,
    this.lineCostCents = const Value.absent(),
    required int lineTotalCents,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        saleId = Value(saleId),
        productId = Value(productId),
        qty = Value(qty),
        unitPriceCents = Value(unitPriceCents),
        taxRateBps = Value(taxRateBps),
        lineSubtotalCents = Value(lineSubtotalCents),
        lineTaxCents = Value(lineTaxCents),
        lineTotalCents = Value(lineTotalCents);
  static Insertable<SaleItem> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<double>? qty,
    Expression<int>? unitPriceCents,
    Expression<int>? unitCostCents,
    Expression<int>? taxRateBps,
    Expression<int>? lineSubtotalCents,
    Expression<int>? lineTaxCents,
    Expression<int>? lineCostCents,
    Expression<int>? lineTotalCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (unitPriceCents != null) 'unit_price_cents': unitPriceCents,
      if (unitCostCents != null) 'unit_cost_cents': unitCostCents,
      if (taxRateBps != null) 'tax_rate_bps': taxRateBps,
      if (lineSubtotalCents != null) 'line_subtotal_cents': lineSubtotalCents,
      if (lineTaxCents != null) 'line_tax_cents': lineTaxCents,
      if (lineCostCents != null) 'line_cost_cents': lineCostCents,
      if (lineTotalCents != null) 'line_total_cents': lineTotalCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? saleId,
      Value<String>? productId,
      Value<double>? qty,
      Value<int>? unitPriceCents,
      Value<int>? unitCostCents,
      Value<int>? taxRateBps,
      Value<int>? lineSubtotalCents,
      Value<int>? lineTaxCents,
      Value<int>? lineCostCents,
      Value<int>? lineTotalCents,
      Value<int>? rowid}) {
    return SaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      unitCostCents: unitCostCents ?? this.unitCostCents,
      taxRateBps: taxRateBps ?? this.taxRateBps,
      lineSubtotalCents: lineSubtotalCents ?? this.lineSubtotalCents,
      lineTaxCents: lineTaxCents ?? this.lineTaxCents,
      lineCostCents: lineCostCents ?? this.lineCostCents,
      lineTotalCents: lineTotalCents ?? this.lineTotalCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unitPriceCents.present) {
      map['unit_price_cents'] = Variable<int>(unitPriceCents.value);
    }
    if (unitCostCents.present) {
      map['unit_cost_cents'] = Variable<int>(unitCostCents.value);
    }
    if (taxRateBps.present) {
      map['tax_rate_bps'] = Variable<int>(taxRateBps.value);
    }
    if (lineSubtotalCents.present) {
      map['line_subtotal_cents'] = Variable<int>(lineSubtotalCents.value);
    }
    if (lineTaxCents.present) {
      map['line_tax_cents'] = Variable<int>(lineTaxCents.value);
    }
    if (lineCostCents.present) {
      map['line_cost_cents'] = Variable<int>(lineCostCents.value);
    }
    if (lineTotalCents.present) {
      map['line_total_cents'] = Variable<int>(lineTotalCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('unitCostCents: $unitCostCents, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('lineSubtotalCents: $lineSubtotalCents, ')
          ..write('lineTaxCents: $lineTaxCents, ')
          ..write('lineCostCents: $lineCostCents, ')
          ..write('lineTotalCents: $lineTotalCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
      'sale_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sales (id)'));
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceCurrencyCodeMeta =
      const VerificationMeta('sourceCurrencyCode');
  @override
  late final GeneratedColumn<String> sourceCurrencyCode =
      GeneratedColumn<String>('source_currency_code', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceAmountCentsMeta =
      const VerificationMeta('sourceAmountCents');
  @override
  late final GeneratedColumn<int> sourceAmountCents = GeneratedColumn<int>(
      'source_amount_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        saleId,
        method,
        amountCents,
        transactionId,
        sourceCurrencyCode,
        sourceAmountCents,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(Insertable<Payment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    if (data.containsKey('source_currency_code')) {
      context.handle(
          _sourceCurrencyCodeMeta,
          sourceCurrencyCode.isAcceptableOrUnknown(
              data['source_currency_code']!, _sourceCurrencyCodeMeta));
    }
    if (data.containsKey('source_amount_cents')) {
      context.handle(
          _sourceAmountCentsMeta,
          sourceAmountCents.isAcceptableOrUnknown(
              data['source_amount_cents']!, _sourceAmountCentsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_id'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id']),
      sourceCurrencyCode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_currency_code']),
      sourceAmountCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}source_amount_cents']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final String id;
  final String saleId;
  final String method;
  final int amountCents;
  final String? transactionId;
  final String? sourceCurrencyCode;
  final int? sourceAmountCents;
  final DateTime createdAt;
  const Payment(
      {required this.id,
      required this.saleId,
      required this.method,
      required this.amountCents,
      this.transactionId,
      this.sourceCurrencyCode,
      this.sourceAmountCents,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['method'] = Variable<String>(method);
    map['amount_cents'] = Variable<int>(amountCents);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || sourceCurrencyCode != null) {
      map['source_currency_code'] = Variable<String>(sourceCurrencyCode);
    }
    if (!nullToAbsent || sourceAmountCents != null) {
      map['source_amount_cents'] = Variable<int>(sourceAmountCents);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      method: Value(method),
      amountCents: Value(amountCents),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      sourceCurrencyCode: sourceCurrencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCurrencyCode),
      sourceAmountCents: sourceAmountCents == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAmountCents),
      createdAt: Value(createdAt),
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      method: serializer.fromJson<String>(json['method']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      sourceCurrencyCode:
          serializer.fromJson<String?>(json['sourceCurrencyCode']),
      sourceAmountCents: serializer.fromJson<int?>(json['sourceAmountCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'method': serializer.toJson<String>(method),
      'amountCents': serializer.toJson<int>(amountCents),
      'transactionId': serializer.toJson<String?>(transactionId),
      'sourceCurrencyCode': serializer.toJson<String?>(sourceCurrencyCode),
      'sourceAmountCents': serializer.toJson<int?>(sourceAmountCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Payment copyWith(
          {String? id,
          String? saleId,
          String? method,
          int? amountCents,
          Value<String?> transactionId = const Value.absent(),
          Value<String?> sourceCurrencyCode = const Value.absent(),
          Value<int?> sourceAmountCents = const Value.absent(),
          DateTime? createdAt}) =>
      Payment(
        id: id ?? this.id,
        saleId: saleId ?? this.saleId,
        method: method ?? this.method,
        amountCents: amountCents ?? this.amountCents,
        transactionId:
            transactionId.present ? transactionId.value : this.transactionId,
        sourceCurrencyCode: sourceCurrencyCode.present
            ? sourceCurrencyCode.value
            : this.sourceCurrencyCode,
        sourceAmountCents: sourceAmountCents.present
            ? sourceAmountCents.value
            : this.sourceAmountCents,
        createdAt: createdAt ?? this.createdAt,
      );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      method: data.method.present ? data.method.value : this.method,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      sourceCurrencyCode: data.sourceCurrencyCode.present
          ? data.sourceCurrencyCode.value
          : this.sourceCurrencyCode,
      sourceAmountCents: data.sourceAmountCents.present
          ? data.sourceAmountCents.value
          : this.sourceAmountCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountCents: $amountCents, ')
          ..write('transactionId: $transactionId, ')
          ..write('sourceCurrencyCode: $sourceCurrencyCode, ')
          ..write('sourceAmountCents: $sourceAmountCents, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, saleId, method, amountCents,
      transactionId, sourceCurrencyCode, sourceAmountCents, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.method == this.method &&
          other.amountCents == this.amountCents &&
          other.transactionId == this.transactionId &&
          other.sourceCurrencyCode == this.sourceCurrencyCode &&
          other.sourceAmountCents == this.sourceAmountCents &&
          other.createdAt == this.createdAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> method;
  final Value<int> amountCents;
  final Value<String?> transactionId;
  final Value<String?> sourceCurrencyCode;
  final Value<int?> sourceAmountCents;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.method = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.sourceCurrencyCode = const Value.absent(),
    this.sourceAmountCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String saleId,
    required String method,
    required int amountCents,
    this.transactionId = const Value.absent(),
    this.sourceCurrencyCode = const Value.absent(),
    this.sourceAmountCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        saleId = Value(saleId),
        method = Value(method),
        amountCents = Value(amountCents);
  static Insertable<Payment> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? method,
    Expression<int>? amountCents,
    Expression<String>? transactionId,
    Expression<String>? sourceCurrencyCode,
    Expression<int>? sourceAmountCents,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (method != null) 'method': method,
      if (amountCents != null) 'amount_cents': amountCents,
      if (transactionId != null) 'transaction_id': transactionId,
      if (sourceCurrencyCode != null)
        'source_currency_code': sourceCurrencyCode,
      if (sourceAmountCents != null) 'source_amount_cents': sourceAmountCents,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? saleId,
      Value<String>? method,
      Value<int>? amountCents,
      Value<String?>? transactionId,
      Value<String?>? sourceCurrencyCode,
      Value<int?>? sourceAmountCents,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PaymentsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amountCents: amountCents ?? this.amountCents,
      transactionId: transactionId ?? this.transactionId,
      sourceCurrencyCode: sourceCurrencyCode ?? this.sourceCurrencyCode,
      sourceAmountCents: sourceAmountCents ?? this.sourceAmountCents,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (sourceCurrencyCode.present) {
      map['source_currency_code'] = Variable<String>(sourceCurrencyCode.value);
    }
    if (sourceAmountCents.present) {
      map['source_amount_cents'] = Variable<int>(sourceAmountCents.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountCents: $amountCents, ')
          ..write('transactionId: $transactionId, ')
          ..write('sourceCurrencyCode: $sourceCurrencyCode, ')
          ..write('sourceAmountCents: $sourceAmountCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IpvReportsTable extends IpvReports
    with TableInfo<$IpvReportsTable, IpvReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IpvReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _terminalIdMeta =
      const VerificationMeta('terminalId');
  @override
  late final GeneratedColumn<String> terminalId = GeneratedColumn<String>(
      'terminal_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pos_terminals (id)'));
  static const VerificationMeta _warehouseIdMeta =
      const VerificationMeta('warehouseId');
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
      'warehouse_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES warehouses (id)'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'UNIQUE REFERENCES pos_sessions (id)'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _openedByMeta =
      const VerificationMeta('openedBy');
  @override
  late final GeneratedColumn<String> openedBy = GeneratedColumn<String>(
      'opened_by', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _closedByMeta =
      const VerificationMeta('closedBy');
  @override
  late final GeneratedColumn<String> closedBy = GeneratedColumn<String>(
      'closed_by', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _openingSourceMeta =
      const VerificationMeta('openingSource');
  @override
  late final GeneratedColumn<String> openingSource = GeneratedColumn<String>(
      'opening_source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('initial_stock'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        terminalId,
        warehouseId,
        sessionId,
        status,
        openedAt,
        closedAt,
        openedBy,
        closedBy,
        openingSource,
        note
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ipv_reports';
  @override
  VerificationContext validateIntegrity(Insertable<IpvReport> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('terminal_id')) {
      context.handle(
          _terminalIdMeta,
          terminalId.isAcceptableOrUnknown(
              data['terminal_id']!, _terminalIdMeta));
    } else if (isInserting) {
      context.missing(_terminalIdMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
          _warehouseIdMeta,
          warehouseId.isAcceptableOrUnknown(
              data['warehouse_id']!, _warehouseIdMeta));
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    if (data.containsKey('opened_by')) {
      context.handle(_openedByMeta,
          openedBy.isAcceptableOrUnknown(data['opened_by']!, _openedByMeta));
    } else if (isInserting) {
      context.missing(_openedByMeta);
    }
    if (data.containsKey('closed_by')) {
      context.handle(_closedByMeta,
          closedBy.isAcceptableOrUnknown(data['closed_by']!, _closedByMeta));
    }
    if (data.containsKey('opening_source')) {
      context.handle(
          _openingSourceMeta,
          openingSource.isAcceptableOrUnknown(
              data['opening_source']!, _openingSourceMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IpvReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IpvReport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      terminalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terminal_id'])!,
      warehouseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}warehouse_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at']),
      openedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opened_by'])!,
      closedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}closed_by']),
      openingSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opening_source'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $IpvReportsTable createAlias(String alias) {
    return $IpvReportsTable(attachedDatabase, alias);
  }
}

class IpvReport extends DataClass implements Insertable<IpvReport> {
  final String id;
  final String terminalId;
  final String warehouseId;
  final String sessionId;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String openedBy;
  final String? closedBy;
  final String openingSource;
  final String? note;
  const IpvReport(
      {required this.id,
      required this.terminalId,
      required this.warehouseId,
      required this.sessionId,
      required this.status,
      required this.openedAt,
      this.closedAt,
      required this.openedBy,
      this.closedBy,
      required this.openingSource,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['terminal_id'] = Variable<String>(terminalId);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['session_id'] = Variable<String>(sessionId);
    map['status'] = Variable<String>(status);
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['opened_by'] = Variable<String>(openedBy);
    if (!nullToAbsent || closedBy != null) {
      map['closed_by'] = Variable<String>(closedBy);
    }
    map['opening_source'] = Variable<String>(openingSource);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  IpvReportsCompanion toCompanion(bool nullToAbsent) {
    return IpvReportsCompanion(
      id: Value(id),
      terminalId: Value(terminalId),
      warehouseId: Value(warehouseId),
      sessionId: Value(sessionId),
      status: Value(status),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      openedBy: Value(openedBy),
      closedBy: closedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(closedBy),
      openingSource: Value(openingSource),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory IpvReport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IpvReport(
      id: serializer.fromJson<String>(json['id']),
      terminalId: serializer.fromJson<String>(json['terminalId']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      status: serializer.fromJson<String>(json['status']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      openedBy: serializer.fromJson<String>(json['openedBy']),
      closedBy: serializer.fromJson<String?>(json['closedBy']),
      openingSource: serializer.fromJson<String>(json['openingSource']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'terminalId': serializer.toJson<String>(terminalId),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'sessionId': serializer.toJson<String>(sessionId),
      'status': serializer.toJson<String>(status),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'openedBy': serializer.toJson<String>(openedBy),
      'closedBy': serializer.toJson<String?>(closedBy),
      'openingSource': serializer.toJson<String>(openingSource),
      'note': serializer.toJson<String?>(note),
    };
  }

  IpvReport copyWith(
          {String? id,
          String? terminalId,
          String? warehouseId,
          String? sessionId,
          String? status,
          DateTime? openedAt,
          Value<DateTime?> closedAt = const Value.absent(),
          String? openedBy,
          Value<String?> closedBy = const Value.absent(),
          String? openingSource,
          Value<String?> note = const Value.absent()}) =>
      IpvReport(
        id: id ?? this.id,
        terminalId: terminalId ?? this.terminalId,
        warehouseId: warehouseId ?? this.warehouseId,
        sessionId: sessionId ?? this.sessionId,
        status: status ?? this.status,
        openedAt: openedAt ?? this.openedAt,
        closedAt: closedAt.present ? closedAt.value : this.closedAt,
        openedBy: openedBy ?? this.openedBy,
        closedBy: closedBy.present ? closedBy.value : this.closedBy,
        openingSource: openingSource ?? this.openingSource,
        note: note.present ? note.value : this.note,
      );
  IpvReport copyWithCompanion(IpvReportsCompanion data) {
    return IpvReport(
      id: data.id.present ? data.id.value : this.id,
      terminalId:
          data.terminalId.present ? data.terminalId.value : this.terminalId,
      warehouseId:
          data.warehouseId.present ? data.warehouseId.value : this.warehouseId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      status: data.status.present ? data.status.value : this.status,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      openedBy: data.openedBy.present ? data.openedBy.value : this.openedBy,
      closedBy: data.closedBy.present ? data.closedBy.value : this.closedBy,
      openingSource: data.openingSource.present
          ? data.openingSource.value
          : this.openingSource,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IpvReport(')
          ..write('id: $id, ')
          ..write('terminalId: $terminalId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openedBy: $openedBy, ')
          ..write('closedBy: $closedBy, ')
          ..write('openingSource: $openingSource, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, terminalId, warehouseId, sessionId,
      status, openedAt, closedAt, openedBy, closedBy, openingSource, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IpvReport &&
          other.id == this.id &&
          other.terminalId == this.terminalId &&
          other.warehouseId == this.warehouseId &&
          other.sessionId == this.sessionId &&
          other.status == this.status &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.openedBy == this.openedBy &&
          other.closedBy == this.closedBy &&
          other.openingSource == this.openingSource &&
          other.note == this.note);
}

class IpvReportsCompanion extends UpdateCompanion<IpvReport> {
  final Value<String> id;
  final Value<String> terminalId;
  final Value<String> warehouseId;
  final Value<String> sessionId;
  final Value<String> status;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<String> openedBy;
  final Value<String?> closedBy;
  final Value<String> openingSource;
  final Value<String?> note;
  final Value<int> rowid;
  const IpvReportsCompanion({
    this.id = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.status = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.openedBy = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.openingSource = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IpvReportsCompanion.insert({
    required String id,
    required String terminalId,
    required String warehouseId,
    required String sessionId,
    this.status = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    required String openedBy,
    this.closedBy = const Value.absent(),
    this.openingSource = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        terminalId = Value(terminalId),
        warehouseId = Value(warehouseId),
        sessionId = Value(sessionId),
        openedBy = Value(openedBy);
  static Insertable<IpvReport> custom({
    Expression<String>? id,
    Expression<String>? terminalId,
    Expression<String>? warehouseId,
    Expression<String>? sessionId,
    Expression<String>? status,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<String>? openedBy,
    Expression<String>? closedBy,
    Expression<String>? openingSource,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (terminalId != null) 'terminal_id': terminalId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (sessionId != null) 'session_id': sessionId,
      if (status != null) 'status': status,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (openedBy != null) 'opened_by': openedBy,
      if (closedBy != null) 'closed_by': closedBy,
      if (openingSource != null) 'opening_source': openingSource,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IpvReportsCompanion copyWith(
      {Value<String>? id,
      Value<String>? terminalId,
      Value<String>? warehouseId,
      Value<String>? sessionId,
      Value<String>? status,
      Value<DateTime>? openedAt,
      Value<DateTime?>? closedAt,
      Value<String>? openedBy,
      Value<String?>? closedBy,
      Value<String>? openingSource,
      Value<String?>? note,
      Value<int>? rowid}) {
    return IpvReportsCompanion(
      id: id ?? this.id,
      terminalId: terminalId ?? this.terminalId,
      warehouseId: warehouseId ?? this.warehouseId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openedBy: openedBy ?? this.openedBy,
      closedBy: closedBy ?? this.closedBy,
      openingSource: openingSource ?? this.openingSource,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (terminalId.present) {
      map['terminal_id'] = Variable<String>(terminalId.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (openedBy.present) {
      map['opened_by'] = Variable<String>(openedBy.value);
    }
    if (closedBy.present) {
      map['closed_by'] = Variable<String>(closedBy.value);
    }
    if (openingSource.present) {
      map['opening_source'] = Variable<String>(openingSource.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IpvReportsCompanion(')
          ..write('id: $id, ')
          ..write('terminalId: $terminalId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openedBy: $openedBy, ')
          ..write('closedBy: $closedBy, ')
          ..write('openingSource: $openingSource, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IpvReportLinesTable extends IpvReportLines
    with TableInfo<$IpvReportLinesTable, IpvReportLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IpvReportLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reportIdMeta =
      const VerificationMeta('reportId');
  @override
  late final GeneratedColumn<String> reportId = GeneratedColumn<String>(
      'report_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ipv_reports (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>('product_name_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productSkuSnapshotMeta =
      const VerificationMeta('productSkuSnapshot');
  @override
  late final GeneratedColumn<String> productSkuSnapshot =
      GeneratedColumn<String>('product_sku_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startQtyMeta =
      const VerificationMeta('startQty');
  @override
  late final GeneratedColumn<double> startQty = GeneratedColumn<double>(
      'start_qty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _entriesQtyMeta =
      const VerificationMeta('entriesQty');
  @override
  late final GeneratedColumn<double> entriesQty = GeneratedColumn<double>(
      'entries_qty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _outputsQtyMeta =
      const VerificationMeta('outputsQty');
  @override
  late final GeneratedColumn<double> outputsQty = GeneratedColumn<double>(
      'outputs_qty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _salesQtyMeta =
      const VerificationMeta('salesQty');
  @override
  late final GeneratedColumn<double> salesQty = GeneratedColumn<double>(
      'sales_qty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _finalQtyMeta =
      const VerificationMeta('finalQty');
  @override
  late final GeneratedColumn<double> finalQty = GeneratedColumn<double>(
      'final_qty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _salePriceCentsMeta =
      const VerificationMeta('salePriceCents');
  @override
  late final GeneratedColumn<int> salePriceCents = GeneratedColumn<int>(
      'sale_price_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalAmountCentsMeta =
      const VerificationMeta('totalAmountCents');
  @override
  late final GeneratedColumn<int> totalAmountCents = GeneratedColumn<int>(
      'total_amount_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        reportId,
        productId,
        productNameSnapshot,
        productSkuSnapshot,
        startQty,
        entriesQty,
        outputsQty,
        salesQty,
        finalQty,
        salePriceCents,
        totalAmountCents
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ipv_report_lines';
  @override
  VerificationContext validateIntegrity(Insertable<IpvReportLine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('report_id')) {
      context.handle(_reportIdMeta,
          reportId.isAcceptableOrUnknown(data['report_id']!, _reportIdMeta));
    } else if (isInserting) {
      context.missing(_reportIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
          _productNameSnapshotMeta,
          productNameSnapshot.isAcceptableOrUnknown(
              data['product_name_snapshot']!, _productNameSnapshotMeta));
    }
    if (data.containsKey('product_sku_snapshot')) {
      context.handle(
          _productSkuSnapshotMeta,
          productSkuSnapshot.isAcceptableOrUnknown(
              data['product_sku_snapshot']!, _productSkuSnapshotMeta));
    }
    if (data.containsKey('start_qty')) {
      context.handle(_startQtyMeta,
          startQty.isAcceptableOrUnknown(data['start_qty']!, _startQtyMeta));
    }
    if (data.containsKey('entries_qty')) {
      context.handle(
          _entriesQtyMeta,
          entriesQty.isAcceptableOrUnknown(
              data['entries_qty']!, _entriesQtyMeta));
    }
    if (data.containsKey('outputs_qty')) {
      context.handle(
          _outputsQtyMeta,
          outputsQty.isAcceptableOrUnknown(
              data['outputs_qty']!, _outputsQtyMeta));
    }
    if (data.containsKey('sales_qty')) {
      context.handle(_salesQtyMeta,
          salesQty.isAcceptableOrUnknown(data['sales_qty']!, _salesQtyMeta));
    }
    if (data.containsKey('final_qty')) {
      context.handle(_finalQtyMeta,
          finalQty.isAcceptableOrUnknown(data['final_qty']!, _finalQtyMeta));
    }
    if (data.containsKey('sale_price_cents')) {
      context.handle(
          _salePriceCentsMeta,
          salePriceCents.isAcceptableOrUnknown(
              data['sale_price_cents']!, _salePriceCentsMeta));
    }
    if (data.containsKey('total_amount_cents')) {
      context.handle(
          _totalAmountCentsMeta,
          totalAmountCents.isAcceptableOrUnknown(
              data['total_amount_cents']!, _totalAmountCentsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reportId, productId};
  @override
  IpvReportLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IpvReportLine(
      reportId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}report_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      productNameSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}product_name_snapshot']),
      productSkuSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}product_sku_snapshot']),
      startQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_qty'])!,
      entriesQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}entries_qty'])!,
      outputsQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}outputs_qty'])!,
      salesQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sales_qty'])!,
      finalQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}final_qty'])!,
      salePriceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sale_price_cents'])!,
      totalAmountCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_amount_cents'])!,
    );
  }

  @override
  $IpvReportLinesTable createAlias(String alias) {
    return $IpvReportLinesTable(attachedDatabase, alias);
  }
}

class IpvReportLine extends DataClass implements Insertable<IpvReportLine> {
  final String reportId;
  final String productId;
  final String? productNameSnapshot;
  final String? productSkuSnapshot;
  final double startQty;
  final double entriesQty;
  final double outputsQty;
  final double salesQty;
  final double finalQty;
  final int salePriceCents;
  final int totalAmountCents;
  const IpvReportLine(
      {required this.reportId,
      required this.productId,
      this.productNameSnapshot,
      this.productSkuSnapshot,
      required this.startQty,
      required this.entriesQty,
      required this.outputsQty,
      required this.salesQty,
      required this.finalQty,
      required this.salePriceCents,
      required this.totalAmountCents});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['report_id'] = Variable<String>(reportId);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || productNameSnapshot != null) {
      map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    }
    if (!nullToAbsent || productSkuSnapshot != null) {
      map['product_sku_snapshot'] = Variable<String>(productSkuSnapshot);
    }
    map['start_qty'] = Variable<double>(startQty);
    map['entries_qty'] = Variable<double>(entriesQty);
    map['outputs_qty'] = Variable<double>(outputsQty);
    map['sales_qty'] = Variable<double>(salesQty);
    map['final_qty'] = Variable<double>(finalQty);
    map['sale_price_cents'] = Variable<int>(salePriceCents);
    map['total_amount_cents'] = Variable<int>(totalAmountCents);
    return map;
  }

  IpvReportLinesCompanion toCompanion(bool nullToAbsent) {
    return IpvReportLinesCompanion(
      reportId: Value(reportId),
      productId: Value(productId),
      productNameSnapshot: productNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(productNameSnapshot),
      productSkuSnapshot: productSkuSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(productSkuSnapshot),
      startQty: Value(startQty),
      entriesQty: Value(entriesQty),
      outputsQty: Value(outputsQty),
      salesQty: Value(salesQty),
      finalQty: Value(finalQty),
      salePriceCents: Value(salePriceCents),
      totalAmountCents: Value(totalAmountCents),
    );
  }

  factory IpvReportLine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IpvReportLine(
      reportId: serializer.fromJson<String>(json['reportId']),
      productId: serializer.fromJson<String>(json['productId']),
      productNameSnapshot:
          serializer.fromJson<String?>(json['productNameSnapshot']),
      productSkuSnapshot:
          serializer.fromJson<String?>(json['productSkuSnapshot']),
      startQty: serializer.fromJson<double>(json['startQty']),
      entriesQty: serializer.fromJson<double>(json['entriesQty']),
      outputsQty: serializer.fromJson<double>(json['outputsQty']),
      salesQty: serializer.fromJson<double>(json['salesQty']),
      finalQty: serializer.fromJson<double>(json['finalQty']),
      salePriceCents: serializer.fromJson<int>(json['salePriceCents']),
      totalAmountCents: serializer.fromJson<int>(json['totalAmountCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reportId': serializer.toJson<String>(reportId),
      'productId': serializer.toJson<String>(productId),
      'productNameSnapshot': serializer.toJson<String?>(productNameSnapshot),
      'productSkuSnapshot': serializer.toJson<String?>(productSkuSnapshot),
      'startQty': serializer.toJson<double>(startQty),
      'entriesQty': serializer.toJson<double>(entriesQty),
      'outputsQty': serializer.toJson<double>(outputsQty),
      'salesQty': serializer.toJson<double>(salesQty),
      'finalQty': serializer.toJson<double>(finalQty),
      'salePriceCents': serializer.toJson<int>(salePriceCents),
      'totalAmountCents': serializer.toJson<int>(totalAmountCents),
    };
  }

  IpvReportLine copyWith(
          {String? reportId,
          String? productId,
          Value<String?> productNameSnapshot = const Value.absent(),
          Value<String?> productSkuSnapshot = const Value.absent(),
          double? startQty,
          double? entriesQty,
          double? outputsQty,
          double? salesQty,
          double? finalQty,
          int? salePriceCents,
          int? totalAmountCents}) =>
      IpvReportLine(
        reportId: reportId ?? this.reportId,
        productId: productId ?? this.productId,
        productNameSnapshot: productNameSnapshot.present
            ? productNameSnapshot.value
            : this.productNameSnapshot,
        productSkuSnapshot: productSkuSnapshot.present
            ? productSkuSnapshot.value
            : this.productSkuSnapshot,
        startQty: startQty ?? this.startQty,
        entriesQty: entriesQty ?? this.entriesQty,
        outputsQty: outputsQty ?? this.outputsQty,
        salesQty: salesQty ?? this.salesQty,
        finalQty: finalQty ?? this.finalQty,
        salePriceCents: salePriceCents ?? this.salePriceCents,
        totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      );
  IpvReportLine copyWithCompanion(IpvReportLinesCompanion data) {
    return IpvReportLine(
      reportId: data.reportId.present ? data.reportId.value : this.reportId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      productSkuSnapshot: data.productSkuSnapshot.present
          ? data.productSkuSnapshot.value
          : this.productSkuSnapshot,
      startQty: data.startQty.present ? data.startQty.value : this.startQty,
      entriesQty:
          data.entriesQty.present ? data.entriesQty.value : this.entriesQty,
      outputsQty:
          data.outputsQty.present ? data.outputsQty.value : this.outputsQty,
      salesQty: data.salesQty.present ? data.salesQty.value : this.salesQty,
      finalQty: data.finalQty.present ? data.finalQty.value : this.finalQty,
      salePriceCents: data.salePriceCents.present
          ? data.salePriceCents.value
          : this.salePriceCents,
      totalAmountCents: data.totalAmountCents.present
          ? data.totalAmountCents.value
          : this.totalAmountCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IpvReportLine(')
          ..write('reportId: $reportId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('productSkuSnapshot: $productSkuSnapshot, ')
          ..write('startQty: $startQty, ')
          ..write('entriesQty: $entriesQty, ')
          ..write('outputsQty: $outputsQty, ')
          ..write('salesQty: $salesQty, ')
          ..write('finalQty: $finalQty, ')
          ..write('salePriceCents: $salePriceCents, ')
          ..write('totalAmountCents: $totalAmountCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      reportId,
      productId,
      productNameSnapshot,
      productSkuSnapshot,
      startQty,
      entriesQty,
      outputsQty,
      salesQty,
      finalQty,
      salePriceCents,
      totalAmountCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IpvReportLine &&
          other.reportId == this.reportId &&
          other.productId == this.productId &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.productSkuSnapshot == this.productSkuSnapshot &&
          other.startQty == this.startQty &&
          other.entriesQty == this.entriesQty &&
          other.outputsQty == this.outputsQty &&
          other.salesQty == this.salesQty &&
          other.finalQty == this.finalQty &&
          other.salePriceCents == this.salePriceCents &&
          other.totalAmountCents == this.totalAmountCents);
}

class IpvReportLinesCompanion extends UpdateCompanion<IpvReportLine> {
  final Value<String> reportId;
  final Value<String> productId;
  final Value<String?> productNameSnapshot;
  final Value<String?> productSkuSnapshot;
  final Value<double> startQty;
  final Value<double> entriesQty;
  final Value<double> outputsQty;
  final Value<double> salesQty;
  final Value<double> finalQty;
  final Value<int> salePriceCents;
  final Value<int> totalAmountCents;
  final Value<int> rowid;
  const IpvReportLinesCompanion({
    this.reportId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.productSkuSnapshot = const Value.absent(),
    this.startQty = const Value.absent(),
    this.entriesQty = const Value.absent(),
    this.outputsQty = const Value.absent(),
    this.salesQty = const Value.absent(),
    this.finalQty = const Value.absent(),
    this.salePriceCents = const Value.absent(),
    this.totalAmountCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IpvReportLinesCompanion.insert({
    required String reportId,
    required String productId,
    this.productNameSnapshot = const Value.absent(),
    this.productSkuSnapshot = const Value.absent(),
    this.startQty = const Value.absent(),
    this.entriesQty = const Value.absent(),
    this.outputsQty = const Value.absent(),
    this.salesQty = const Value.absent(),
    this.finalQty = const Value.absent(),
    this.salePriceCents = const Value.absent(),
    this.totalAmountCents = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : reportId = Value(reportId),
        productId = Value(productId);
  static Insertable<IpvReportLine> custom({
    Expression<String>? reportId,
    Expression<String>? productId,
    Expression<String>? productNameSnapshot,
    Expression<String>? productSkuSnapshot,
    Expression<double>? startQty,
    Expression<double>? entriesQty,
    Expression<double>? outputsQty,
    Expression<double>? salesQty,
    Expression<double>? finalQty,
    Expression<int>? salePriceCents,
    Expression<int>? totalAmountCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reportId != null) 'report_id': reportId,
      if (productId != null) 'product_id': productId,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (productSkuSnapshot != null)
        'product_sku_snapshot': productSkuSnapshot,
      if (startQty != null) 'start_qty': startQty,
      if (entriesQty != null) 'entries_qty': entriesQty,
      if (outputsQty != null) 'outputs_qty': outputsQty,
      if (salesQty != null) 'sales_qty': salesQty,
      if (finalQty != null) 'final_qty': finalQty,
      if (salePriceCents != null) 'sale_price_cents': salePriceCents,
      if (totalAmountCents != null) 'total_amount_cents': totalAmountCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IpvReportLinesCompanion copyWith(
      {Value<String>? reportId,
      Value<String>? productId,
      Value<String?>? productNameSnapshot,
      Value<String?>? productSkuSnapshot,
      Value<double>? startQty,
      Value<double>? entriesQty,
      Value<double>? outputsQty,
      Value<double>? salesQty,
      Value<double>? finalQty,
      Value<int>? salePriceCents,
      Value<int>? totalAmountCents,
      Value<int>? rowid}) {
    return IpvReportLinesCompanion(
      reportId: reportId ?? this.reportId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      productSkuSnapshot: productSkuSnapshot ?? this.productSkuSnapshot,
      startQty: startQty ?? this.startQty,
      entriesQty: entriesQty ?? this.entriesQty,
      outputsQty: outputsQty ?? this.outputsQty,
      salesQty: salesQty ?? this.salesQty,
      finalQty: finalQty ?? this.finalQty,
      salePriceCents: salePriceCents ?? this.salePriceCents,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reportId.present) {
      map['report_id'] = Variable<String>(reportId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] =
          Variable<String>(productNameSnapshot.value);
    }
    if (productSkuSnapshot.present) {
      map['product_sku_snapshot'] = Variable<String>(productSkuSnapshot.value);
    }
    if (startQty.present) {
      map['start_qty'] = Variable<double>(startQty.value);
    }
    if (entriesQty.present) {
      map['entries_qty'] = Variable<double>(entriesQty.value);
    }
    if (outputsQty.present) {
      map['outputs_qty'] = Variable<double>(outputsQty.value);
    }
    if (salesQty.present) {
      map['sales_qty'] = Variable<double>(salesQty.value);
    }
    if (finalQty.present) {
      map['final_qty'] = Variable<double>(finalQty.value);
    }
    if (salePriceCents.present) {
      map['sale_price_cents'] = Variable<int>(salePriceCents.value);
    }
    if (totalAmountCents.present) {
      map['total_amount_cents'] = Variable<int>(totalAmountCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IpvReportLinesCompanion(')
          ..write('reportId: $reportId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('productSkuSnapshot: $productSkuSnapshot, ')
          ..write('startQty: $startQty, ')
          ..write('entriesQty: $entriesQty, ')
          ..write('outputsQty: $outputsQty, ')
          ..write('salesQty: $salesQty, ')
          ..write('finalQty: $finalQty, ')
          ..write('salePriceCents: $salePriceCents, ')
          ..write('totalAmountCents: $totalAmountCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, action, entity, entityId, payloadJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  final String id;
  final String? userId;
  final String action;
  final String entity;
  final String entityId;
  final String payloadJson;
  final DateTime createdAt;
  const AuditLog(
      {required this.id,
      this.userId,
      required this.action,
      required this.entity,
      required this.entityId,
      required this.payloadJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['action'] = Variable<String>(action);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      action: Value(action),
      entity: Value(entity),
      entityId: Value(entityId),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      action: serializer.fromJson<String>(json['action']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'action': serializer.toJson<String>(action),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLog copyWith(
          {String? id,
          Value<String?> userId = const Value.absent(),
          String? action,
          String? entity,
          String? entityId,
          String? payloadJson,
          DateTime? createdAt}) =>
      AuditLog(
        id: id ?? this.id,
        userId: userId.present ? userId.value : this.userId,
        action: action ?? this.action,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
        payloadJson: payloadJson ?? this.payloadJson,
        createdAt: createdAt ?? this.createdAt,
      );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      action: data.action.present ? data.action.value : this.action,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, action, entity, entityId, payloadJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.action == this.action &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> action;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.action = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String action,
    required String entity,
    required String entityId,
    required String payloadJson,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        action = Value(action),
        entity = Value(entity),
        entityId = Value(entityId),
        payloadJson = Value(payloadJson);
  static Insertable<AuditLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? action,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (action != null) 'action': action,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? userId,
      Value<String>? action,
      Value<String>? entity,
      Value<String>? entityId,
      Value<String>? payloadJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $RolesTable roles = $RolesTable(this);
  late final $PermissionsTable permissions = $PermissionsTable(this);
  late final $RolePermissionsTable rolePermissions =
      $RolePermissionsTable(this);
  late final $UserRolesTable userRoles = $UserRolesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductCatalogItemsTable productCatalogItems =
      $ProductCatalogItemsTable(this);
  late final $WarehousesTable warehouses = $WarehousesTable(this);
  late final $PosTerminalsTable posTerminals = $PosTerminalsTable(this);
  late final $PosSessionsTable posSessions = $PosSessionsTable(this);
  late final $PosSessionCashBreakdownsTable posSessionCashBreakdowns =
      $PosSessionCashBreakdownsTable(this);
  late final $EmployeesTable employees = $EmployeesTable(this);
  late final $PosSessionEmployeesTable posSessionEmployees =
      $PosSessionEmployeesTable(this);
  late final $PosTerminalEmployeesTable posTerminalEmployees =
      $PosTerminalEmployeesTable(this);
  late final $StockBalancesTable stockBalances = $StockBalancesTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SaleItemsTable saleItems = $SaleItemsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $IpvReportsTable ipvReports = $IpvReportsTable(this);
  late final $IpvReportLinesTable ipvReportLines = $IpvReportLinesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        roles,
        permissions,
        rolePermissions,
        userRoles,
        products,
        productCatalogItems,
        warehouses,
        posTerminals,
        posSessions,
        posSessionCashBreakdowns,
        employees,
        posSessionEmployees,
        posTerminalEmployees,
        stockBalances,
        stockMovements,
        customers,
        sales,
        saleItems,
        payments,
        ipvReports,
        ipvReportLines,
        appSettings,
        auditLogs
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String username,
  required String passwordHash,
  required String salt,
  Value<String> role,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> username,
  Value<String> passwordHash,
  Value<String> salt,
  Value<String> role,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserRolesTable, List<UserRole>>
      _userRolesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.userRoles,
          aliasName: $_aliasNameGenerator(db.users.id, db.userRoles.userId));

  $$UserRolesTableProcessedTableManager get userRolesRefs {
    final manager = $$UserRolesTableTableManager($_db, $_db.userRoles)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userRolesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PosSessionsTable, List<PosSession>>
      _posSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.posSessions,
          aliasName: $_aliasNameGenerator(db.users.id, db.posSessions.userId));

  $$PosSessionsTableProcessedTableManager get posSessionsRefs {
    final manager = $$PosSessionsTableTableManager($_db, $_db.posSessions)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_posSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EmployeesTable, List<Employee>>
      _employeesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.employees,
          aliasName:
              $_aliasNameGenerator(db.users.id, db.employees.associatedUserId));

  $$EmployeesTableProcessedTableManager get employeesRefs {
    final manager = $$EmployeesTableTableManager($_db, $_db.employees).filter(
        (f) => f.associatedUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_employeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _voidedStockMovementsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.users.id, db.stockMovements.voidedBy));

  $$StockMovementsTableProcessedTableManager get voidedStockMovements {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.voidedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_voidedStockMovementsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _createdStockMovementsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.users.id, db.stockMovements.createdBy));

  $$StockMovementsTableProcessedTableManager get createdStockMovements {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.createdBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_createdStockMovementsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName: $_aliasNameGenerator(db.users.id, db.sales.cashierId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.cashierId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IpvReportsTable, List<IpvReport>>
      _openedIpvReportsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.ipvReports,
          aliasName: $_aliasNameGenerator(db.users.id, db.ipvReports.openedBy));

  $$IpvReportsTableProcessedTableManager get openedIpvReports {
    final manager = $$IpvReportsTableTableManager($_db, $_db.ipvReports)
        .filter((f) => f.openedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_openedIpvReportsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IpvReportsTable, List<IpvReport>>
      _closedIpvReportsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.ipvReports,
          aliasName: $_aliasNameGenerator(db.users.id, db.ipvReports.closedBy));

  $$IpvReportsTableProcessedTableManager get closedIpvReports {
    final manager = $$IpvReportsTableTableManager($_db, $_db.ipvReports)
        .filter((f) => f.closedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_closedIpvReportsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AuditLogsTable, List<AuditLog>>
      _auditLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.auditLogs,
          aliasName: $_aliasNameGenerator(db.users.id, db.auditLogs.userId));

  $$AuditLogsTableProcessedTableManager get auditLogsRefs {
    final manager = $$AuditLogsTableTableManager($_db, $_db.auditLogs)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_auditLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get salt => $composableBuilder(
      column: $table.salt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> userRolesRefs(
      Expression<bool> Function($$UserRolesTableFilterComposer f) f) {
    final $$UserRolesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userRoles,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserRolesTableFilterComposer(
              $db: $db,
              $table: $db.userRoles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> posSessionsRefs(
      Expression<bool> Function($$PosSessionsTableFilterComposer f) f) {
    final $$PosSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableFilterComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> employeesRefs(
      Expression<bool> Function($$EmployeesTableFilterComposer f) f) {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.associatedUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> voidedStockMovements(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.voidedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> createdStockMovements(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.createdBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.cashierId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> openedIpvReports(
      Expression<bool> Function($$IpvReportsTableFilterComposer f) f) {
    final $$IpvReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.openedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableFilterComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> closedIpvReports(
      Expression<bool> Function($$IpvReportsTableFilterComposer f) f) {
    final $$IpvReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.closedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableFilterComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> auditLogsRefs(
      Expression<bool> Function($$AuditLogsTableFilterComposer f) f) {
    final $$AuditLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLogs,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogsTableFilterComposer(
              $db: $db,
              $table: $db.auditLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get salt => $composableBuilder(
      column: $table.salt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<String> get salt =>
      $composableBuilder(column: $table.salt, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> userRolesRefs<T extends Object>(
      Expression<T> Function($$UserRolesTableAnnotationComposer a) f) {
    final $$UserRolesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userRoles,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserRolesTableAnnotationComposer(
              $db: $db,
              $table: $db.userRoles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> posSessionsRefs<T extends Object>(
      Expression<T> Function($$PosSessionsTableAnnotationComposer a) f) {
    final $$PosSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> employeesRefs<T extends Object>(
      Expression<T> Function($$EmployeesTableAnnotationComposer a) f) {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.associatedUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> voidedStockMovements<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.voidedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> createdStockMovements<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.createdBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.cashierId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> openedIpvReports<T extends Object>(
      Expression<T> Function($$IpvReportsTableAnnotationComposer a) f) {
    final $$IpvReportsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.openedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> closedIpvReports<T extends Object>(
      Expression<T> Function($$IpvReportsTableAnnotationComposer a) f) {
    final $$IpvReportsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.closedBy,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> auditLogsRefs<T extends Object>(
      Expression<T> Function($$AuditLogsTableAnnotationComposer a) f) {
    final $$AuditLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLogs,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.auditLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool userRolesRefs,
        bool posSessionsRefs,
        bool employeesRefs,
        bool voidedStockMovements,
        bool createdStockMovements,
        bool salesRefs,
        bool openedIpvReports,
        bool closedIpvReports,
        bool auditLogsRefs})> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<String> salt = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            username: username,
            passwordHash: passwordHash,
            salt: salt,
            role: role,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String username,
            required String passwordHash,
            required String salt,
            Value<String> role = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            username: username,
            passwordHash: passwordHash,
            salt: salt,
            role: role,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {userRolesRefs = false,
              posSessionsRefs = false,
              employeesRefs = false,
              voidedStockMovements = false,
              createdStockMovements = false,
              salesRefs = false,
              openedIpvReports = false,
              closedIpvReports = false,
              auditLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userRolesRefs) db.userRoles,
                if (posSessionsRefs) db.posSessions,
                if (employeesRefs) db.employees,
                if (voidedStockMovements) db.stockMovements,
                if (createdStockMovements) db.stockMovements,
                if (salesRefs) db.sales,
                if (openedIpvReports) db.ipvReports,
                if (closedIpvReports) db.ipvReports,
                if (auditLogsRefs) db.auditLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userRolesRefs)
                    await $_getPrefetchedData<User, $UsersTable, UserRole>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._userRolesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).userRolesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (posSessionsRefs)
                    await $_getPrefetchedData<User, $UsersTable, PosSession>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._posSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .posSessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (employeesRefs)
                    await $_getPrefetchedData<User, $UsersTable, Employee>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._employeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).employeesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.associatedUserId == item.id),
                        typedResults: items),
                  if (voidedStockMovements)
                    await $_getPrefetchedData<User, $UsersTable, StockMovement>(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._voidedStockMovementsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .voidedStockMovements,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.voidedBy == item.id),
                        typedResults: items),
                  if (createdStockMovements)
                    await $_getPrefetchedData<User, $UsersTable, StockMovement>(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._createdStockMovementsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .createdStockMovements,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.createdBy == item.id),
                        typedResults: items),
                  if (salesRefs)
                    await $_getPrefetchedData<User, $UsersTable, Sale>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).salesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.cashierId == item.id),
                        typedResults: items),
                  if (openedIpvReports)
                    await $_getPrefetchedData<User, $UsersTable, IpvReport>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._openedIpvReportsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .openedIpvReports,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.openedBy == item.id),
                        typedResults: items),
                  if (closedIpvReports)
                    await $_getPrefetchedData<User, $UsersTable, IpvReport>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._closedIpvReportsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .closedIpvReports,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.closedBy == item.id),
                        typedResults: items),
                  if (auditLogsRefs)
                    await $_getPrefetchedData<User, $UsersTable, AuditLog>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._auditLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).auditLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool userRolesRefs,
        bool posSessionsRefs,
        bool employeesRefs,
        bool voidedStockMovements,
        bool createdStockMovements,
        bool salesRefs,
        bool openedIpvReports,
        bool closedIpvReports,
        bool auditLogsRefs})>;
typedef $$RolesTableCreateCompanionBuilder = RolesCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<bool> isSystem,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$RolesTableUpdateCompanionBuilder = RolesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<bool> isSystem,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

final class $$RolesTableReferences
    extends BaseReferences<_$AppDatabase, $RolesTable, Role> {
  $$RolesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RolePermissionsTable, List<RolePermission>>
      _rolePermissionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.rolePermissions,
              aliasName:
                  $_aliasNameGenerator(db.roles.id, db.rolePermissions.roleId));

  $$RolePermissionsTableProcessedTableManager get rolePermissionsRefs {
    final manager =
        $$RolePermissionsTableTableManager($_db, $_db.rolePermissions)
            .filter((f) => f.roleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_rolePermissionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserRolesTable, List<UserRole>>
      _userRolesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.userRoles,
          aliasName: $_aliasNameGenerator(db.roles.id, db.userRoles.roleId));

  $$UserRolesTableProcessedTableManager get userRolesRefs {
    final manager = $$UserRolesTableTableManager($_db, $_db.userRoles)
        .filter((f) => f.roleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userRolesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RolesTableFilterComposer extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> rolePermissionsRefs(
      Expression<bool> Function($$RolePermissionsTableFilterComposer f) f) {
    final $$RolePermissionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rolePermissions,
        getReferencedColumn: (t) => t.roleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolePermissionsTableFilterComposer(
              $db: $db,
              $table: $db.rolePermissions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userRolesRefs(
      Expression<bool> Function($$UserRolesTableFilterComposer f) f) {
    final $$UserRolesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userRoles,
        getReferencedColumn: (t) => t.roleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserRolesTableFilterComposer(
              $db: $db,
              $table: $db.userRoles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RolesTableOrderingComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> rolePermissionsRefs<T extends Object>(
      Expression<T> Function($$RolePermissionsTableAnnotationComposer a) f) {
    final $$RolePermissionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rolePermissions,
        getReferencedColumn: (t) => t.roleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolePermissionsTableAnnotationComposer(
              $db: $db,
              $table: $db.rolePermissions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userRolesRefs<T extends Object>(
      Expression<T> Function($$UserRolesTableAnnotationComposer a) f) {
    final $$UserRolesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userRoles,
        getReferencedColumn: (t) => t.roleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserRolesTableAnnotationComposer(
              $db: $db,
              $table: $db.userRoles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RolesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RolesTable,
    Role,
    $$RolesTableFilterComposer,
    $$RolesTableOrderingComposer,
    $$RolesTableAnnotationComposer,
    $$RolesTableCreateCompanionBuilder,
    $$RolesTableUpdateCompanionBuilder,
    (Role, $$RolesTableReferences),
    Role,
    PrefetchHooks Function({bool rolePermissionsRefs, bool userRolesRefs})> {
  $$RolesTableTableManager(_$AppDatabase db, $RolesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RolesCompanion(
            id: id,
            name: name,
            description: description,
            isSystem: isSystem,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RolesCompanion.insert(
            id: id,
            name: name,
            description: description,
            isSystem: isSystem,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RolesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {rolePermissionsRefs = false, userRolesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rolePermissionsRefs) db.rolePermissions,
                if (userRolesRefs) db.userRoles
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rolePermissionsRefs)
                    await $_getPrefetchedData<Role, $RolesTable,
                            RolePermission>(
                        currentTable: table,
                        referencedTable: $$RolesTableReferences
                            ._rolePermissionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RolesTableReferences(db, table, p0)
                                .rolePermissionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.roleId == item.id),
                        typedResults: items),
                  if (userRolesRefs)
                    await $_getPrefetchedData<Role, $RolesTable, UserRole>(
                        currentTable: table,
                        referencedTable:
                            $$RolesTableReferences._userRolesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RolesTableReferences(db, table, p0).userRolesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.roleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RolesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RolesTable,
    Role,
    $$RolesTableFilterComposer,
    $$RolesTableOrderingComposer,
    $$RolesTableAnnotationComposer,
    $$RolesTableCreateCompanionBuilder,
    $$RolesTableUpdateCompanionBuilder,
    (Role, $$RolesTableReferences),
    Role,
    PrefetchHooks Function({bool rolePermissionsRefs, bool userRolesRefs})>;
typedef $$PermissionsTableCreateCompanionBuilder = PermissionsCompanion
    Function({
  required String key,
  required String module,
  required String label,
  Value<String?> description,
  Value<bool> isSystem,
  Value<int> rowid,
});
typedef $$PermissionsTableUpdateCompanionBuilder = PermissionsCompanion
    Function({
  Value<String> key,
  Value<String> module,
  Value<String> label,
  Value<String?> description,
  Value<bool> isSystem,
  Value<int> rowid,
});

final class $$PermissionsTableReferences
    extends BaseReferences<_$AppDatabase, $PermissionsTable, Permission> {
  $$PermissionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RolePermissionsTable, List<RolePermission>>
      _rolePermissionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.rolePermissions,
              aliasName: $_aliasNameGenerator(
                  db.permissions.key, db.rolePermissions.permissionKey));

  $$RolePermissionsTableProcessedTableManager get rolePermissionsRefs {
    final manager =
        $$RolePermissionsTableTableManager($_db, $_db.rolePermissions).filter(
            (f) => f.permissionKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache =
        $_typedResult.readTableOrNull(_rolePermissionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $PermissionsTable> {
  $$PermissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnFilters(column));

  Expression<bool> rolePermissionsRefs(
      Expression<bool> Function($$RolePermissionsTableFilterComposer f) f) {
    final $$RolePermissionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.key,
        referencedTable: $db.rolePermissions,
        getReferencedColumn: (t) => t.permissionKey,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolePermissionsTableFilterComposer(
              $db: $db,
              $table: $db.rolePermissions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PermissionsTable> {
  $$PermissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnOrderings(column));
}

class $$PermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PermissionsTable> {
  $$PermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  Expression<T> rolePermissionsRefs<T extends Object>(
      Expression<T> Function($$RolePermissionsTableAnnotationComposer a) f) {
    final $$RolePermissionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.key,
        referencedTable: $db.rolePermissions,
        getReferencedColumn: (t) => t.permissionKey,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolePermissionsTableAnnotationComposer(
              $db: $db,
              $table: $db.rolePermissions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PermissionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PermissionsTable,
    Permission,
    $$PermissionsTableFilterComposer,
    $$PermissionsTableOrderingComposer,
    $$PermissionsTableAnnotationComposer,
    $$PermissionsTableCreateCompanionBuilder,
    $$PermissionsTableUpdateCompanionBuilder,
    (Permission, $$PermissionsTableReferences),
    Permission,
    PrefetchHooks Function({bool rolePermissionsRefs})> {
  $$PermissionsTableTableManager(_$AppDatabase db, $PermissionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PermissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PermissionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> module = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PermissionsCompanion(
            key: key,
            module: module,
            label: label,
            description: description,
            isSystem: isSystem,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String module,
            required String label,
            Value<String?> description = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PermissionsCompanion.insert(
            key: key,
            module: module,
            label: label,
            description: description,
            isSystem: isSystem,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PermissionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({rolePermissionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rolePermissionsRefs) db.rolePermissions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rolePermissionsRefs)
                    await $_getPrefetchedData<Permission, $PermissionsTable,
                            RolePermission>(
                        currentTable: table,
                        referencedTable: $$PermissionsTableReferences
                            ._rolePermissionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PermissionsTableReferences(db, table, p0)
                                .rolePermissionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.permissionKey == item.key),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PermissionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PermissionsTable,
    Permission,
    $$PermissionsTableFilterComposer,
    $$PermissionsTableOrderingComposer,
    $$PermissionsTableAnnotationComposer,
    $$PermissionsTableCreateCompanionBuilder,
    $$PermissionsTableUpdateCompanionBuilder,
    (Permission, $$PermissionsTableReferences),
    Permission,
    PrefetchHooks Function({bool rolePermissionsRefs})>;
typedef $$RolePermissionsTableCreateCompanionBuilder = RolePermissionsCompanion
    Function({
  required String roleId,
  required String permissionKey,
  Value<DateTime> grantedAt,
  Value<int> rowid,
});
typedef $$RolePermissionsTableUpdateCompanionBuilder = RolePermissionsCompanion
    Function({
  Value<String> roleId,
  Value<String> permissionKey,
  Value<DateTime> grantedAt,
  Value<int> rowid,
});

final class $$RolePermissionsTableReferences extends BaseReferences<
    _$AppDatabase, $RolePermissionsTable, RolePermission> {
  $$RolePermissionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RolesTable _roleIdTable(_$AppDatabase db) => db.roles.createAlias(
      $_aliasNameGenerator(db.rolePermissions.roleId, db.roles.id));

  $$RolesTableProcessedTableManager get roleId {
    final $_column = $_itemColumn<String>('role_id')!;

    final manager = $$RolesTableTableManager($_db, $_db.roles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PermissionsTable _permissionKeyTable(_$AppDatabase db) =>
      db.permissions.createAlias($_aliasNameGenerator(
          db.rolePermissions.permissionKey, db.permissions.key));

  $$PermissionsTableProcessedTableManager get permissionKey {
    final $_column = $_itemColumn<String>('permission_key')!;

    final manager = $$PermissionsTableTableManager($_db, $_db.permissions)
        .filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_permissionKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RolePermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get grantedAt => $composableBuilder(
      column: $table.grantedAt, builder: (column) => ColumnFilters(column));

  $$RolesTableFilterComposer get roleId {
    final $$RolesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roleId,
        referencedTable: $db.roles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolesTableFilterComposer(
              $db: $db,
              $table: $db.roles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PermissionsTableFilterComposer get permissionKey {
    final $$PermissionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.permissionKey,
        referencedTable: $db.permissions,
        getReferencedColumn: (t) => t.key,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PermissionsTableFilterComposer(
              $db: $db,
              $table: $db.permissions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RolePermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get grantedAt => $composableBuilder(
      column: $table.grantedAt, builder: (column) => ColumnOrderings(column));

  $$RolesTableOrderingComposer get roleId {
    final $$RolesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roleId,
        referencedTable: $db.roles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolesTableOrderingComposer(
              $db: $db,
              $table: $db.roles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PermissionsTableOrderingComposer get permissionKey {
    final $$PermissionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.permissionKey,
        referencedTable: $db.permissions,
        getReferencedColumn: (t) => t.key,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PermissionsTableOrderingComposer(
              $db: $db,
              $table: $db.permissions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RolePermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get grantedAt =>
      $composableBuilder(column: $table.grantedAt, builder: (column) => column);

  $$RolesTableAnnotationComposer get roleId {
    final $$RolesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roleId,
        referencedTable: $db.roles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolesTableAnnotationComposer(
              $db: $db,
              $table: $db.roles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PermissionsTableAnnotationComposer get permissionKey {
    final $$PermissionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.permissionKey,
        referencedTable: $db.permissions,
        getReferencedColumn: (t) => t.key,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PermissionsTableAnnotationComposer(
              $db: $db,
              $table: $db.permissions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RolePermissionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RolePermissionsTable,
    RolePermission,
    $$RolePermissionsTableFilterComposer,
    $$RolePermissionsTableOrderingComposer,
    $$RolePermissionsTableAnnotationComposer,
    $$RolePermissionsTableCreateCompanionBuilder,
    $$RolePermissionsTableUpdateCompanionBuilder,
    (RolePermission, $$RolePermissionsTableReferences),
    RolePermission,
    PrefetchHooks Function({bool roleId, bool permissionKey})> {
  $$RolePermissionsTableTableManager(
      _$AppDatabase db, $RolePermissionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RolePermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RolePermissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RolePermissionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> roleId = const Value.absent(),
            Value<String> permissionKey = const Value.absent(),
            Value<DateTime> grantedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RolePermissionsCompanion(
            roleId: roleId,
            permissionKey: permissionKey,
            grantedAt: grantedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String roleId,
            required String permissionKey,
            Value<DateTime> grantedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RolePermissionsCompanion.insert(
            roleId: roleId,
            permissionKey: permissionKey,
            grantedAt: grantedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RolePermissionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({roleId = false, permissionKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (roleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.roleId,
                    referencedTable:
                        $$RolePermissionsTableReferences._roleIdTable(db),
                    referencedColumn:
                        $$RolePermissionsTableReferences._roleIdTable(db).id,
                  ) as T;
                }
                if (permissionKey) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.permissionKey,
                    referencedTable: $$RolePermissionsTableReferences
                        ._permissionKeyTable(db),
                    referencedColumn: $$RolePermissionsTableReferences
                        ._permissionKeyTable(db)
                        .key,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RolePermissionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RolePermissionsTable,
    RolePermission,
    $$RolePermissionsTableFilterComposer,
    $$RolePermissionsTableOrderingComposer,
    $$RolePermissionsTableAnnotationComposer,
    $$RolePermissionsTableCreateCompanionBuilder,
    $$RolePermissionsTableUpdateCompanionBuilder,
    (RolePermission, $$RolePermissionsTableReferences),
    RolePermission,
    PrefetchHooks Function({bool roleId, bool permissionKey})>;
typedef $$UserRolesTableCreateCompanionBuilder = UserRolesCompanion Function({
  required String userId,
  required String roleId,
  Value<DateTime> assignedAt,
  Value<int> rowid,
});
typedef $$UserRolesTableUpdateCompanionBuilder = UserRolesCompanion Function({
  Value<String> userId,
  Value<String> roleId,
  Value<DateTime> assignedAt,
  Value<int> rowid,
});

final class $$UserRolesTableReferences
    extends BaseReferences<_$AppDatabase, $UserRolesTable, UserRole> {
  $$UserRolesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.userRoles.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RolesTable _roleIdTable(_$AppDatabase db) => db.roles
      .createAlias($_aliasNameGenerator(db.userRoles.roleId, db.roles.id));

  $$RolesTableProcessedTableManager get roleId {
    final $_column = $_itemColumn<String>('role_id')!;

    final manager = $$RolesTableTableManager($_db, $_db.roles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserRolesTableFilterComposer
    extends Composer<_$AppDatabase, $UserRolesTable> {
  $$UserRolesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RolesTableFilterComposer get roleId {
    final $$RolesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roleId,
        referencedTable: $db.roles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolesTableFilterComposer(
              $db: $db,
              $table: $db.roles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserRolesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserRolesTable> {
  $$UserRolesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RolesTableOrderingComposer get roleId {
    final $$RolesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roleId,
        referencedTable: $db.roles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolesTableOrderingComposer(
              $db: $db,
              $table: $db.roles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserRolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserRolesTable> {
  $$UserRolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RolesTableAnnotationComposer get roleId {
    final $$RolesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.roleId,
        referencedTable: $db.roles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RolesTableAnnotationComposer(
              $db: $db,
              $table: $db.roles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserRolesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserRolesTable,
    UserRole,
    $$UserRolesTableFilterComposer,
    $$UserRolesTableOrderingComposer,
    $$UserRolesTableAnnotationComposer,
    $$UserRolesTableCreateCompanionBuilder,
    $$UserRolesTableUpdateCompanionBuilder,
    (UserRole, $$UserRolesTableReferences),
    UserRole,
    PrefetchHooks Function({bool userId, bool roleId})> {
  $$UserRolesTableTableManager(_$AppDatabase db, $UserRolesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> roleId = const Value.absent(),
            Value<DateTime> assignedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserRolesCompanion(
            userId: userId,
            roleId: roleId,
            assignedAt: assignedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String roleId,
            Value<DateTime> assignedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserRolesCompanion.insert(
            userId: userId,
            roleId: roleId,
            assignedAt: assignedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserRolesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false, roleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$UserRolesTableReferences._userIdTable(db),
                    referencedColumn:
                        $$UserRolesTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (roleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.roleId,
                    referencedTable:
                        $$UserRolesTableReferences._roleIdTable(db),
                    referencedColumn:
                        $$UserRolesTableReferences._roleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UserRolesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserRolesTable,
    UserRole,
    $$UserRolesTableFilterComposer,
    $$UserRolesTableOrderingComposer,
    $$UserRolesTableAnnotationComposer,
    $$UserRolesTableCreateCompanionBuilder,
    $$UserRolesTableUpdateCompanionBuilder,
    (UserRole, $$UserRolesTableReferences),
    UserRole,
    PrefetchHooks Function({bool userId, bool roleId})>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String sku,
  Value<String?> barcode,
  required String name,
  Value<int> priceCents,
  Value<int> taxRateBps,
  Value<String?> imagePath,
  Value<int> costPriceCents,
  Value<String> category,
  Value<String> productType,
  Value<String> unitMeasure,
  Value<String> currencyCode,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> sku,
  Value<String?> barcode,
  Value<String> name,
  Value<int> priceCents,
  Value<int> taxRateBps,
  Value<String?> imagePath,
  Value<int> costPriceCents,
  Value<String> category,
  Value<String> productType,
  Value<String> unitMeasure,
  Value<String> currencyCode,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockBalancesTable, List<StockBalance>>
      _stockBalancesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockBalances,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.stockBalances.productId));

  $$StockBalancesTableProcessedTableManager get stockBalancesRefs {
    final manager = $$StockBalancesTableTableManager($_db, $_db.stockBalances)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockBalancesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _stockMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.stockMovements.productId));

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
      _saleItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.saleItems,
              aliasName:
                  $_aliasNameGenerator(db.products.id, db.saleItems.productId));

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager($_db, $_db.saleItems)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IpvReportLinesTable, List<IpvReportLine>>
      _ipvReportLinesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ipvReportLines,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.ipvReportLines.productId));

  $$IpvReportLinesTableProcessedTableManager get ipvReportLinesRefs {
    final manager = $$IpvReportLinesTableTableManager($_db, $_db.ipvReportLines)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ipvReportLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxRateBps => $composableBuilder(
      column: $table.taxRateBps, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get costPriceCents => $composableBuilder(
      column: $table.costPriceCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productType => $composableBuilder(
      column: $table.productType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitMeasure => $composableBuilder(
      column: $table.unitMeasure, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> stockBalancesRefs(
      Expression<bool> Function($$StockBalancesTableFilterComposer f) f) {
    final $$StockBalancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockBalances,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockBalancesTableFilterComposer(
              $db: $db,
              $table: $db.stockBalances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> saleItemsRefs(
      Expression<bool> Function($$SaleItemsTableFilterComposer f) f) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableFilterComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ipvReportLinesRefs(
      Expression<bool> Function($$IpvReportLinesTableFilterComposer f) f) {
    final $$IpvReportLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReportLines,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportLinesTableFilterComposer(
              $db: $db,
              $table: $db.ipvReportLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxRateBps => $composableBuilder(
      column: $table.taxRateBps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get costPriceCents => $composableBuilder(
      column: $table.costPriceCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productType => $composableBuilder(
      column: $table.productType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitMeasure => $composableBuilder(
      column: $table.unitMeasure, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => column);

  GeneratedColumn<int> get taxRateBps => $composableBuilder(
      column: $table.taxRateBps, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get costPriceCents => $composableBuilder(
      column: $table.costPriceCents, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get productType => $composableBuilder(
      column: $table.productType, builder: (column) => column);

  GeneratedColumn<String> get unitMeasure => $composableBuilder(
      column: $table.unitMeasure, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> stockBalancesRefs<T extends Object>(
      Expression<T> Function($$StockBalancesTableAnnotationComposer a) f) {
    final $$StockBalancesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockBalances,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockBalancesTableAnnotationComposer(
              $db: $db,
              $table: $db.stockBalances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> saleItemsRefs<T extends Object>(
      Expression<T> Function($$SaleItemsTableAnnotationComposer a) f) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ipvReportLinesRefs<T extends Object>(
      Expression<T> Function($$IpvReportLinesTableAnnotationComposer a) f) {
    final $$IpvReportLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReportLines,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReportLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function(
        {bool stockBalancesRefs,
        bool stockMovementsRefs,
        bool saleItemsRefs,
        bool ipvReportLinesRefs})> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> priceCents = const Value.absent(),
            Value<int> taxRateBps = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<int> costPriceCents = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> productType = const Value.absent(),
            Value<String> unitMeasure = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            sku: sku,
            barcode: barcode,
            name: name,
            priceCents: priceCents,
            taxRateBps: taxRateBps,
            imagePath: imagePath,
            costPriceCents: costPriceCents,
            category: category,
            productType: productType,
            unitMeasure: unitMeasure,
            currencyCode: currencyCode,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sku,
            Value<String?> barcode = const Value.absent(),
            required String name,
            Value<int> priceCents = const Value.absent(),
            Value<int> taxRateBps = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<int> costPriceCents = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> productType = const Value.absent(),
            Value<String> unitMeasure = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            sku: sku,
            barcode: barcode,
            name: name,
            priceCents: priceCents,
            taxRateBps: taxRateBps,
            imagePath: imagePath,
            costPriceCents: costPriceCents,
            category: category,
            productType: productType,
            unitMeasure: unitMeasure,
            currencyCode: currencyCode,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {stockBalancesRefs = false,
              stockMovementsRefs = false,
              saleItemsRefs = false,
              ipvReportLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockBalancesRefs) db.stockBalances,
                if (stockMovementsRefs) db.stockMovements,
                if (saleItemsRefs) db.saleItems,
                if (ipvReportLinesRefs) db.ipvReportLines
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockBalancesRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            StockBalance>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._stockBalancesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .stockBalancesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (stockMovementsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            StockMovement>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._stockMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .stockMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (saleItemsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            SaleItem>(
                        currentTable: table,
                        referencedTable:
                            $$ProductsTableReferences._saleItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .saleItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (ipvReportLinesRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            IpvReportLine>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._ipvReportLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .ipvReportLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function(
        {bool stockBalancesRefs,
        bool stockMovementsRefs,
        bool saleItemsRefs,
        bool ipvReportLinesRefs})>;
typedef $$ProductCatalogItemsTableCreateCompanionBuilder
    = ProductCatalogItemsCompanion Function({
  required String id,
  required String kind,
  required String value,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ProductCatalogItemsTableUpdateCompanionBuilder
    = ProductCatalogItemsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> value,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$ProductCatalogItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductCatalogItemsTable> {
  $$ProductCatalogItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProductCatalogItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductCatalogItemsTable> {
  $$ProductCatalogItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductCatalogItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductCatalogItemsTable> {
  $$ProductCatalogItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductCatalogItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductCatalogItemsTable,
    ProductCatalogItem,
    $$ProductCatalogItemsTableFilterComposer,
    $$ProductCatalogItemsTableOrderingComposer,
    $$ProductCatalogItemsTableAnnotationComposer,
    $$ProductCatalogItemsTableCreateCompanionBuilder,
    $$ProductCatalogItemsTableUpdateCompanionBuilder,
    (
      ProductCatalogItem,
      BaseReferences<_$AppDatabase, $ProductCatalogItemsTable,
          ProductCatalogItem>
    ),
    ProductCatalogItem,
    PrefetchHooks Function()> {
  $$ProductCatalogItemsTableTableManager(
      _$AppDatabase db, $ProductCatalogItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductCatalogItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductCatalogItemsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductCatalogItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductCatalogItemsCompanion(
            id: id,
            kind: kind,
            value: value,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required String value,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductCatalogItemsCompanion.insert(
            id: id,
            kind: kind,
            value: value,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductCatalogItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductCatalogItemsTable,
    ProductCatalogItem,
    $$ProductCatalogItemsTableFilterComposer,
    $$ProductCatalogItemsTableOrderingComposer,
    $$ProductCatalogItemsTableAnnotationComposer,
    $$ProductCatalogItemsTableCreateCompanionBuilder,
    $$ProductCatalogItemsTableUpdateCompanionBuilder,
    (
      ProductCatalogItem,
      BaseReferences<_$AppDatabase, $ProductCatalogItemsTable,
          ProductCatalogItem>
    ),
    ProductCatalogItem,
    PrefetchHooks Function()>;
typedef $$WarehousesTableCreateCompanionBuilder = WarehousesCompanion Function({
  required String id,
  required String name,
  Value<String> warehouseType,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$WarehousesTableUpdateCompanionBuilder = WarehousesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> warehouseType,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$WarehousesTableReferences
    extends BaseReferences<_$AppDatabase, $WarehousesTable, Warehouse> {
  $$WarehousesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PosTerminalsTable, List<PosTerminal>>
      _posTerminalsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.posTerminals,
              aliasName: $_aliasNameGenerator(
                  db.warehouses.id, db.posTerminals.warehouseId));

  $$PosTerminalsTableProcessedTableManager get posTerminalsRefs {
    final manager = $$PosTerminalsTableTableManager($_db, $_db.posTerminals)
        .filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_posTerminalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockBalancesTable, List<StockBalance>>
      _stockBalancesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockBalances,
              aliasName: $_aliasNameGenerator(
                  db.warehouses.id, db.stockBalances.warehouseId));

  $$StockBalancesTableProcessedTableManager get stockBalancesRefs {
    final manager = $$StockBalancesTableTableManager($_db, $_db.stockBalances)
        .filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockBalancesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _stockMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.warehouses.id, db.stockMovements.warehouseId));

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName:
              $_aliasNameGenerator(db.warehouses.id, db.sales.warehouseId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IpvReportsTable, List<IpvReport>>
      _ipvReportsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ipvReports,
              aliasName: $_aliasNameGenerator(
                  db.warehouses.id, db.ipvReports.warehouseId));

  $$IpvReportsTableProcessedTableManager get ipvReportsRefs {
    final manager = $$IpvReportsTableTableManager($_db, $_db.ipvReports)
        .filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ipvReportsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WarehousesTableFilterComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get warehouseType => $composableBuilder(
      column: $table.warehouseType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> posTerminalsRefs(
      Expression<bool> Function($$PosTerminalsTableFilterComposer f) f) {
    final $$PosTerminalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableFilterComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockBalancesRefs(
      Expression<bool> Function($$StockBalancesTableFilterComposer f) f) {
    final $$StockBalancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockBalances,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockBalancesTableFilterComposer(
              $db: $db,
              $table: $db.stockBalances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ipvReportsRefs(
      Expression<bool> Function($$IpvReportsTableFilterComposer f) f) {
    final $$IpvReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableFilterComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WarehousesTableOrderingComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get warehouseType => $composableBuilder(
      column: $table.warehouseType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$WarehousesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get warehouseType => $composableBuilder(
      column: $table.warehouseType, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> posTerminalsRefs<T extends Object>(
      Expression<T> Function($$PosTerminalsTableAnnotationComposer a) f) {
    final $$PosTerminalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableAnnotationComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockBalancesRefs<T extends Object>(
      Expression<T> Function($$StockBalancesTableAnnotationComposer a) f) {
    final $$StockBalancesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockBalances,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockBalancesTableAnnotationComposer(
              $db: $db,
              $table: $db.stockBalances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ipvReportsRefs<T extends Object>(
      Expression<T> Function($$IpvReportsTableAnnotationComposer a) f) {
    final $$IpvReportsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.warehouseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WarehousesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WarehousesTable,
    Warehouse,
    $$WarehousesTableFilterComposer,
    $$WarehousesTableOrderingComposer,
    $$WarehousesTableAnnotationComposer,
    $$WarehousesTableCreateCompanionBuilder,
    $$WarehousesTableUpdateCompanionBuilder,
    (Warehouse, $$WarehousesTableReferences),
    Warehouse,
    PrefetchHooks Function(
        {bool posTerminalsRefs,
        bool stockBalancesRefs,
        bool stockMovementsRefs,
        bool salesRefs,
        bool ipvReportsRefs})> {
  $$WarehousesTableTableManager(_$AppDatabase db, $WarehousesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WarehousesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WarehousesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WarehousesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> warehouseType = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WarehousesCompanion(
            id: id,
            name: name,
            warehouseType: warehouseType,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> warehouseType = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WarehousesCompanion.insert(
            id: id,
            name: name,
            warehouseType: warehouseType,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WarehousesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {posTerminalsRefs = false,
              stockBalancesRefs = false,
              stockMovementsRefs = false,
              salesRefs = false,
              ipvReportsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (posTerminalsRefs) db.posTerminals,
                if (stockBalancesRefs) db.stockBalances,
                if (stockMovementsRefs) db.stockMovements,
                if (salesRefs) db.sales,
                if (ipvReportsRefs) db.ipvReports
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (posTerminalsRefs)
                    await $_getPrefetchedData<Warehouse, $WarehousesTable,
                            PosTerminal>(
                        currentTable: table,
                        referencedTable: $$WarehousesTableReferences
                            ._posTerminalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WarehousesTableReferences(db, table, p0)
                                .posTerminalsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.warehouseId == item.id),
                        typedResults: items),
                  if (stockBalancesRefs)
                    await $_getPrefetchedData<Warehouse, $WarehousesTable,
                            StockBalance>(
                        currentTable: table,
                        referencedTable: $$WarehousesTableReferences
                            ._stockBalancesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WarehousesTableReferences(db, table, p0)
                                .stockBalancesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.warehouseId == item.id),
                        typedResults: items),
                  if (stockMovementsRefs)
                    await $_getPrefetchedData<Warehouse, $WarehousesTable,
                            StockMovement>(
                        currentTable: table,
                        referencedTable: $$WarehousesTableReferences
                            ._stockMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WarehousesTableReferences(db, table, p0)
                                .stockMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.warehouseId == item.id),
                        typedResults: items),
                  if (salesRefs)
                    await $_getPrefetchedData<Warehouse, $WarehousesTable,
                            Sale>(
                        currentTable: table,
                        referencedTable:
                            $$WarehousesTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WarehousesTableReferences(db, table, p0)
                                .salesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.warehouseId == item.id),
                        typedResults: items),
                  if (ipvReportsRefs)
                    await $_getPrefetchedData<Warehouse, $WarehousesTable,
                            IpvReport>(
                        currentTable: table,
                        referencedTable: $$WarehousesTableReferences
                            ._ipvReportsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WarehousesTableReferences(db, table, p0)
                                .ipvReportsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.warehouseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WarehousesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WarehousesTable,
    Warehouse,
    $$WarehousesTableFilterComposer,
    $$WarehousesTableOrderingComposer,
    $$WarehousesTableAnnotationComposer,
    $$WarehousesTableCreateCompanionBuilder,
    $$WarehousesTableUpdateCompanionBuilder,
    (Warehouse, $$WarehousesTableReferences),
    Warehouse,
    PrefetchHooks Function(
        {bool posTerminalsRefs,
        bool stockBalancesRefs,
        bool stockMovementsRefs,
        bool salesRefs,
        bool ipvReportsRefs})>;
typedef $$PosTerminalsTableCreateCompanionBuilder = PosTerminalsCompanion
    Function({
  required String id,
  required String code,
  required String name,
  required String warehouseId,
  Value<String> currencyCode,
  Value<String> currencySymbol,
  Value<String> paymentMethodsJson,
  Value<String> cashDenominationsJson,
  Value<String?> imagePath,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$PosTerminalsTableUpdateCompanionBuilder = PosTerminalsCompanion
    Function({
  Value<String> id,
  Value<String> code,
  Value<String> name,
  Value<String> warehouseId,
  Value<String> currencyCode,
  Value<String> currencySymbol,
  Value<String> paymentMethodsJson,
  Value<String> cashDenominationsJson,
  Value<String?> imagePath,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

final class $$PosTerminalsTableReferences
    extends BaseReferences<_$AppDatabase, $PosTerminalsTable, PosTerminal> {
  $$PosTerminalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WarehousesTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehouses.createAlias(
          $_aliasNameGenerator(db.posTerminals.warehouseId, db.warehouses.id));

  $$WarehousesTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableManager($_db, $_db.warehouses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PosSessionsTable, List<PosSession>>
      _posSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.posSessions,
              aliasName: $_aliasNameGenerator(
                  db.posTerminals.id, db.posSessions.terminalId));

  $$PosSessionsTableProcessedTableManager get posSessionsRefs {
    final manager = $$PosSessionsTableTableManager($_db, $_db.posSessions)
        .filter((f) => f.terminalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_posSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PosTerminalEmployeesTable,
      List<PosTerminalEmployee>> _posTerminalEmployeesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.posTerminalEmployees,
          aliasName: $_aliasNameGenerator(
              db.posTerminals.id, db.posTerminalEmployees.terminalId));

  $$PosTerminalEmployeesTableProcessedTableManager
      get posTerminalEmployeesRefs {
    final manager = $$PosTerminalEmployeesTableTableManager(
            $_db, $_db.posTerminalEmployees)
        .filter((f) => f.terminalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_posTerminalEmployeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName:
              $_aliasNameGenerator(db.posTerminals.id, db.sales.terminalId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.terminalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IpvReportsTable, List<IpvReport>>
      _ipvReportsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ipvReports,
              aliasName: $_aliasNameGenerator(
                  db.posTerminals.id, db.ipvReports.terminalId));

  $$IpvReportsTableProcessedTableManager get ipvReportsRefs {
    final manager = $$IpvReportsTableTableManager($_db, $_db.ipvReports)
        .filter((f) => f.terminalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ipvReportsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PosTerminalsTableFilterComposer
    extends Composer<_$AppDatabase, $PosTerminalsTable> {
  $$PosTerminalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethodsJson => $composableBuilder(
      column: $table.paymentMethodsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cashDenominationsJson => $composableBuilder(
      column: $table.cashDenominationsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$WarehousesTableFilterComposer get warehouseId {
    final $$WarehousesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableFilterComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> posSessionsRefs(
      Expression<bool> Function($$PosSessionsTableFilterComposer f) f) {
    final $$PosSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.terminalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableFilterComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> posTerminalEmployeesRefs(
      Expression<bool> Function($$PosTerminalEmployeesTableFilterComposer f)
          f) {
    final $$PosTerminalEmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posTerminalEmployees,
        getReferencedColumn: (t) => t.terminalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalEmployeesTableFilterComposer(
              $db: $db,
              $table: $db.posTerminalEmployees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.terminalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ipvReportsRefs(
      Expression<bool> Function($$IpvReportsTableFilterComposer f) f) {
    final $$IpvReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.terminalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableFilterComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PosTerminalsTableOrderingComposer
    extends Composer<_$AppDatabase, $PosTerminalsTable> {
  $$PosTerminalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethodsJson => $composableBuilder(
      column: $table.paymentMethodsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cashDenominationsJson => $composableBuilder(
      column: $table.cashDenominationsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$WarehousesTableOrderingComposer get warehouseId {
    final $$WarehousesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableOrderingComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosTerminalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PosTerminalsTable> {
  $$PosTerminalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol, builder: (column) => column);

  GeneratedColumn<String> get paymentMethodsJson => $composableBuilder(
      column: $table.paymentMethodsJson, builder: (column) => column);

  GeneratedColumn<String> get cashDenominationsJson => $composableBuilder(
      column: $table.cashDenominationsJson, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WarehousesTableAnnotationComposer get warehouseId {
    final $$WarehousesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableAnnotationComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> posSessionsRefs<T extends Object>(
      Expression<T> Function($$PosSessionsTableAnnotationComposer a) f) {
    final $$PosSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.terminalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> posTerminalEmployeesRefs<T extends Object>(
      Expression<T> Function($$PosTerminalEmployeesTableAnnotationComposer a)
          f) {
    final $$PosTerminalEmployeesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.posTerminalEmployees,
            getReferencedColumn: (t) => t.terminalId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PosTerminalEmployeesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.posTerminalEmployees,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.terminalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ipvReportsRefs<T extends Object>(
      Expression<T> Function($$IpvReportsTableAnnotationComposer a) f) {
    final $$IpvReportsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.terminalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PosTerminalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PosTerminalsTable,
    PosTerminal,
    $$PosTerminalsTableFilterComposer,
    $$PosTerminalsTableOrderingComposer,
    $$PosTerminalsTableAnnotationComposer,
    $$PosTerminalsTableCreateCompanionBuilder,
    $$PosTerminalsTableUpdateCompanionBuilder,
    (PosTerminal, $$PosTerminalsTableReferences),
    PosTerminal,
    PrefetchHooks Function(
        {bool warehouseId,
        bool posSessionsRefs,
        bool posTerminalEmployeesRefs,
        bool salesRefs,
        bool ipvReportsRefs})> {
  $$PosTerminalsTableTableManager(_$AppDatabase db, $PosTerminalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PosTerminalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PosTerminalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PosTerminalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> warehouseId = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<String> currencySymbol = const Value.absent(),
            Value<String> paymentMethodsJson = const Value.absent(),
            Value<String> cashDenominationsJson = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosTerminalsCompanion(
            id: id,
            code: code,
            name: name,
            warehouseId: warehouseId,
            currencyCode: currencyCode,
            currencySymbol: currencySymbol,
            paymentMethodsJson: paymentMethodsJson,
            cashDenominationsJson: cashDenominationsJson,
            imagePath: imagePath,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String code,
            required String name,
            required String warehouseId,
            Value<String> currencyCode = const Value.absent(),
            Value<String> currencySymbol = const Value.absent(),
            Value<String> paymentMethodsJson = const Value.absent(),
            Value<String> cashDenominationsJson = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosTerminalsCompanion.insert(
            id: id,
            code: code,
            name: name,
            warehouseId: warehouseId,
            currencyCode: currencyCode,
            currencySymbol: currencySymbol,
            paymentMethodsJson: paymentMethodsJson,
            cashDenominationsJson: cashDenominationsJson,
            imagePath: imagePath,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PosTerminalsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {warehouseId = false,
              posSessionsRefs = false,
              posTerminalEmployeesRefs = false,
              salesRefs = false,
              ipvReportsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (posSessionsRefs) db.posSessions,
                if (posTerminalEmployeesRefs) db.posTerminalEmployees,
                if (salesRefs) db.sales,
                if (ipvReportsRefs) db.ipvReports
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (warehouseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.warehouseId,
                    referencedTable:
                        $$PosTerminalsTableReferences._warehouseIdTable(db),
                    referencedColumn:
                        $$PosTerminalsTableReferences._warehouseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (posSessionsRefs)
                    await $_getPrefetchedData<PosTerminal, $PosTerminalsTable,
                            PosSession>(
                        currentTable: table,
                        referencedTable: $$PosTerminalsTableReferences
                            ._posSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosTerminalsTableReferences(db, table, p0)
                                .posSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.terminalId == item.id),
                        typedResults: items),
                  if (posTerminalEmployeesRefs)
                    await $_getPrefetchedData<PosTerminal, $PosTerminalsTable,
                            PosTerminalEmployee>(
                        currentTable: table,
                        referencedTable: $$PosTerminalsTableReferences
                            ._posTerminalEmployeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosTerminalsTableReferences(db, table, p0)
                                .posTerminalEmployeesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.terminalId == item.id),
                        typedResults: items),
                  if (salesRefs)
                    await $_getPrefetchedData<PosTerminal, $PosTerminalsTable,
                            Sale>(
                        currentTable: table,
                        referencedTable:
                            $$PosTerminalsTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosTerminalsTableReferences(db, table, p0)
                                .salesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.terminalId == item.id),
                        typedResults: items),
                  if (ipvReportsRefs)
                    await $_getPrefetchedData<PosTerminal, $PosTerminalsTable,
                            IpvReport>(
                        currentTable: table,
                        referencedTable: $$PosTerminalsTableReferences
                            ._ipvReportsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosTerminalsTableReferences(db, table, p0)
                                .ipvReportsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.terminalId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PosTerminalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PosTerminalsTable,
    PosTerminal,
    $$PosTerminalsTableFilterComposer,
    $$PosTerminalsTableOrderingComposer,
    $$PosTerminalsTableAnnotationComposer,
    $$PosTerminalsTableCreateCompanionBuilder,
    $$PosTerminalsTableUpdateCompanionBuilder,
    (PosTerminal, $$PosTerminalsTableReferences),
    PosTerminal,
    PrefetchHooks Function(
        {bool warehouseId,
        bool posSessionsRefs,
        bool posTerminalEmployeesRefs,
        bool salesRefs,
        bool ipvReportsRefs})>;
typedef $$PosSessionsTableCreateCompanionBuilder = PosSessionsCompanion
    Function({
  required String id,
  required String terminalId,
  required String userId,
  Value<DateTime> openedAt,
  Value<int> openingFloatCents,
  Value<DateTime?> closedAt,
  Value<int?> closingCashCents,
  Value<String> status,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$PosSessionsTableUpdateCompanionBuilder = PosSessionsCompanion
    Function({
  Value<String> id,
  Value<String> terminalId,
  Value<String> userId,
  Value<DateTime> openedAt,
  Value<int> openingFloatCents,
  Value<DateTime?> closedAt,
  Value<int?> closingCashCents,
  Value<String> status,
  Value<String?> note,
  Value<int> rowid,
});

final class $$PosSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $PosSessionsTable, PosSession> {
  $$PosSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PosTerminalsTable _terminalIdTable(_$AppDatabase db) =>
      db.posTerminals.createAlias(
          $_aliasNameGenerator(db.posSessions.terminalId, db.posTerminals.id));

  $$PosTerminalsTableProcessedTableManager get terminalId {
    final $_column = $_itemColumn<String>('terminal_id')!;

    final manager = $$PosTerminalsTableTableManager($_db, $_db.posTerminals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_terminalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.posSessions.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PosSessionCashBreakdownsTable,
      List<PosSessionCashBreakdown>> _posSessionCashBreakdownsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.posSessionCashBreakdowns,
          aliasName: $_aliasNameGenerator(
              db.posSessions.id, db.posSessionCashBreakdowns.sessionId));

  $$PosSessionCashBreakdownsTableProcessedTableManager
      get posSessionCashBreakdownsRefs {
    final manager = $$PosSessionCashBreakdownsTableTableManager(
            $_db, $_db.posSessionCashBreakdowns)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_posSessionCashBreakdownsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PosSessionEmployeesTable,
      List<PosSessionEmployee>> _posSessionEmployeesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.posSessionEmployees,
          aliasName: $_aliasNameGenerator(
              db.posSessions.id, db.posSessionEmployees.sessionId));

  $$PosSessionEmployeesTableProcessedTableManager get posSessionEmployeesRefs {
    final manager = $$PosSessionEmployeesTableTableManager(
            $_db, $_db.posSessionEmployees)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_posSessionEmployeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName: $_aliasNameGenerator(
              db.posSessions.id, db.sales.terminalSessionId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales).filter(
        (f) => f.terminalSessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IpvReportsTable, List<IpvReport>>
      _ipvReportsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.ipvReports,
          aliasName:
              $_aliasNameGenerator(db.posSessions.id, db.ipvReports.sessionId));

  $$IpvReportsTableProcessedTableManager get ipvReportsRefs {
    final manager = $$IpvReportsTableTableManager($_db, $_db.ipvReports)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ipvReportsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PosSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PosSessionsTable> {
  $$PosSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingFloatCents => $composableBuilder(
      column: $table.openingFloatCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get closingCashCents => $composableBuilder(
      column: $table.closingCashCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$PosTerminalsTableFilterComposer get terminalId {
    final $$PosTerminalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableFilterComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> posSessionCashBreakdownsRefs(
      Expression<bool> Function($$PosSessionCashBreakdownsTableFilterComposer f)
          f) {
    final $$PosSessionCashBreakdownsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.posSessionCashBreakdowns,
            getReferencedColumn: (t) => t.sessionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PosSessionCashBreakdownsTableFilterComposer(
                  $db: $db,
                  $table: $db.posSessionCashBreakdowns,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> posSessionEmployeesRefs(
      Expression<bool> Function($$PosSessionEmployeesTableFilterComposer f) f) {
    final $$PosSessionEmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posSessionEmployees,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionEmployeesTableFilterComposer(
              $db: $db,
              $table: $db.posSessionEmployees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.terminalSessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ipvReportsRefs(
      Expression<bool> Function($$IpvReportsTableFilterComposer f) f) {
    final $$IpvReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableFilterComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PosSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PosSessionsTable> {
  $$PosSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingFloatCents => $composableBuilder(
      column: $table.openingFloatCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get closingCashCents => $composableBuilder(
      column: $table.closingCashCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$PosTerminalsTableOrderingComposer get terminalId {
    final $$PosTerminalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableOrderingComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PosSessionsTable> {
  $$PosSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<int> get openingFloatCents => $composableBuilder(
      column: $table.openingFloatCents, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get closingCashCents => $composableBuilder(
      column: $table.closingCashCents, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$PosTerminalsTableAnnotationComposer get terminalId {
    final $$PosTerminalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableAnnotationComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> posSessionCashBreakdownsRefs<T extends Object>(
      Expression<T> Function(
              $$PosSessionCashBreakdownsTableAnnotationComposer a)
          f) {
    final $$PosSessionCashBreakdownsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.posSessionCashBreakdowns,
            getReferencedColumn: (t) => t.sessionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PosSessionCashBreakdownsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.posSessionCashBreakdowns,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> posSessionEmployeesRefs<T extends Object>(
      Expression<T> Function($$PosSessionEmployeesTableAnnotationComposer a)
          f) {
    final $$PosSessionEmployeesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.posSessionEmployees,
            getReferencedColumn: (t) => t.sessionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PosSessionEmployeesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.posSessionEmployees,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.terminalSessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ipvReportsRefs<T extends Object>(
      Expression<T> Function($$IpvReportsTableAnnotationComposer a) f) {
    final $$IpvReportsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PosSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PosSessionsTable,
    PosSession,
    $$PosSessionsTableFilterComposer,
    $$PosSessionsTableOrderingComposer,
    $$PosSessionsTableAnnotationComposer,
    $$PosSessionsTableCreateCompanionBuilder,
    $$PosSessionsTableUpdateCompanionBuilder,
    (PosSession, $$PosSessionsTableReferences),
    PosSession,
    PrefetchHooks Function(
        {bool terminalId,
        bool userId,
        bool posSessionCashBreakdownsRefs,
        bool posSessionEmployeesRefs,
        bool salesRefs,
        bool ipvReportsRefs})> {
  $$PosSessionsTableTableManager(_$AppDatabase db, $PosSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PosSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PosSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PosSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> terminalId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<int> openingFloatCents = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<int?> closingCashCents = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosSessionsCompanion(
            id: id,
            terminalId: terminalId,
            userId: userId,
            openedAt: openedAt,
            openingFloatCents: openingFloatCents,
            closedAt: closedAt,
            closingCashCents: closingCashCents,
            status: status,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String terminalId,
            required String userId,
            Value<DateTime> openedAt = const Value.absent(),
            Value<int> openingFloatCents = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<int?> closingCashCents = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosSessionsCompanion.insert(
            id: id,
            terminalId: terminalId,
            userId: userId,
            openedAt: openedAt,
            openingFloatCents: openingFloatCents,
            closedAt: closedAt,
            closingCashCents: closingCashCents,
            status: status,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PosSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {terminalId = false,
              userId = false,
              posSessionCashBreakdownsRefs = false,
              posSessionEmployeesRefs = false,
              salesRefs = false,
              ipvReportsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (posSessionCashBreakdownsRefs) db.posSessionCashBreakdowns,
                if (posSessionEmployeesRefs) db.posSessionEmployees,
                if (salesRefs) db.sales,
                if (ipvReportsRefs) db.ipvReports
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (terminalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.terminalId,
                    referencedTable:
                        $$PosSessionsTableReferences._terminalIdTable(db),
                    referencedColumn:
                        $$PosSessionsTableReferences._terminalIdTable(db).id,
                  ) as T;
                }
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$PosSessionsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$PosSessionsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (posSessionCashBreakdownsRefs)
                    await $_getPrefetchedData<PosSession, $PosSessionsTable,
                            PosSessionCashBreakdown>(
                        currentTable: table,
                        referencedTable: $$PosSessionsTableReferences
                            ._posSessionCashBreakdownsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosSessionsTableReferences(db, table, p0)
                                .posSessionCashBreakdownsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items),
                  if (posSessionEmployeesRefs)
                    await $_getPrefetchedData<PosSession, $PosSessionsTable, PosSessionEmployee>(
                        currentTable: table,
                        referencedTable: $$PosSessionsTableReferences
                            ._posSessionEmployeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosSessionsTableReferences(db, table, p0)
                                .posSessionEmployeesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items),
                  if (salesRefs)
                    await $_getPrefetchedData<PosSession, $PosSessionsTable,
                            Sale>(
                        currentTable: table,
                        referencedTable:
                            $$PosSessionsTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosSessionsTableReferences(db, table, p0)
                                .salesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.terminalSessionId == item.id),
                        typedResults: items),
                  if (ipvReportsRefs)
                    await $_getPrefetchedData<PosSession, $PosSessionsTable,
                            IpvReport>(
                        currentTable: table,
                        referencedTable: $$PosSessionsTableReferences
                            ._ipvReportsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PosSessionsTableReferences(db, table, p0)
                                .ipvReportsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PosSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PosSessionsTable,
    PosSession,
    $$PosSessionsTableFilterComposer,
    $$PosSessionsTableOrderingComposer,
    $$PosSessionsTableAnnotationComposer,
    $$PosSessionsTableCreateCompanionBuilder,
    $$PosSessionsTableUpdateCompanionBuilder,
    (PosSession, $$PosSessionsTableReferences),
    PosSession,
    PrefetchHooks Function(
        {bool terminalId,
        bool userId,
        bool posSessionCashBreakdownsRefs,
        bool posSessionEmployeesRefs,
        bool salesRefs,
        bool ipvReportsRefs})>;
typedef $$PosSessionCashBreakdownsTableCreateCompanionBuilder
    = PosSessionCashBreakdownsCompanion Function({
  required String sessionId,
  required int denominationCents,
  Value<int> unitCount,
  Value<int> subtotalCents,
  Value<int> rowid,
});
typedef $$PosSessionCashBreakdownsTableUpdateCompanionBuilder
    = PosSessionCashBreakdownsCompanion Function({
  Value<String> sessionId,
  Value<int> denominationCents,
  Value<int> unitCount,
  Value<int> subtotalCents,
  Value<int> rowid,
});

final class $$PosSessionCashBreakdownsTableReferences extends BaseReferences<
    _$AppDatabase, $PosSessionCashBreakdownsTable, PosSessionCashBreakdown> {
  $$PosSessionCashBreakdownsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PosSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.posSessions.createAlias($_aliasNameGenerator(
          db.posSessionCashBreakdowns.sessionId, db.posSessions.id));

  $$PosSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$PosSessionsTableTableManager($_db, $_db.posSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PosSessionCashBreakdownsTableFilterComposer
    extends Composer<_$AppDatabase, $PosSessionCashBreakdownsTable> {
  $$PosSessionCashBreakdownsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get denominationCents => $composableBuilder(
      column: $table.denominationCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitCount => $composableBuilder(
      column: $table.unitCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents, builder: (column) => ColumnFilters(column));

  $$PosSessionsTableFilterComposer get sessionId {
    final $$PosSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableFilterComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosSessionCashBreakdownsTableOrderingComposer
    extends Composer<_$AppDatabase, $PosSessionCashBreakdownsTable> {
  $$PosSessionCashBreakdownsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get denominationCents => $composableBuilder(
      column: $table.denominationCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitCount => $composableBuilder(
      column: $table.unitCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents,
      builder: (column) => ColumnOrderings(column));

  $$PosSessionsTableOrderingComposer get sessionId {
    final $$PosSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosSessionCashBreakdownsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PosSessionCashBreakdownsTable> {
  $$PosSessionCashBreakdownsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get denominationCents => $composableBuilder(
      column: $table.denominationCents, builder: (column) => column);

  GeneratedColumn<int> get unitCount =>
      $composableBuilder(column: $table.unitCount, builder: (column) => column);

  GeneratedColumn<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents, builder: (column) => column);

  $$PosSessionsTableAnnotationComposer get sessionId {
    final $$PosSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosSessionCashBreakdownsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PosSessionCashBreakdownsTable,
    PosSessionCashBreakdown,
    $$PosSessionCashBreakdownsTableFilterComposer,
    $$PosSessionCashBreakdownsTableOrderingComposer,
    $$PosSessionCashBreakdownsTableAnnotationComposer,
    $$PosSessionCashBreakdownsTableCreateCompanionBuilder,
    $$PosSessionCashBreakdownsTableUpdateCompanionBuilder,
    (PosSessionCashBreakdown, $$PosSessionCashBreakdownsTableReferences),
    PosSessionCashBreakdown,
    PrefetchHooks Function({bool sessionId})> {
  $$PosSessionCashBreakdownsTableTableManager(
      _$AppDatabase db, $PosSessionCashBreakdownsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PosSessionCashBreakdownsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PosSessionCashBreakdownsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PosSessionCashBreakdownsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sessionId = const Value.absent(),
            Value<int> denominationCents = const Value.absent(),
            Value<int> unitCount = const Value.absent(),
            Value<int> subtotalCents = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosSessionCashBreakdownsCompanion(
            sessionId: sessionId,
            denominationCents: denominationCents,
            unitCount: unitCount,
            subtotalCents: subtotalCents,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sessionId,
            required int denominationCents,
            Value<int> unitCount = const Value.absent(),
            Value<int> subtotalCents = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosSessionCashBreakdownsCompanion.insert(
            sessionId: sessionId,
            denominationCents: denominationCents,
            unitCount: unitCount,
            subtotalCents: subtotalCents,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PosSessionCashBreakdownsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable: $$PosSessionCashBreakdownsTableReferences
                        ._sessionIdTable(db),
                    referencedColumn: $$PosSessionCashBreakdownsTableReferences
                        ._sessionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PosSessionCashBreakdownsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PosSessionCashBreakdownsTable,
        PosSessionCashBreakdown,
        $$PosSessionCashBreakdownsTableFilterComposer,
        $$PosSessionCashBreakdownsTableOrderingComposer,
        $$PosSessionCashBreakdownsTableAnnotationComposer,
        $$PosSessionCashBreakdownsTableCreateCompanionBuilder,
        $$PosSessionCashBreakdownsTableUpdateCompanionBuilder,
        (PosSessionCashBreakdown, $$PosSessionCashBreakdownsTableReferences),
        PosSessionCashBreakdown,
        PrefetchHooks Function({bool sessionId})>;
typedef $$EmployeesTableCreateCompanionBuilder = EmployeesCompanion Function({
  required String id,
  required String code,
  required String name,
  Value<String?> sex,
  Value<String?> identityNumber,
  Value<String?> address,
  Value<String?> imagePath,
  Value<String?> associatedUserId,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$EmployeesTableUpdateCompanionBuilder = EmployeesCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> name,
  Value<String?> sex,
  Value<String?> identityNumber,
  Value<String?> address,
  Value<String?> imagePath,
  Value<String?> associatedUserId,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

final class $$EmployeesTableReferences
    extends BaseReferences<_$AppDatabase, $EmployeesTable, Employee> {
  $$EmployeesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _associatedUserIdTable(_$AppDatabase db) =>
      db.users.createAlias(
          $_aliasNameGenerator(db.employees.associatedUserId, db.users.id));

  $$UsersTableProcessedTableManager? get associatedUserId {
    final $_column = $_itemColumn<String>('associated_user_id');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_associatedUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PosSessionEmployeesTable,
      List<PosSessionEmployee>> _posSessionEmployeesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.posSessionEmployees,
          aliasName: $_aliasNameGenerator(
              db.employees.id, db.posSessionEmployees.employeeId));

  $$PosSessionEmployeesTableProcessedTableManager get posSessionEmployeesRefs {
    final manager = $$PosSessionEmployeesTableTableManager(
            $_db, $_db.posSessionEmployees)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_posSessionEmployeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PosTerminalEmployeesTable,
      List<PosTerminalEmployee>> _posTerminalEmployeesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.posTerminalEmployees,
          aliasName: $_aliasNameGenerator(
              db.employees.id, db.posTerminalEmployees.employeeId));

  $$PosTerminalEmployeesTableProcessedTableManager
      get posTerminalEmployeesRefs {
    final manager = $$PosTerminalEmployeesTableTableManager(
            $_db, $_db.posTerminalEmployees)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_posTerminalEmployeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identityNumber => $composableBuilder(
      column: $table.identityNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get associatedUserId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.associatedUserId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> posSessionEmployeesRefs(
      Expression<bool> Function($$PosSessionEmployeesTableFilterComposer f) f) {
    final $$PosSessionEmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posSessionEmployees,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionEmployeesTableFilterComposer(
              $db: $db,
              $table: $db.posSessionEmployees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> posTerminalEmployeesRefs(
      Expression<bool> Function($$PosTerminalEmployeesTableFilterComposer f)
          f) {
    final $$PosTerminalEmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.posTerminalEmployees,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalEmployeesTableFilterComposer(
              $db: $db,
              $table: $db.posTerminalEmployees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identityNumber => $composableBuilder(
      column: $table.identityNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get associatedUserId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.associatedUserId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get identityNumber => $composableBuilder(
      column: $table.identityNumber, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get associatedUserId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.associatedUserId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> posSessionEmployeesRefs<T extends Object>(
      Expression<T> Function($$PosSessionEmployeesTableAnnotationComposer a)
          f) {
    final $$PosSessionEmployeesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.posSessionEmployees,
            getReferencedColumn: (t) => t.employeeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PosSessionEmployeesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.posSessionEmployees,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> posTerminalEmployeesRefs<T extends Object>(
      Expression<T> Function($$PosTerminalEmployeesTableAnnotationComposer a)
          f) {
    final $$PosTerminalEmployeesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.posTerminalEmployees,
            getReferencedColumn: (t) => t.employeeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PosTerminalEmployeesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.posTerminalEmployees,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$EmployeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeesTable,
    Employee,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (Employee, $$EmployeesTableReferences),
    Employee,
    PrefetchHooks Function(
        {bool associatedUserId,
        bool posSessionEmployeesRefs,
        bool posTerminalEmployeesRefs})> {
  $$EmployeesTableTableManager(_$AppDatabase db, $EmployeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> sex = const Value.absent(),
            Value<String?> identityNumber = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> associatedUserId = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmployeesCompanion(
            id: id,
            code: code,
            name: name,
            sex: sex,
            identityNumber: identityNumber,
            address: address,
            imagePath: imagePath,
            associatedUserId: associatedUserId,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String code,
            required String name,
            Value<String?> sex = const Value.absent(),
            Value<String?> identityNumber = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> associatedUserId = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmployeesCompanion.insert(
            id: id,
            code: code,
            name: name,
            sex: sex,
            identityNumber: identityNumber,
            address: address,
            imagePath: imagePath,
            associatedUserId: associatedUserId,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EmployeesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {associatedUserId = false,
              posSessionEmployeesRefs = false,
              posTerminalEmployeesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (posSessionEmployeesRefs) db.posSessionEmployees,
                if (posTerminalEmployeesRefs) db.posTerminalEmployees
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (associatedUserId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.associatedUserId,
                    referencedTable:
                        $$EmployeesTableReferences._associatedUserIdTable(db),
                    referencedColumn: $$EmployeesTableReferences
                        ._associatedUserIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (posSessionEmployeesRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            PosSessionEmployee>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._posSessionEmployeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .posSessionEmployeesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (posTerminalEmployeesRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            PosTerminalEmployee>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._posTerminalEmployeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .posTerminalEmployeesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EmployeesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmployeesTable,
    Employee,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (Employee, $$EmployeesTableReferences),
    Employee,
    PrefetchHooks Function(
        {bool associatedUserId,
        bool posSessionEmployeesRefs,
        bool posTerminalEmployeesRefs})>;
typedef $$PosSessionEmployeesTableCreateCompanionBuilder
    = PosSessionEmployeesCompanion Function({
  required String sessionId,
  required String employeeId,
  Value<DateTime> assignedAt,
  Value<int> rowid,
});
typedef $$PosSessionEmployeesTableUpdateCompanionBuilder
    = PosSessionEmployeesCompanion Function({
  Value<String> sessionId,
  Value<String> employeeId,
  Value<DateTime> assignedAt,
  Value<int> rowid,
});

final class $$PosSessionEmployeesTableReferences extends BaseReferences<
    _$AppDatabase, $PosSessionEmployeesTable, PosSessionEmployee> {
  $$PosSessionEmployeesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PosSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.posSessions.createAlias($_aliasNameGenerator(
          db.posSessionEmployees.sessionId, db.posSessions.id));

  $$PosSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$PosSessionsTableTableManager($_db, $_db.posSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias($_aliasNameGenerator(
          db.posSessionEmployees.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<String>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PosSessionEmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $PosSessionEmployeesTable> {
  $$PosSessionEmployeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => ColumnFilters(column));

  $$PosSessionsTableFilterComposer get sessionId {
    final $$PosSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableFilterComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosSessionEmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $PosSessionEmployeesTable> {
  $$PosSessionEmployeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => ColumnOrderings(column));

  $$PosSessionsTableOrderingComposer get sessionId {
    final $$PosSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosSessionEmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PosSessionEmployeesTable> {
  $$PosSessionEmployeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => column);

  $$PosSessionsTableAnnotationComposer get sessionId {
    final $$PosSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosSessionEmployeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PosSessionEmployeesTable,
    PosSessionEmployee,
    $$PosSessionEmployeesTableFilterComposer,
    $$PosSessionEmployeesTableOrderingComposer,
    $$PosSessionEmployeesTableAnnotationComposer,
    $$PosSessionEmployeesTableCreateCompanionBuilder,
    $$PosSessionEmployeesTableUpdateCompanionBuilder,
    (PosSessionEmployee, $$PosSessionEmployeesTableReferences),
    PosSessionEmployee,
    PrefetchHooks Function({bool sessionId, bool employeeId})> {
  $$PosSessionEmployeesTableTableManager(
      _$AppDatabase db, $PosSessionEmployeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PosSessionEmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PosSessionEmployeesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PosSessionEmployeesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sessionId = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<DateTime> assignedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosSessionEmployeesCompanion(
            sessionId: sessionId,
            employeeId: employeeId,
            assignedAt: assignedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sessionId,
            required String employeeId,
            Value<DateTime> assignedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosSessionEmployeesCompanion.insert(
            sessionId: sessionId,
            employeeId: employeeId,
            assignedAt: assignedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PosSessionEmployeesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false, employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable: $$PosSessionEmployeesTableReferences
                        ._sessionIdTable(db),
                    referencedColumn: $$PosSessionEmployeesTableReferences
                        ._sessionIdTable(db)
                        .id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable: $$PosSessionEmployeesTableReferences
                        ._employeeIdTable(db),
                    referencedColumn: $$PosSessionEmployeesTableReferences
                        ._employeeIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PosSessionEmployeesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PosSessionEmployeesTable,
    PosSessionEmployee,
    $$PosSessionEmployeesTableFilterComposer,
    $$PosSessionEmployeesTableOrderingComposer,
    $$PosSessionEmployeesTableAnnotationComposer,
    $$PosSessionEmployeesTableCreateCompanionBuilder,
    $$PosSessionEmployeesTableUpdateCompanionBuilder,
    (PosSessionEmployee, $$PosSessionEmployeesTableReferences),
    PosSessionEmployee,
    PrefetchHooks Function({bool sessionId, bool employeeId})>;
typedef $$PosTerminalEmployeesTableCreateCompanionBuilder
    = PosTerminalEmployeesCompanion Function({
  required String terminalId,
  required String employeeId,
  Value<DateTime> assignedAt,
  Value<int> rowid,
});
typedef $$PosTerminalEmployeesTableUpdateCompanionBuilder
    = PosTerminalEmployeesCompanion Function({
  Value<String> terminalId,
  Value<String> employeeId,
  Value<DateTime> assignedAt,
  Value<int> rowid,
});

final class $$PosTerminalEmployeesTableReferences extends BaseReferences<
    _$AppDatabase, $PosTerminalEmployeesTable, PosTerminalEmployee> {
  $$PosTerminalEmployeesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PosTerminalsTable _terminalIdTable(_$AppDatabase db) =>
      db.posTerminals.createAlias($_aliasNameGenerator(
          db.posTerminalEmployees.terminalId, db.posTerminals.id));

  $$PosTerminalsTableProcessedTableManager get terminalId {
    final $_column = $_itemColumn<String>('terminal_id')!;

    final manager = $$PosTerminalsTableTableManager($_db, $_db.posTerminals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_terminalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias($_aliasNameGenerator(
          db.posTerminalEmployees.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<String>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PosTerminalEmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $PosTerminalEmployeesTable> {
  $$PosTerminalEmployeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => ColumnFilters(column));

  $$PosTerminalsTableFilterComposer get terminalId {
    final $$PosTerminalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableFilterComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosTerminalEmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $PosTerminalEmployeesTable> {
  $$PosTerminalEmployeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => ColumnOrderings(column));

  $$PosTerminalsTableOrderingComposer get terminalId {
    final $$PosTerminalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableOrderingComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosTerminalEmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PosTerminalEmployeesTable> {
  $$PosTerminalEmployeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get assignedAt => $composableBuilder(
      column: $table.assignedAt, builder: (column) => column);

  $$PosTerminalsTableAnnotationComposer get terminalId {
    final $$PosTerminalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableAnnotationComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PosTerminalEmployeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PosTerminalEmployeesTable,
    PosTerminalEmployee,
    $$PosTerminalEmployeesTableFilterComposer,
    $$PosTerminalEmployeesTableOrderingComposer,
    $$PosTerminalEmployeesTableAnnotationComposer,
    $$PosTerminalEmployeesTableCreateCompanionBuilder,
    $$PosTerminalEmployeesTableUpdateCompanionBuilder,
    (PosTerminalEmployee, $$PosTerminalEmployeesTableReferences),
    PosTerminalEmployee,
    PrefetchHooks Function({bool terminalId, bool employeeId})> {
  $$PosTerminalEmployeesTableTableManager(
      _$AppDatabase db, $PosTerminalEmployeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PosTerminalEmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PosTerminalEmployeesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PosTerminalEmployeesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> terminalId = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<DateTime> assignedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosTerminalEmployeesCompanion(
            terminalId: terminalId,
            employeeId: employeeId,
            assignedAt: assignedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String terminalId,
            required String employeeId,
            Value<DateTime> assignedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PosTerminalEmployeesCompanion.insert(
            terminalId: terminalId,
            employeeId: employeeId,
            assignedAt: assignedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PosTerminalEmployeesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({terminalId = false, employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (terminalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.terminalId,
                    referencedTable: $$PosTerminalEmployeesTableReferences
                        ._terminalIdTable(db),
                    referencedColumn: $$PosTerminalEmployeesTableReferences
                        ._terminalIdTable(db)
                        .id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable: $$PosTerminalEmployeesTableReferences
                        ._employeeIdTable(db),
                    referencedColumn: $$PosTerminalEmployeesTableReferences
                        ._employeeIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PosTerminalEmployeesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PosTerminalEmployeesTable,
        PosTerminalEmployee,
        $$PosTerminalEmployeesTableFilterComposer,
        $$PosTerminalEmployeesTableOrderingComposer,
        $$PosTerminalEmployeesTableAnnotationComposer,
        $$PosTerminalEmployeesTableCreateCompanionBuilder,
        $$PosTerminalEmployeesTableUpdateCompanionBuilder,
        (PosTerminalEmployee, $$PosTerminalEmployeesTableReferences),
        PosTerminalEmployee,
        PrefetchHooks Function({bool terminalId, bool employeeId})>;
typedef $$StockBalancesTableCreateCompanionBuilder = StockBalancesCompanion
    Function({
  required String productId,
  required String warehouseId,
  Value<double> qty,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$StockBalancesTableUpdateCompanionBuilder = StockBalancesCompanion
    Function({
  Value<String> productId,
  Value<String> warehouseId,
  Value<double> qty,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$StockBalancesTableReferences
    extends BaseReferences<_$AppDatabase, $StockBalancesTable, StockBalance> {
  $$StockBalancesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.stockBalances.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WarehousesTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehouses.createAlias(
          $_aliasNameGenerator(db.stockBalances.warehouseId, db.warehouses.id));

  $$WarehousesTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableManager($_db, $_db.warehouses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StockBalancesTableFilterComposer
    extends Composer<_$AppDatabase, $StockBalancesTable> {
  $$StockBalancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableFilterComposer get warehouseId {
    final $$WarehousesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableFilterComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockBalancesTableOrderingComposer
    extends Composer<_$AppDatabase, $StockBalancesTable> {
  $$StockBalancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableOrderingComposer get warehouseId {
    final $$WarehousesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableOrderingComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockBalancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockBalancesTable> {
  $$StockBalancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableAnnotationComposer get warehouseId {
    final $$WarehousesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableAnnotationComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockBalancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StockBalancesTable,
    StockBalance,
    $$StockBalancesTableFilterComposer,
    $$StockBalancesTableOrderingComposer,
    $$StockBalancesTableAnnotationComposer,
    $$StockBalancesTableCreateCompanionBuilder,
    $$StockBalancesTableUpdateCompanionBuilder,
    (StockBalance, $$StockBalancesTableReferences),
    StockBalance,
    PrefetchHooks Function({bool productId, bool warehouseId})> {
  $$StockBalancesTableTableManager(_$AppDatabase db, $StockBalancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockBalancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockBalancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockBalancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> productId = const Value.absent(),
            Value<String> warehouseId = const Value.absent(),
            Value<double> qty = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StockBalancesCompanion(
            productId: productId,
            warehouseId: warehouseId,
            qty: qty,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String productId,
            required String warehouseId,
            Value<double> qty = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StockBalancesCompanion.insert(
            productId: productId,
            warehouseId: warehouseId,
            qty: qty,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockBalancesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false, warehouseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$StockBalancesTableReferences._productIdTable(db),
                    referencedColumn:
                        $$StockBalancesTableReferences._productIdTable(db).id,
                  ) as T;
                }
                if (warehouseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.warehouseId,
                    referencedTable:
                        $$StockBalancesTableReferences._warehouseIdTable(db),
                    referencedColumn:
                        $$StockBalancesTableReferences._warehouseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StockBalancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StockBalancesTable,
    StockBalance,
    $$StockBalancesTableFilterComposer,
    $$StockBalancesTableOrderingComposer,
    $$StockBalancesTableAnnotationComposer,
    $$StockBalancesTableCreateCompanionBuilder,
    $$StockBalancesTableUpdateCompanionBuilder,
    (StockBalance, $$StockBalancesTableReferences),
    StockBalance,
    PrefetchHooks Function({bool productId, bool warehouseId})>;
typedef $$StockMovementsTableCreateCompanionBuilder = StockMovementsCompanion
    Function({
  required String id,
  required String productId,
  required String warehouseId,
  required String type,
  required double qty,
  Value<String?> reasonCode,
  Value<String> movementSource,
  Value<String?> refType,
  Value<String?> refId,
  Value<String?> note,
  Value<bool> isVoided,
  Value<DateTime?> voidedAt,
  Value<String?> voidedBy,
  Value<String?> voidNote,
  required String createdBy,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$StockMovementsTableUpdateCompanionBuilder = StockMovementsCompanion
    Function({
  Value<String> id,
  Value<String> productId,
  Value<String> warehouseId,
  Value<String> type,
  Value<double> qty,
  Value<String?> reasonCode,
  Value<String> movementSource,
  Value<String?> refType,
  Value<String?> refId,
  Value<String?> note,
  Value<bool> isVoided,
  Value<DateTime?> voidedAt,
  Value<String?> voidedBy,
  Value<String?> voidNote,
  Value<String> createdBy,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$StockMovementsTableReferences
    extends BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovement> {
  $$StockMovementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.stockMovements.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WarehousesTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehouses.createAlias($_aliasNameGenerator(
          db.stockMovements.warehouseId, db.warehouses.id));

  $$WarehousesTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableManager($_db, $_db.warehouses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _voidedByTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.stockMovements.voidedBy, db.users.id));

  $$UsersTableProcessedTableManager? get voidedBy {
    final $_column = $_itemColumn<String>('voided_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_voidedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _createdByTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.stockMovements.createdBy, db.users.id));

  $$UsersTableProcessedTableManager get createdBy {
    final $_column = $_itemColumn<String>('created_by')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movementSource => $composableBuilder(
      column: $table.movementSource,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refType => $composableBuilder(
      column: $table.refType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refId => $composableBuilder(
      column: $table.refId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVoided => $composableBuilder(
      column: $table.isVoided, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
      column: $table.voidedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get voidNote => $composableBuilder(
      column: $table.voidNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableFilterComposer get warehouseId {
    final $$WarehousesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableFilterComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get voidedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.voidedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get createdBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movementSource => $composableBuilder(
      column: $table.movementSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refType => $composableBuilder(
      column: $table.refType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refId => $composableBuilder(
      column: $table.refId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVoided => $composableBuilder(
      column: $table.isVoided, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
      column: $table.voidedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voidNote => $composableBuilder(
      column: $table.voidNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableOrderingComposer get warehouseId {
    final $$WarehousesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableOrderingComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get voidedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.voidedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get createdBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => column);

  GeneratedColumn<String> get movementSource => $composableBuilder(
      column: $table.movementSource, builder: (column) => column);

  GeneratedColumn<String> get refType =>
      $composableBuilder(column: $table.refType, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isVoided =>
      $composableBuilder(column: $table.isVoided, builder: (column) => column);

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<String> get voidNote =>
      $composableBuilder(column: $table.voidNote, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableAnnotationComposer get warehouseId {
    final $$WarehousesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableAnnotationComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get voidedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.voidedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get createdBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StockMovementsTable,
    StockMovement,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (StockMovement, $$StockMovementsTableReferences),
    StockMovement,
    PrefetchHooks Function(
        {bool productId, bool warehouseId, bool voidedBy, bool createdBy})> {
  $$StockMovementsTableTableManager(
      _$AppDatabase db, $StockMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> warehouseId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> qty = const Value.absent(),
            Value<String?> reasonCode = const Value.absent(),
            Value<String> movementSource = const Value.absent(),
            Value<String?> refType = const Value.absent(),
            Value<String?> refId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> isVoided = const Value.absent(),
            Value<DateTime?> voidedAt = const Value.absent(),
            Value<String?> voidedBy = const Value.absent(),
            Value<String?> voidNote = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StockMovementsCompanion(
            id: id,
            productId: productId,
            warehouseId: warehouseId,
            type: type,
            qty: qty,
            reasonCode: reasonCode,
            movementSource: movementSource,
            refType: refType,
            refId: refId,
            note: note,
            isVoided: isVoided,
            voidedAt: voidedAt,
            voidedBy: voidedBy,
            voidNote: voidNote,
            createdBy: createdBy,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String productId,
            required String warehouseId,
            required String type,
            required double qty,
            Value<String?> reasonCode = const Value.absent(),
            Value<String> movementSource = const Value.absent(),
            Value<String?> refType = const Value.absent(),
            Value<String?> refId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> isVoided = const Value.absent(),
            Value<DateTime?> voidedAt = const Value.absent(),
            Value<String?> voidedBy = const Value.absent(),
            Value<String?> voidNote = const Value.absent(),
            required String createdBy,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StockMovementsCompanion.insert(
            id: id,
            productId: productId,
            warehouseId: warehouseId,
            type: type,
            qty: qty,
            reasonCode: reasonCode,
            movementSource: movementSource,
            refType: refType,
            refId: refId,
            note: note,
            isVoided: isVoided,
            voidedAt: voidedAt,
            voidedBy: voidedBy,
            voidNote: voidNote,
            createdBy: createdBy,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockMovementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {productId = false,
              warehouseId = false,
              voidedBy = false,
              createdBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$StockMovementsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$StockMovementsTableReferences._productIdTable(db).id,
                  ) as T;
                }
                if (warehouseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.warehouseId,
                    referencedTable:
                        $$StockMovementsTableReferences._warehouseIdTable(db),
                    referencedColumn: $$StockMovementsTableReferences
                        ._warehouseIdTable(db)
                        .id,
                  ) as T;
                }
                if (voidedBy) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.voidedBy,
                    referencedTable:
                        $$StockMovementsTableReferences._voidedByTable(db),
                    referencedColumn:
                        $$StockMovementsTableReferences._voidedByTable(db).id,
                  ) as T;
                }
                if (createdBy) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.createdBy,
                    referencedTable:
                        $$StockMovementsTableReferences._createdByTable(db),
                    referencedColumn:
                        $$StockMovementsTableReferences._createdByTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StockMovementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StockMovementsTable,
    StockMovement,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (StockMovement, $$StockMovementsTableReferences),
    StockMovement,
    PrefetchHooks Function(
        {bool productId, bool warehouseId, bool voidedBy, bool createdBy})>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String code,
  required String fullName,
  Value<String?> identityNumber,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> company,
  Value<String?> avatarPath,
  Value<String> customerType,
  Value<bool> isVip,
  Value<int> creditAvailableCents,
  Value<int> discountBps,
  Value<String?> adminNote,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> fullName,
  Value<String?> identityNumber,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> company,
  Value<String?> avatarPath,
  Value<String> customerType,
  Value<bool> isVip,
  Value<int> creditAvailableCents,
  Value<int> discountBps,
  Value<String?> adminNote,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

final class $$CustomersTableReferences
    extends BaseReferences<_$AppDatabase, $CustomersTable, Customer> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName:
              $_aliasNameGenerator(db.customers.id, db.sales.customerId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.customerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identityNumber => $composableBuilder(
      column: $table.identityNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerType => $composableBuilder(
      column: $table.customerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVip => $composableBuilder(
      column: $table.isVip, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get creditAvailableCents => $composableBuilder(
      column: $table.creditAvailableCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discountBps => $composableBuilder(
      column: $table.discountBps, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get adminNote => $composableBuilder(
      column: $table.adminNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identityNumber => $composableBuilder(
      column: $table.identityNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerType => $composableBuilder(
      column: $table.customerType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVip => $composableBuilder(
      column: $table.isVip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get creditAvailableCents => $composableBuilder(
      column: $table.creditAvailableCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discountBps => $composableBuilder(
      column: $table.discountBps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get adminNote => $composableBuilder(
      column: $table.adminNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get identityNumber => $composableBuilder(
      column: $table.identityNumber, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => column);

  GeneratedColumn<String> get customerType => $composableBuilder(
      column: $table.customerType, builder: (column) => column);

  GeneratedColumn<bool> get isVip =>
      $composableBuilder(column: $table.isVip, builder: (column) => column);

  GeneratedColumn<int> get creditAvailableCents => $composableBuilder(
      column: $table.creditAvailableCents, builder: (column) => column);

  GeneratedColumn<int> get discountBps => $composableBuilder(
      column: $table.discountBps, builder: (column) => column);

  GeneratedColumn<String> get adminNote =>
      $composableBuilder(column: $table.adminNote, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, $$CustomersTableReferences),
    Customer,
    PrefetchHooks Function({bool salesRefs})> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String?> identityNumber = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<String> customerType = const Value.absent(),
            Value<bool> isVip = const Value.absent(),
            Value<int> creditAvailableCents = const Value.absent(),
            Value<int> discountBps = const Value.absent(),
            Value<String?> adminNote = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            code: code,
            fullName: fullName,
            identityNumber: identityNumber,
            phone: phone,
            email: email,
            address: address,
            company: company,
            avatarPath: avatarPath,
            customerType: customerType,
            isVip: isVip,
            creditAvailableCents: creditAvailableCents,
            discountBps: discountBps,
            adminNote: adminNote,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String code,
            required String fullName,
            Value<String?> identityNumber = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<String> customerType = const Value.absent(),
            Value<bool> isVip = const Value.absent(),
            Value<int> creditAvailableCents = const Value.absent(),
            Value<int> discountBps = const Value.absent(),
            Value<String?> adminNote = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            code: code,
            fullName: fullName,
            identityNumber: identityNumber,
            phone: phone,
            email: email,
            address: address,
            company: company,
            avatarPath: avatarPath,
            customerType: customerType,
            isVip: isVip,
            creditAvailableCents: creditAvailableCents,
            discountBps: discountBps,
            adminNote: adminNote,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CustomersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({salesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (salesRefs) db.sales],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (salesRefs)
                    await $_getPrefetchedData<Customer, $CustomersTable, Sale>(
                        currentTable: table,
                        referencedTable:
                            $$CustomersTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CustomersTableReferences(db, table, p0).salesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.customerId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, $$CustomersTableReferences),
    Customer,
    PrefetchHooks Function({bool salesRefs})>;
typedef $$SalesTableCreateCompanionBuilder = SalesCompanion Function({
  required String id,
  required String folio,
  required String warehouseId,
  required String cashierId,
  Value<String?> customerId,
  Value<String?> terminalId,
  Value<String?> terminalSessionId,
  required int subtotalCents,
  required int taxCents,
  required int totalCents,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SalesTableUpdateCompanionBuilder = SalesCompanion Function({
  Value<String> id,
  Value<String> folio,
  Value<String> warehouseId,
  Value<String> cashierId,
  Value<String?> customerId,
  Value<String?> terminalId,
  Value<String?> terminalSessionId,
  Value<int> subtotalCents,
  Value<int> taxCents,
  Value<int> totalCents,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$SalesTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WarehousesTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehouses.createAlias(
          $_aliasNameGenerator(db.sales.warehouseId, db.warehouses.id));

  $$WarehousesTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableManager($_db, $_db.warehouses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _cashierIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.sales.cashierId, db.users.id));

  $$UsersTableProcessedTableManager get cashierId {
    final $_column = $_itemColumn<String>('cashier_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CustomersTable _customerIdTable(_$AppDatabase db) => db.customers
      .createAlias($_aliasNameGenerator(db.sales.customerId, db.customers.id));

  $$CustomersTableProcessedTableManager? get customerId {
    final $_column = $_itemColumn<String>('customer_id');
    if ($_column == null) return null;
    final manager = $$CustomersTableTableManager($_db, $_db.customers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PosTerminalsTable _terminalIdTable(_$AppDatabase db) =>
      db.posTerminals.createAlias(
          $_aliasNameGenerator(db.sales.terminalId, db.posTerminals.id));

  $$PosTerminalsTableProcessedTableManager? get terminalId {
    final $_column = $_itemColumn<String>('terminal_id');
    if ($_column == null) return null;
    final manager = $$PosTerminalsTableTableManager($_db, $_db.posTerminals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_terminalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PosSessionsTable _terminalSessionIdTable(_$AppDatabase db) =>
      db.posSessions.createAlias(
          $_aliasNameGenerator(db.sales.terminalSessionId, db.posSessions.id));

  $$PosSessionsTableProcessedTableManager? get terminalSessionId {
    final $_column = $_itemColumn<String>('terminal_session_id');
    if ($_column == null) return null;
    final manager = $$PosSessionsTableTableManager($_db, $_db.posSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_terminalSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
      _saleItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.saleItems,
          aliasName: $_aliasNameGenerator(db.sales.id, db.saleItems.saleId));

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager($_db, $_db.saleItems)
        .filter((f) => f.saleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.payments,
          aliasName: $_aliasNameGenerator(db.sales.id, db.payments.saleId));

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager($_db, $_db.payments)
        .filter((f) => f.saleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folio => $composableBuilder(
      column: $table.folio, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxCents => $composableBuilder(
      column: $table.taxCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$WarehousesTableFilterComposer get warehouseId {
    final $$WarehousesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableFilterComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get cashierId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashierId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableFilterComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosTerminalsTableFilterComposer get terminalId {
    final $$PosTerminalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableFilterComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosSessionsTableFilterComposer get terminalSessionId {
    final $$PosSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalSessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableFilterComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> saleItemsRefs(
      Expression<bool> Function($$SaleItemsTableFilterComposer f) f) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableFilterComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> paymentsRefs(
      Expression<bool> Function($$PaymentsTableFilterComposer f) f) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableFilterComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folio => $composableBuilder(
      column: $table.folio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxCents => $composableBuilder(
      column: $table.taxCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$WarehousesTableOrderingComposer get warehouseId {
    final $$WarehousesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableOrderingComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get cashierId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashierId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableOrderingComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosTerminalsTableOrderingComposer get terminalId {
    final $$PosTerminalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableOrderingComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosSessionsTableOrderingComposer get terminalSessionId {
    final $$PosSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalSessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folio =>
      $composableBuilder(column: $table.folio, builder: (column) => column);

  GeneratedColumn<int> get subtotalCents => $composableBuilder(
      column: $table.subtotalCents, builder: (column) => column);

  GeneratedColumn<int> get taxCents =>
      $composableBuilder(column: $table.taxCents, builder: (column) => column);

  GeneratedColumn<int> get totalCents => $composableBuilder(
      column: $table.totalCents, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WarehousesTableAnnotationComposer get warehouseId {
    final $$WarehousesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableAnnotationComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get cashierId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashierId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableAnnotationComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosTerminalsTableAnnotationComposer get terminalId {
    final $$PosTerminalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableAnnotationComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosSessionsTableAnnotationComposer get terminalSessionId {
    final $$PosSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalSessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> saleItemsRefs<T extends Object>(
      Expression<T> Function($$SaleItemsTableAnnotationComposer a) f) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
      Expression<T> Function($$PaymentsTableAnnotationComposer a) f) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, $$SalesTableReferences),
    Sale,
    PrefetchHooks Function(
        {bool warehouseId,
        bool cashierId,
        bool customerId,
        bool terminalId,
        bool terminalSessionId,
        bool saleItemsRefs,
        bool paymentsRefs})> {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> folio = const Value.absent(),
            Value<String> warehouseId = const Value.absent(),
            Value<String> cashierId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String?> terminalId = const Value.absent(),
            Value<String?> terminalSessionId = const Value.absent(),
            Value<int> subtotalCents = const Value.absent(),
            Value<int> taxCents = const Value.absent(),
            Value<int> totalCents = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesCompanion(
            id: id,
            folio: folio,
            warehouseId: warehouseId,
            cashierId: cashierId,
            customerId: customerId,
            terminalId: terminalId,
            terminalSessionId: terminalSessionId,
            subtotalCents: subtotalCents,
            taxCents: taxCents,
            totalCents: totalCents,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String folio,
            required String warehouseId,
            required String cashierId,
            Value<String?> customerId = const Value.absent(),
            Value<String?> terminalId = const Value.absent(),
            Value<String?> terminalSessionId = const Value.absent(),
            required int subtotalCents,
            required int taxCents,
            required int totalCents,
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesCompanion.insert(
            id: id,
            folio: folio,
            warehouseId: warehouseId,
            cashierId: cashierId,
            customerId: customerId,
            terminalId: terminalId,
            terminalSessionId: terminalSessionId,
            subtotalCents: subtotalCents,
            taxCents: taxCents,
            totalCents: totalCents,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SalesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {warehouseId = false,
              cashierId = false,
              customerId = false,
              terminalId = false,
              terminalSessionId = false,
              saleItemsRefs = false,
              paymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (saleItemsRefs) db.saleItems,
                if (paymentsRefs) db.payments
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (warehouseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.warehouseId,
                    referencedTable:
                        $$SalesTableReferences._warehouseIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._warehouseIdTable(db).id,
                  ) as T;
                }
                if (cashierId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cashierId,
                    referencedTable: $$SalesTableReferences._cashierIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._cashierIdTable(db).id,
                  ) as T;
                }
                if (customerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.customerId,
                    referencedTable:
                        $$SalesTableReferences._customerIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._customerIdTable(db).id,
                  ) as T;
                }
                if (terminalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.terminalId,
                    referencedTable:
                        $$SalesTableReferences._terminalIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._terminalIdTable(db).id,
                  ) as T;
                }
                if (terminalSessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.terminalSessionId,
                    referencedTable:
                        $$SalesTableReferences._terminalSessionIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._terminalSessionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (saleItemsRefs)
                    await $_getPrefetchedData<Sale, $SalesTable, SaleItem>(
                        currentTable: table,
                        referencedTable:
                            $$SalesTableReferences._saleItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SalesTableReferences(db, table, p0).saleItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.saleId == item.id),
                        typedResults: items),
                  if (paymentsRefs)
                    await $_getPrefetchedData<Sale, $SalesTable, Payment>(
                        currentTable: table,
                        referencedTable:
                            $$SalesTableReferences._paymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SalesTableReferences(db, table, p0).paymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.saleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SalesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, $$SalesTableReferences),
    Sale,
    PrefetchHooks Function(
        {bool warehouseId,
        bool cashierId,
        bool customerId,
        bool terminalId,
        bool terminalSessionId,
        bool saleItemsRefs,
        bool paymentsRefs})>;
typedef $$SaleItemsTableCreateCompanionBuilder = SaleItemsCompanion Function({
  required String id,
  required String saleId,
  required String productId,
  required double qty,
  required int unitPriceCents,
  Value<int> unitCostCents,
  required int taxRateBps,
  required int lineSubtotalCents,
  required int lineTaxCents,
  Value<int> lineCostCents,
  required int lineTotalCents,
  Value<int> rowid,
});
typedef $$SaleItemsTableUpdateCompanionBuilder = SaleItemsCompanion Function({
  Value<String> id,
  Value<String> saleId,
  Value<String> productId,
  Value<double> qty,
  Value<int> unitPriceCents,
  Value<int> unitCostCents,
  Value<int> taxRateBps,
  Value<int> lineSubtotalCents,
  Value<int> lineTaxCents,
  Value<int> lineCostCents,
  Value<int> lineTotalCents,
  Value<int> rowid,
});

final class $$SaleItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SaleItemsTable, SaleItem> {
  $$SaleItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$AppDatabase db) => db.sales
      .createAlias($_aliasNameGenerator(db.saleItems.saleId, db.sales.id));

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.saleItems.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitCostCents => $composableBuilder(
      column: $table.unitCostCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxRateBps => $composableBuilder(
      column: $table.taxRateBps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineSubtotalCents => $composableBuilder(
      column: $table.lineSubtotalCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineTaxCents => $composableBuilder(
      column: $table.lineTaxCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineCostCents => $composableBuilder(
      column: $table.lineCostCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineTotalCents => $composableBuilder(
      column: $table.lineTotalCents,
      builder: (column) => ColumnFilters(column));

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitCostCents => $composableBuilder(
      column: $table.unitCostCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxRateBps => $composableBuilder(
      column: $table.taxRateBps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineSubtotalCents => $composableBuilder(
      column: $table.lineSubtotalCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineTaxCents => $composableBuilder(
      column: $table.lineTaxCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineCostCents => $composableBuilder(
      column: $table.lineCostCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineTotalCents => $composableBuilder(
      column: $table.lineTotalCents,
      builder: (column) => ColumnOrderings(column));

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableOrderingComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents, builder: (column) => column);

  GeneratedColumn<int> get unitCostCents => $composableBuilder(
      column: $table.unitCostCents, builder: (column) => column);

  GeneratedColumn<int> get taxRateBps => $composableBuilder(
      column: $table.taxRateBps, builder: (column) => column);

  GeneratedColumn<int> get lineSubtotalCents => $composableBuilder(
      column: $table.lineSubtotalCents, builder: (column) => column);

  GeneratedColumn<int> get lineTaxCents => $composableBuilder(
      column: $table.lineTaxCents, builder: (column) => column);

  GeneratedColumn<int> get lineCostCents => $composableBuilder(
      column: $table.lineCostCents, builder: (column) => column);

  GeneratedColumn<int> get lineTotalCents => $composableBuilder(
      column: $table.lineTotalCents, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SaleItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SaleItemsTable,
    SaleItem,
    $$SaleItemsTableFilterComposer,
    $$SaleItemsTableOrderingComposer,
    $$SaleItemsTableAnnotationComposer,
    $$SaleItemsTableCreateCompanionBuilder,
    $$SaleItemsTableUpdateCompanionBuilder,
    (SaleItem, $$SaleItemsTableReferences),
    SaleItem,
    PrefetchHooks Function({bool saleId, bool productId})> {
  $$SaleItemsTableTableManager(_$AppDatabase db, $SaleItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> saleId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double> qty = const Value.absent(),
            Value<int> unitPriceCents = const Value.absent(),
            Value<int> unitCostCents = const Value.absent(),
            Value<int> taxRateBps = const Value.absent(),
            Value<int> lineSubtotalCents = const Value.absent(),
            Value<int> lineTaxCents = const Value.absent(),
            Value<int> lineCostCents = const Value.absent(),
            Value<int> lineTotalCents = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SaleItemsCompanion(
            id: id,
            saleId: saleId,
            productId: productId,
            qty: qty,
            unitPriceCents: unitPriceCents,
            unitCostCents: unitCostCents,
            taxRateBps: taxRateBps,
            lineSubtotalCents: lineSubtotalCents,
            lineTaxCents: lineTaxCents,
            lineCostCents: lineCostCents,
            lineTotalCents: lineTotalCents,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String saleId,
            required String productId,
            required double qty,
            required int unitPriceCents,
            Value<int> unitCostCents = const Value.absent(),
            required int taxRateBps,
            required int lineSubtotalCents,
            required int lineTaxCents,
            Value<int> lineCostCents = const Value.absent(),
            required int lineTotalCents,
            Value<int> rowid = const Value.absent(),
          }) =>
              SaleItemsCompanion.insert(
            id: id,
            saleId: saleId,
            productId: productId,
            qty: qty,
            unitPriceCents: unitPriceCents,
            unitCostCents: unitCostCents,
            taxRateBps: taxRateBps,
            lineSubtotalCents: lineSubtotalCents,
            lineTaxCents: lineTaxCents,
            lineCostCents: lineCostCents,
            lineTotalCents: lineTotalCents,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SaleItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({saleId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (saleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.saleId,
                    referencedTable:
                        $$SaleItemsTableReferences._saleIdTable(db),
                    referencedColumn:
                        $$SaleItemsTableReferences._saleIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$SaleItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$SaleItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SaleItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SaleItemsTable,
    SaleItem,
    $$SaleItemsTableFilterComposer,
    $$SaleItemsTableOrderingComposer,
    $$SaleItemsTableAnnotationComposer,
    $$SaleItemsTableCreateCompanionBuilder,
    $$SaleItemsTableUpdateCompanionBuilder,
    (SaleItem, $$SaleItemsTableReferences),
    SaleItem,
    PrefetchHooks Function({bool saleId, bool productId})>;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  required String id,
  required String saleId,
  required String method,
  required int amountCents,
  Value<String?> transactionId,
  Value<String?> sourceCurrencyCode,
  Value<int?> sourceAmountCents,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<String> saleId,
  Value<String> method,
  Value<int> amountCents,
  Value<String?> transactionId,
  Value<String?> sourceCurrencyCode,
  Value<int?> sourceAmountCents,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$AppDatabase db) => db.sales
      .createAlias($_aliasNameGenerator(db.payments.saleId, db.sales.id));

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceCurrencyCode => $composableBuilder(
      column: $table.sourceCurrencyCode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sourceAmountCents => $composableBuilder(
      column: $table.sourceAmountCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceCurrencyCode => $composableBuilder(
      column: $table.sourceCurrencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sourceAmountCents => $composableBuilder(
      column: $table.sourceAmountCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableOrderingComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<String> get sourceCurrencyCode => $composableBuilder(
      column: $table.sourceCurrencyCode, builder: (column) => column);

  GeneratedColumn<int> get sourceAmountCents => $composableBuilder(
      column: $table.sourceAmountCents, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, $$PaymentsTableReferences),
    Payment,
    PrefetchHooks Function({bool saleId})> {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> saleId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<String?> transactionId = const Value.absent(),
            Value<String?> sourceCurrencyCode = const Value.absent(),
            Value<int?> sourceAmountCents = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion(
            id: id,
            saleId: saleId,
            method: method,
            amountCents: amountCents,
            transactionId: transactionId,
            sourceCurrencyCode: sourceCurrencyCode,
            sourceAmountCents: sourceAmountCents,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String saleId,
            required String method,
            required int amountCents,
            Value<String?> transactionId = const Value.absent(),
            Value<String?> sourceCurrencyCode = const Value.absent(),
            Value<int?> sourceAmountCents = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentsCompanion.insert(
            id: id,
            saleId: saleId,
            method: method,
            amountCents: amountCents,
            transactionId: transactionId,
            sourceCurrencyCode: sourceCurrencyCode,
            sourceAmountCents: sourceAmountCents,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PaymentsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (saleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.saleId,
                    referencedTable: $$PaymentsTableReferences._saleIdTable(db),
                    referencedColumn:
                        $$PaymentsTableReferences._saleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, $$PaymentsTableReferences),
    Payment,
    PrefetchHooks Function({bool saleId})>;
typedef $$IpvReportsTableCreateCompanionBuilder = IpvReportsCompanion Function({
  required String id,
  required String terminalId,
  required String warehouseId,
  required String sessionId,
  Value<String> status,
  Value<DateTime> openedAt,
  Value<DateTime?> closedAt,
  required String openedBy,
  Value<String?> closedBy,
  Value<String> openingSource,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$IpvReportsTableUpdateCompanionBuilder = IpvReportsCompanion Function({
  Value<String> id,
  Value<String> terminalId,
  Value<String> warehouseId,
  Value<String> sessionId,
  Value<String> status,
  Value<DateTime> openedAt,
  Value<DateTime?> closedAt,
  Value<String> openedBy,
  Value<String?> closedBy,
  Value<String> openingSource,
  Value<String?> note,
  Value<int> rowid,
});

final class $$IpvReportsTableReferences
    extends BaseReferences<_$AppDatabase, $IpvReportsTable, IpvReport> {
  $$IpvReportsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PosTerminalsTable _terminalIdTable(_$AppDatabase db) =>
      db.posTerminals.createAlias(
          $_aliasNameGenerator(db.ipvReports.terminalId, db.posTerminals.id));

  $$PosTerminalsTableProcessedTableManager get terminalId {
    final $_column = $_itemColumn<String>('terminal_id')!;

    final manager = $$PosTerminalsTableTableManager($_db, $_db.posTerminals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_terminalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WarehousesTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehouses.createAlias(
          $_aliasNameGenerator(db.ipvReports.warehouseId, db.warehouses.id));

  $$WarehousesTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableManager($_db, $_db.warehouses)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PosSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.posSessions.createAlias(
          $_aliasNameGenerator(db.ipvReports.sessionId, db.posSessions.id));

  $$PosSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$PosSessionsTableTableManager($_db, $_db.posSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _openedByTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.ipvReports.openedBy, db.users.id));

  $$UsersTableProcessedTableManager get openedBy {
    final $_column = $_itemColumn<String>('opened_by')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_openedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _closedByTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.ipvReports.closedBy, db.users.id));

  $$UsersTableProcessedTableManager? get closedBy {
    final $_column = $_itemColumn<String>('closed_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_closedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$IpvReportLinesTable, List<IpvReportLine>>
      _ipvReportLinesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ipvReportLines,
              aliasName: $_aliasNameGenerator(
                  db.ipvReports.id, db.ipvReportLines.reportId));

  $$IpvReportLinesTableProcessedTableManager get ipvReportLinesRefs {
    final manager = $$IpvReportLinesTableTableManager($_db, $_db.ipvReportLines)
        .filter((f) => f.reportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ipvReportLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IpvReportsTableFilterComposer
    extends Composer<_$AppDatabase, $IpvReportsTable> {
  $$IpvReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get openingSource => $composableBuilder(
      column: $table.openingSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$PosTerminalsTableFilterComposer get terminalId {
    final $$PosTerminalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableFilterComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableFilterComposer get warehouseId {
    final $$WarehousesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableFilterComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosSessionsTableFilterComposer get sessionId {
    final $$PosSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableFilterComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get openedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.openedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get closedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.closedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> ipvReportLinesRefs(
      Expression<bool> Function($$IpvReportLinesTableFilterComposer f) f) {
    final $$IpvReportLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReportLines,
        getReferencedColumn: (t) => t.reportId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportLinesTableFilterComposer(
              $db: $db,
              $table: $db.ipvReportLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IpvReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $IpvReportsTable> {
  $$IpvReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get openingSource => $composableBuilder(
      column: $table.openingSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$PosTerminalsTableOrderingComposer get terminalId {
    final $$PosTerminalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableOrderingComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableOrderingComposer get warehouseId {
    final $$WarehousesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableOrderingComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosSessionsTableOrderingComposer get sessionId {
    final $$PosSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get openedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.openedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get closedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.closedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IpvReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IpvReportsTable> {
  $$IpvReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get openingSource => $composableBuilder(
      column: $table.openingSource, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$PosTerminalsTableAnnotationComposer get terminalId {
    final $$PosTerminalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.terminalId,
        referencedTable: $db.posTerminals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosTerminalsTableAnnotationComposer(
              $db: $db,
              $table: $db.posTerminals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WarehousesTableAnnotationComposer get warehouseId {
    final $$WarehousesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.warehouseId,
        referencedTable: $db.warehouses,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WarehousesTableAnnotationComposer(
              $db: $db,
              $table: $db.warehouses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PosSessionsTableAnnotationComposer get sessionId {
    final $$PosSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.posSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PosSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.posSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get openedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.openedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get closedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.closedBy,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> ipvReportLinesRefs<T extends Object>(
      Expression<T> Function($$IpvReportLinesTableAnnotationComposer a) f) {
    final $$IpvReportLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ipvReportLines,
        getReferencedColumn: (t) => t.reportId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReportLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IpvReportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IpvReportsTable,
    IpvReport,
    $$IpvReportsTableFilterComposer,
    $$IpvReportsTableOrderingComposer,
    $$IpvReportsTableAnnotationComposer,
    $$IpvReportsTableCreateCompanionBuilder,
    $$IpvReportsTableUpdateCompanionBuilder,
    (IpvReport, $$IpvReportsTableReferences),
    IpvReport,
    PrefetchHooks Function(
        {bool terminalId,
        bool warehouseId,
        bool sessionId,
        bool openedBy,
        bool closedBy,
        bool ipvReportLinesRefs})> {
  $$IpvReportsTableTableManager(_$AppDatabase db, $IpvReportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IpvReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IpvReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IpvReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> terminalId = const Value.absent(),
            Value<String> warehouseId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<String> openedBy = const Value.absent(),
            Value<String?> closedBy = const Value.absent(),
            Value<String> openingSource = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IpvReportsCompanion(
            id: id,
            terminalId: terminalId,
            warehouseId: warehouseId,
            sessionId: sessionId,
            status: status,
            openedAt: openedAt,
            closedAt: closedAt,
            openedBy: openedBy,
            closedBy: closedBy,
            openingSource: openingSource,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String terminalId,
            required String warehouseId,
            required String sessionId,
            Value<String> status = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            required String openedBy,
            Value<String?> closedBy = const Value.absent(),
            Value<String> openingSource = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IpvReportsCompanion.insert(
            id: id,
            terminalId: terminalId,
            warehouseId: warehouseId,
            sessionId: sessionId,
            status: status,
            openedAt: openedAt,
            closedAt: closedAt,
            openedBy: openedBy,
            closedBy: closedBy,
            openingSource: openingSource,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IpvReportsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {terminalId = false,
              warehouseId = false,
              sessionId = false,
              openedBy = false,
              closedBy = false,
              ipvReportLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ipvReportLinesRefs) db.ipvReportLines
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (terminalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.terminalId,
                    referencedTable:
                        $$IpvReportsTableReferences._terminalIdTable(db),
                    referencedColumn:
                        $$IpvReportsTableReferences._terminalIdTable(db).id,
                  ) as T;
                }
                if (warehouseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.warehouseId,
                    referencedTable:
                        $$IpvReportsTableReferences._warehouseIdTable(db),
                    referencedColumn:
                        $$IpvReportsTableReferences._warehouseIdTable(db).id,
                  ) as T;
                }
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$IpvReportsTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$IpvReportsTableReferences._sessionIdTable(db).id,
                  ) as T;
                }
                if (openedBy) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.openedBy,
                    referencedTable:
                        $$IpvReportsTableReferences._openedByTable(db),
                    referencedColumn:
                        $$IpvReportsTableReferences._openedByTable(db).id,
                  ) as T;
                }
                if (closedBy) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.closedBy,
                    referencedTable:
                        $$IpvReportsTableReferences._closedByTable(db),
                    referencedColumn:
                        $$IpvReportsTableReferences._closedByTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ipvReportLinesRefs)
                    await $_getPrefetchedData<IpvReport, $IpvReportsTable,
                            IpvReportLine>(
                        currentTable: table,
                        referencedTable: $$IpvReportsTableReferences
                            ._ipvReportLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IpvReportsTableReferences(db, table, p0)
                                .ipvReportLinesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.reportId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IpvReportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IpvReportsTable,
    IpvReport,
    $$IpvReportsTableFilterComposer,
    $$IpvReportsTableOrderingComposer,
    $$IpvReportsTableAnnotationComposer,
    $$IpvReportsTableCreateCompanionBuilder,
    $$IpvReportsTableUpdateCompanionBuilder,
    (IpvReport, $$IpvReportsTableReferences),
    IpvReport,
    PrefetchHooks Function(
        {bool terminalId,
        bool warehouseId,
        bool sessionId,
        bool openedBy,
        bool closedBy,
        bool ipvReportLinesRefs})>;
typedef $$IpvReportLinesTableCreateCompanionBuilder = IpvReportLinesCompanion
    Function({
  required String reportId,
  required String productId,
  Value<String?> productNameSnapshot,
  Value<String?> productSkuSnapshot,
  Value<double> startQty,
  Value<double> entriesQty,
  Value<double> outputsQty,
  Value<double> salesQty,
  Value<double> finalQty,
  Value<int> salePriceCents,
  Value<int> totalAmountCents,
  Value<int> rowid,
});
typedef $$IpvReportLinesTableUpdateCompanionBuilder = IpvReportLinesCompanion
    Function({
  Value<String> reportId,
  Value<String> productId,
  Value<String?> productNameSnapshot,
  Value<String?> productSkuSnapshot,
  Value<double> startQty,
  Value<double> entriesQty,
  Value<double> outputsQty,
  Value<double> salesQty,
  Value<double> finalQty,
  Value<int> salePriceCents,
  Value<int> totalAmountCents,
  Value<int> rowid,
});

final class $$IpvReportLinesTableReferences
    extends BaseReferences<_$AppDatabase, $IpvReportLinesTable, IpvReportLine> {
  $$IpvReportLinesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IpvReportsTable _reportIdTable(_$AppDatabase db) =>
      db.ipvReports.createAlias(
          $_aliasNameGenerator(db.ipvReportLines.reportId, db.ipvReports.id));

  $$IpvReportsTableProcessedTableManager get reportId {
    final $_column = $_itemColumn<String>('report_id')!;

    final manager = $$IpvReportsTableTableManager($_db, $_db.ipvReports)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.ipvReportLines.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IpvReportLinesTableFilterComposer
    extends Composer<_$AppDatabase, $IpvReportLinesTable> {
  $$IpvReportLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
      column: $table.productNameSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productSkuSnapshot => $composableBuilder(
      column: $table.productSkuSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startQty => $composableBuilder(
      column: $table.startQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get entriesQty => $composableBuilder(
      column: $table.entriesQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get outputsQty => $composableBuilder(
      column: $table.outputsQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get salesQty => $composableBuilder(
      column: $table.salesQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get finalQty => $composableBuilder(
      column: $table.finalQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get salePriceCents => $composableBuilder(
      column: $table.salePriceCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents,
      builder: (column) => ColumnFilters(column));

  $$IpvReportsTableFilterComposer get reportId {
    final $$IpvReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reportId,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableFilterComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IpvReportLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $IpvReportLinesTable> {
  $$IpvReportLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
      column: $table.productNameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productSkuSnapshot => $composableBuilder(
      column: $table.productSkuSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startQty => $composableBuilder(
      column: $table.startQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get entriesQty => $composableBuilder(
      column: $table.entriesQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get outputsQty => $composableBuilder(
      column: $table.outputsQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get salesQty => $composableBuilder(
      column: $table.salesQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get finalQty => $composableBuilder(
      column: $table.finalQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get salePriceCents => $composableBuilder(
      column: $table.salePriceCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents,
      builder: (column) => ColumnOrderings(column));

  $$IpvReportsTableOrderingComposer get reportId {
    final $$IpvReportsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reportId,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableOrderingComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IpvReportLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IpvReportLinesTable> {
  $$IpvReportLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
      column: $table.productNameSnapshot, builder: (column) => column);

  GeneratedColumn<String> get productSkuSnapshot => $composableBuilder(
      column: $table.productSkuSnapshot, builder: (column) => column);

  GeneratedColumn<double> get startQty =>
      $composableBuilder(column: $table.startQty, builder: (column) => column);

  GeneratedColumn<double> get entriesQty => $composableBuilder(
      column: $table.entriesQty, builder: (column) => column);

  GeneratedColumn<double> get outputsQty => $composableBuilder(
      column: $table.outputsQty, builder: (column) => column);

  GeneratedColumn<double> get salesQty =>
      $composableBuilder(column: $table.salesQty, builder: (column) => column);

  GeneratedColumn<double> get finalQty =>
      $composableBuilder(column: $table.finalQty, builder: (column) => column);

  GeneratedColumn<int> get salePriceCents => $composableBuilder(
      column: $table.salePriceCents, builder: (column) => column);

  GeneratedColumn<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents, builder: (column) => column);

  $$IpvReportsTableAnnotationComposer get reportId {
    final $$IpvReportsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reportId,
        referencedTable: $db.ipvReports,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IpvReportsTableAnnotationComposer(
              $db: $db,
              $table: $db.ipvReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IpvReportLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IpvReportLinesTable,
    IpvReportLine,
    $$IpvReportLinesTableFilterComposer,
    $$IpvReportLinesTableOrderingComposer,
    $$IpvReportLinesTableAnnotationComposer,
    $$IpvReportLinesTableCreateCompanionBuilder,
    $$IpvReportLinesTableUpdateCompanionBuilder,
    (IpvReportLine, $$IpvReportLinesTableReferences),
    IpvReportLine,
    PrefetchHooks Function({bool reportId, bool productId})> {
  $$IpvReportLinesTableTableManager(
      _$AppDatabase db, $IpvReportLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IpvReportLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IpvReportLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IpvReportLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> reportId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String?> productNameSnapshot = const Value.absent(),
            Value<String?> productSkuSnapshot = const Value.absent(),
            Value<double> startQty = const Value.absent(),
            Value<double> entriesQty = const Value.absent(),
            Value<double> outputsQty = const Value.absent(),
            Value<double> salesQty = const Value.absent(),
            Value<double> finalQty = const Value.absent(),
            Value<int> salePriceCents = const Value.absent(),
            Value<int> totalAmountCents = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IpvReportLinesCompanion(
            reportId: reportId,
            productId: productId,
            productNameSnapshot: productNameSnapshot,
            productSkuSnapshot: productSkuSnapshot,
            startQty: startQty,
            entriesQty: entriesQty,
            outputsQty: outputsQty,
            salesQty: salesQty,
            finalQty: finalQty,
            salePriceCents: salePriceCents,
            totalAmountCents: totalAmountCents,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String reportId,
            required String productId,
            Value<String?> productNameSnapshot = const Value.absent(),
            Value<String?> productSkuSnapshot = const Value.absent(),
            Value<double> startQty = const Value.absent(),
            Value<double> entriesQty = const Value.absent(),
            Value<double> outputsQty = const Value.absent(),
            Value<double> salesQty = const Value.absent(),
            Value<double> finalQty = const Value.absent(),
            Value<int> salePriceCents = const Value.absent(),
            Value<int> totalAmountCents = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IpvReportLinesCompanion.insert(
            reportId: reportId,
            productId: productId,
            productNameSnapshot: productNameSnapshot,
            productSkuSnapshot: productSkuSnapshot,
            startQty: startQty,
            entriesQty: entriesQty,
            outputsQty: outputsQty,
            salesQty: salesQty,
            finalQty: finalQty,
            salePriceCents: salePriceCents,
            totalAmountCents: totalAmountCents,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IpvReportLinesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({reportId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (reportId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.reportId,
                    referencedTable:
                        $$IpvReportLinesTableReferences._reportIdTable(db),
                    referencedColumn:
                        $$IpvReportLinesTableReferences._reportIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$IpvReportLinesTableReferences._productIdTable(db),
                    referencedColumn:
                        $$IpvReportLinesTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IpvReportLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IpvReportLinesTable,
    IpvReportLine,
    $$IpvReportLinesTableFilterComposer,
    $$IpvReportLinesTableOrderingComposer,
    $$IpvReportLinesTableAnnotationComposer,
    $$IpvReportLinesTableCreateCompanionBuilder,
    $$IpvReportLinesTableUpdateCompanionBuilder,
    (IpvReportLine, $$IpvReportLinesTableReferences),
    IpvReportLine,
    PrefetchHooks Function({bool reportId, bool productId})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$AuditLogsTableCreateCompanionBuilder = AuditLogsCompanion Function({
  required String id,
  Value<String?> userId,
  required String action,
  required String entity,
  required String entityId,
  required String payloadJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AuditLogsTableUpdateCompanionBuilder = AuditLogsCompanion Function({
  Value<String> id,
  Value<String?> userId,
  Value<String> action,
  Value<String> entity,
  Value<String> entityId,
  Value<String> payloadJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AuditLogsTableReferences
    extends BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog> {
  $$AuditLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.auditLogs.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    final $_column = $_itemColumn<String>('user_id');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, $$AuditLogsTableReferences),
    AuditLog,
    PrefetchHooks Function({bool userId})> {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsCompanion(
            id: id,
            userId: userId,
            action: action,
            entity: entity,
            entityId: entityId,
            payloadJson: payloadJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> userId = const Value.absent(),
            required String action,
            required String entity,
            required String entityId,
            required String payloadJson,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsCompanion.insert(
            id: id,
            userId: userId,
            action: action,
            entity: entity,
            entityId: entityId,
            payloadJson: payloadJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AuditLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$AuditLogsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AuditLogsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AuditLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, $$AuditLogsTableReferences),
    AuditLog,
    PrefetchHooks Function({bool userId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$RolesTableTableManager get roles =>
      $$RolesTableTableManager(_db, _db.roles);
  $$PermissionsTableTableManager get permissions =>
      $$PermissionsTableTableManager(_db, _db.permissions);
  $$RolePermissionsTableTableManager get rolePermissions =>
      $$RolePermissionsTableTableManager(_db, _db.rolePermissions);
  $$UserRolesTableTableManager get userRoles =>
      $$UserRolesTableTableManager(_db, _db.userRoles);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductCatalogItemsTableTableManager get productCatalogItems =>
      $$ProductCatalogItemsTableTableManager(_db, _db.productCatalogItems);
  $$WarehousesTableTableManager get warehouses =>
      $$WarehousesTableTableManager(_db, _db.warehouses);
  $$PosTerminalsTableTableManager get posTerminals =>
      $$PosTerminalsTableTableManager(_db, _db.posTerminals);
  $$PosSessionsTableTableManager get posSessions =>
      $$PosSessionsTableTableManager(_db, _db.posSessions);
  $$PosSessionCashBreakdownsTableTableManager get posSessionCashBreakdowns =>
      $$PosSessionCashBreakdownsTableTableManager(
          _db, _db.posSessionCashBreakdowns);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db, _db.employees);
  $$PosSessionEmployeesTableTableManager get posSessionEmployees =>
      $$PosSessionEmployeesTableTableManager(_db, _db.posSessionEmployees);
  $$PosTerminalEmployeesTableTableManager get posTerminalEmployees =>
      $$PosTerminalEmployeesTableTableManager(_db, _db.posTerminalEmployees);
  $$StockBalancesTableTableManager get stockBalances =>
      $$StockBalancesTableTableManager(_db, _db.stockBalances);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db, _db.saleItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$IpvReportsTableTableManager get ipvReports =>
      $$IpvReportsTableTableManager(_db, _db.ipvReports);
  $$IpvReportLinesTableTableManager get ipvReportLines =>
      $$IpvReportLinesTableTableManager(_db, _db.ipvReportLines);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
}
