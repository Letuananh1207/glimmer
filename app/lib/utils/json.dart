// Đọc an toàn trường JSON của firmware (thiếu / sai kiểu → giá trị mặc định, không ném lỗi).

int jsonInt(Object? v, [int d = 0]) => v is num ? v.toInt() : d;
bool jsonBool(Object? v) => v == true;
String jsonStr(Object? v) => v is String ? v : '';
