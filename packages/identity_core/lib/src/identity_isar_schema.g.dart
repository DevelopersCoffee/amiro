// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_isar_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIdentityRecordCollection on Isar {
  IsarCollection<IdentityRecord> get identityRecords => this.collection();
}

const IdentityRecordSchema = CollectionSchema(
  name: r'IdentityRecord',
  id: -2303143554673215988,
  properties: {
    r'avatarDefinitionJson': PropertySchema(
      id: 0,
      name: r'avatarDefinitionJson',
      type: IsarType.string,
    ),
    r'bio': PropertySchema(
      id: 1,
      name: r'bio',
      type: IsarType.string,
    ),
    r'displayName': PropertySchema(
      id: 2,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'email': PropertySchema(
      id: 3,
      name: r'email',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'instagramHandle': PropertySchema(
      id: 5,
      name: r'instagramHandle',
      type: IsarType.string,
    ),
    r'mobile': PropertySchema(
      id: 6,
      name: r'mobile',
      type: IsarType.string,
    ),
    r'privacyJson': PropertySchema(
      id: 7,
      name: r'privacyJson',
      type: IsarType.string,
    ),
    r'username': PropertySchema(
      id: 8,
      name: r'username',
      type: IsarType.string,
    ),
    r'website': PropertySchema(
      id: 9,
      name: r'website',
      type: IsarType.string,
    ),
    r'xHandle': PropertySchema(
      id: 10,
      name: r'xHandle',
      type: IsarType.string,
    )
  },
  estimateSize: _identityRecordEstimateSize,
  serialize: _identityRecordSerialize,
  deserialize: _identityRecordDeserialize,
  deserializeProp: _identityRecordDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _identityRecordGetId,
  getLinks: _identityRecordGetLinks,
  attach: _identityRecordAttach,
  version: '3.1.0+1',
);

int _identityRecordEstimateSize(
  IdentityRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatarDefinitionJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.bio;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.displayName.length * 3;
  {
    final value = object.email;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.instagramHandle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mobile;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.privacyJson.length * 3;
  bytesCount += 3 + object.username.length * 3;
  {
    final value = object.website;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.xHandle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _identityRecordSerialize(
  IdentityRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatarDefinitionJson);
  writer.writeString(offsets[1], object.bio);
  writer.writeString(offsets[2], object.displayName);
  writer.writeString(offsets[3], object.email);
  writer.writeString(offsets[4], object.id);
  writer.writeString(offsets[5], object.instagramHandle);
  writer.writeString(offsets[6], object.mobile);
  writer.writeString(offsets[7], object.privacyJson);
  writer.writeString(offsets[8], object.username);
  writer.writeString(offsets[9], object.website);
  writer.writeString(offsets[10], object.xHandle);
}

IdentityRecord _identityRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IdentityRecord();
  object.avatarDefinitionJson = reader.readStringOrNull(offsets[0]);
  object.bio = reader.readStringOrNull(offsets[1]);
  object.displayName = reader.readString(offsets[2]);
  object.email = reader.readStringOrNull(offsets[3]);
  object.id = reader.readString(offsets[4]);
  object.instagramHandle = reader.readStringOrNull(offsets[5]);
  object.isarId = id;
  object.mobile = reader.readStringOrNull(offsets[6]);
  object.privacyJson = reader.readString(offsets[7]);
  object.username = reader.readString(offsets[8]);
  object.website = reader.readStringOrNull(offsets[9]);
  object.xHandle = reader.readStringOrNull(offsets[10]);
  return object;
}

P _identityRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _identityRecordGetId(IdentityRecord object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _identityRecordGetLinks(IdentityRecord object) {
  return [];
}

void _identityRecordAttach(
    IsarCollection<dynamic> col, Id id, IdentityRecord object) {
  object.isarId = id;
}

extension IdentityRecordQueryWhereSort
    on QueryBuilder<IdentityRecord, IdentityRecord, QWhere> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IdentityRecordQueryWhere
    on QueryBuilder<IdentityRecord, IdentityRecord, QWhereClause> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IdentityRecordQueryFilter
    on QueryBuilder<IdentityRecord, IdentityRecord, QFilterCondition> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatarDefinitionJson',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatarDefinitionJson',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarDefinitionJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarDefinitionJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarDefinitionJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarDefinitionJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarDefinitionJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarDefinitionJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarDefinitionJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarDefinitionJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarDefinitionJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      avatarDefinitionJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarDefinitionJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bio',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bio',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bio',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bio',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      bioIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bio',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'instagramHandle',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'instagramHandle',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'instagramHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'instagramHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'instagramHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'instagramHandle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'instagramHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'instagramHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'instagramHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'instagramHandle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'instagramHandle',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      instagramHandleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'instagramHandle',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mobile',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mobile',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      mobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privacyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privacyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privacyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privacyJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'privacyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'privacyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privacyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privacyJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privacyJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      privacyJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privacyJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'website',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'website',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'website',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'website',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'website',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      websiteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'website',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'xHandle',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'xHandle',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'xHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'xHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'xHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'xHandle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'xHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'xHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'xHandle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'xHandle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'xHandle',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
      xHandleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'xHandle',
        value: '',
      ));
    });
  }
}

extension IdentityRecordQueryObject
    on QueryBuilder<IdentityRecord, IdentityRecord, QFilterCondition> {}

extension IdentityRecordQueryLinks
    on QueryBuilder<IdentityRecord, IdentityRecord, QFilterCondition> {}

extension IdentityRecordQuerySortBy
    on QueryBuilder<IdentityRecord, IdentityRecord, QSortBy> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByAvatarDefinitionJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarDefinitionJson', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByAvatarDefinitionJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarDefinitionJson', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByBio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByBioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByInstagramHandle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instagramHandle', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByInstagramHandleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instagramHandle', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByPrivacyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyJson', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByPrivacyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyJson', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByWebsite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByWebsiteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByXHandle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xHandle', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      sortByXHandleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xHandle', Sort.desc);
    });
  }
}

extension IdentityRecordQuerySortThenBy
    on QueryBuilder<IdentityRecord, IdentityRecord, QSortThenBy> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByAvatarDefinitionJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarDefinitionJson', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByAvatarDefinitionJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarDefinitionJson', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByBio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByBioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByInstagramHandle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instagramHandle', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByInstagramHandleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'instagramHandle', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByPrivacyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyJson', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByPrivacyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyJson', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByWebsite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByWebsiteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByXHandle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xHandle', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
      thenByXHandleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xHandle', Sort.desc);
    });
  }
}

extension IdentityRecordQueryWhereDistinct
    on QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> {
  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct>
      distinctByAvatarDefinitionJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarDefinitionJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByBio(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bio', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct>
      distinctByInstagramHandle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'instagramHandle',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByMobile(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByPrivacyJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privacyJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByWebsite(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'website', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByXHandle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'xHandle', caseSensitive: caseSensitive);
    });
  }
}

extension IdentityRecordQueryProperty
    on QueryBuilder<IdentityRecord, IdentityRecord, QQueryProperty> {
  QueryBuilder<IdentityRecord, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IdentityRecord, String?, QQueryOperations>
      avatarDefinitionJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarDefinitionJson');
    });
  }

  QueryBuilder<IdentityRecord, String?, QQueryOperations> bioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bio');
    });
  }

  QueryBuilder<IdentityRecord, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<IdentityRecord, String?, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<IdentityRecord, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IdentityRecord, String?, QQueryOperations>
      instagramHandleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'instagramHandle');
    });
  }

  QueryBuilder<IdentityRecord, String?, QQueryOperations> mobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobile');
    });
  }

  QueryBuilder<IdentityRecord, String, QQueryOperations> privacyJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privacyJson');
    });
  }

  QueryBuilder<IdentityRecord, String, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }

  QueryBuilder<IdentityRecord, String?, QQueryOperations> websiteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'website');
    });
  }

  QueryBuilder<IdentityRecord, String?, QQueryOperations> xHandleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'xHandle');
    });
  }
}
