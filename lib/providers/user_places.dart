import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

import 'package:flutter_riverpod/legacy.dart';

Future<Database> _getDatabase() async {
  final dbpath = await sql.getDatabasesPath();
  return await sql.openDatabase(
    path.join(dbpath, 'places.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE user_places('
        'id TEXT PRIMARY KEY,'
        'title TEXT,'
        'image TEXT,'
        'loc_lat REAL,'
        'loc_lng REAL,'
        'address TEXT'
        ')',
      );
    },
    version: 1,
  );
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> loadPlaces() async {
    final db = await _getDatabase();
    final data = await db.query('user_places');

    final places = data.map(
      (item) {
        return Place(
          id: item['id'] as String,
          title: item['title'] as String,
          image: File(item['image'] as String),
          location: PlaceLocation(
            latitude: item['loc_lat'] as double,
            longitude: item['loc_lng'] as double,
            address: item['address'] as String,
          ),
        );
      },
    );

    state = places.toList();
  }

  void addPlace(String title, File image, PlaceLocation location) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedImage = await image.copy('${appDir.path}/$fileName');

    final place = Place(title: title, image: savedImage, location: location);

    final db = await _getDatabase();
    await db.insert(
      'user_places',
      {
        'id': place.id,
        'title': place.title,
        'image': place.image.path,
        'loc_lat': place.location.latitude,
        'loc_lng': place.location.longitude,
        'address': place.location.address,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );

    state = [...state, place];
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
      (ref) => UserPlacesNotifier(),
    );
