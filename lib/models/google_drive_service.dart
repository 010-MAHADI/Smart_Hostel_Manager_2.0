import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['https://www.googleapis.com/auth/drive.file'],
);

class GoogleDriveService {
  // ✅ Create Authenticated HTTP Client
  static Future<http.Client?> getHttpClient() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    if (account == null) {
      print('❌ User not signed in');
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await account.authentication;

    // Manually create AccessCredentials from GoogleSignInAuthentication
    final auth.AccessCredentials credentials = auth.AccessCredentials(
      auth.AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().toUtc().add(Duration(hours: 1))),
      googleAuth.idToken,
      ['https://www.googleapis.com/auth/drive.file'],
    );

    // Use the credentials to authenticate the client
    final authenticatedClient = await auth.authenticatedClient(
      IOClient(),
      credentials,
    );

    return authenticatedClient;
  }

  // ✅ Upload File to Google Drive
  static Future<void> uploadFileToDrive(String filePath) async {
    try {
      final http.Client? client = await getHttpClient();
      if (client == null) {
        print('❌ Authentication failed');
        return;
      }

      final drive.DriveApi driveApi = drive.DriveApi(client);
      final File file = File(filePath);
      final drive.File fileMetadata = drive.File()..name = 'hostel_manager_backup.db';

      final media = drive.Media(file.openRead(), file.lengthSync());
      final drive.File uploadedFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      print('✅ File uploaded to Google Drive: ${uploadedFile.id}');
    } catch (e) {
      print('❌ Error uploading file: $e');
    }
  }

  // ✅ Download & Restore Database from Google Drive
  static Future<void> downloadAndRestore(String fileId) async {
    try {
      final http.Client? client = await getHttpClient();
      if (client == null) {
        print('❌ Authentication failed');
        return;
      }

      final drive.DriveApi driveApi = drive.DriveApi(client);

      final drive.Media file = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await getDatabasesPath();
      final restoredFile = File('$dbPath/hostel_manager.db');

      List<int> dataStore = [];
      await for (var data in file.stream) {
        dataStore.addAll(data);
      }
      await restoredFile.writeAsBytes(dataStore);

      print('✅ Database restored from Google Drive: ${restoredFile.path}');
    } catch (e) {
      print('❌ Error restoring database: $e');
    }
  }
}
