//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'discounts_get200_response_inner.g.dart';

/// DiscountsGet200ResponseInner
///
/// Properties:
/// * [title] 
/// * [description] 
/// * [savings] 
@BuiltValue()
abstract class DiscountsGet200ResponseInner implements Built<DiscountsGet200ResponseInner, DiscountsGet200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'savings')
  num? get savings;

  DiscountsGet200ResponseInner._();

  factory DiscountsGet200ResponseInner([void updates(DiscountsGet200ResponseInnerBuilder b)]) = _$DiscountsGet200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DiscountsGet200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DiscountsGet200ResponseInner> get serializer => _$DiscountsGet200ResponseInnerSerializer();
}

class _$DiscountsGet200ResponseInnerSerializer implements PrimitiveSerializer<DiscountsGet200ResponseInner> {
  @override
  final Iterable<Type> types = const [DiscountsGet200ResponseInner, _$DiscountsGet200ResponseInner];

  @override
  final String wireName = r'DiscountsGet200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DiscountsGet200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType(String),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.savings != null) {
      yield r'savings';
      yield serializers.serialize(
        object.savings,
        specifiedType: const FullType(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DiscountsGet200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DiscountsGet200ResponseInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'savings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.savings = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DiscountsGet200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DiscountsGet200ResponseInnerBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

