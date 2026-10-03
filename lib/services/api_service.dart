class RestaurantAuthApi {
  static Future<Map<String, dynamic>> registerRestaurant({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String restaurantName,
    required String restaurantPhone,
    required String description,
    required String address,
    required double lat,
    required double lng,
    required List<int> cuisineIds,
  }) async {
    return {'success': true};
  }
}
