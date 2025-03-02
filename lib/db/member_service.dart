import '../models/member.dart';
import 'db_helper.dart';

class MemberService {
  Future<int> addMember(Member member) async {
    final db = await DBHelper.instance.database;
    return await db.insert('members', member.toMap());
  }

  Future<List<Member>> getMembers() async {
    final db = await DBHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query('members');
    return result.map((e) => Member.fromMap(e)).toList();
  }

  Future<int> updateMember(Member member) async {
    final db = await DBHelper.instance.database;
    return await db.update('members', member.toMap(),
        where: "id = ?", whereArgs: [member.id]);
  }

  Future<int> deleteMember(int id) async {
    final db = await DBHelper.instance.database;
    return await db.delete('members', where: "id = ?", whereArgs: [id]);
  }
}
