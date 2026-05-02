import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/professor_model.dart';
import '../../models/admin_model.dart';

class UserFactory {
  static UserModel fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString().toLowerCase() ?? 'student';
    
    if (role == 'student') {
      return StudentModel.fromJson(json);
    } else if (role == 'professor') {
      return ProfessorModel.fromJson(json);
    } else if (role == 'admin') {
      return AdminModel.fromJson(json);
    }
    
    return UserModel.fromJson(json);
  }
}
