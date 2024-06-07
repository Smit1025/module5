class Task {
  int? id;
  String name;
  String description;
  String date;
  String time;
  String priority;
  String status;

  Task({
    this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.priority,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date,
      'time': time,
      'priority': priority,
      'status': status,
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      date: map['date'],
      time: map['time'],
      priority: map['priority'],
      status: map['status'],
    );
  }
}
