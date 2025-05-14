# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *https://api.yourdomain.com/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**discountsGet**](DefaultApi.md#discountsget) | **GET** /discounts | Get cost-saving tips and discounts.


# **discountsGet**
> BuiltList<DiscountsGet200ResponseInner> discountsGet(location)

Get cost-saving tips and discounts.

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final String location = location_example; // String | User's location to filter relevant discounts.

try {
    final response = api.discountsGet(location);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->discountsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **location** | **String**| User's location to filter relevant discounts. | [optional] 

### Return type

[**BuiltList&lt;DiscountsGet200ResponseInner&gt;**](DiscountsGet200ResponseInner.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

