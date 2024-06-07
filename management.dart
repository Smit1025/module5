import 'package:flutter/material.dart';
import 'package:flutter1/Offline_assignment.dart/creat.dart';
import 'package:flutter1/Offline_assignment.dart/operations.dart';
import 'package:intl/intl.dart';
import 'task.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Task> _tasks = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    List<Map<String, dynamic>> tasks = await _databaseHelper.getTasks();
    setState(() {
      _tasks = tasks.map((task) => Task.fromMap(task)).toList();
    });
  }

  void _searchTasks(String query) async {
    if (query.isEmpty) {
      _loadTasks();
    } else {
      List<Map<String, dynamic>> tasks =
          await _databaseHelper.searchTasksByName(query);
      setState(() {
        _tasks = tasks.map((task) => Task.fromMap(task)).toList();
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  void _completeTask(Task task) async {
    task.status = 'completed';
    await _databaseHelper.updateTask(task.toMap());
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(_tasks, _databaseHelper),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          Task task = _tasks[index];
          bool isDue = DateFormat('yyyy-MM-dd')
              .parse(task.date)
              .isBefore(DateTime.now());
          return Card(
            color: task.status == 'completed' ? Colors.grey[300] : Colors.white,
            child: ListTile(
              title: Text(
                task.name,
                style: TextStyle(
                  decoration: task.status == 'completed'
                      ? TextDecoration.lineThrough
                      : null,
                  color: _getPriorityColor(task.priority),
                ),
              ),
              subtitle: Text('${task.date} ${task.time}\n${task.description}'),
              trailing: task.status == 'completed'
                  ? null
                  : IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () => _completeTask(task),
                    ),
              onTap: () => _showContextMenu(context, task),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showTaskDialog([Task? task]) {
    showDialog(
      context: context,
      builder: (context) {
        return TaskDialog(
          databaseHelper: _databaseHelper,
          task: task,
          onSave: _loadTasks,
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            ListTile(
              leading: Icon(Icons.check),
              title: Text('Complete Task'),
              onTap: () {
                Navigator.pop(context);
                _completeTask(task);
              },
            ),
          ],
        );
      },
    );
  }
}

class TaskDialog extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final Task? task;
  final Function onSave;

  TaskDialog({required this.databaseHelper, this.task, required this.onSave});

  @override
  _TaskDialogState createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  String _priority = 'low';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _dateController = TextEditingController(text: widget.task?.date ?? '');
    _timeController = TextEditingController(text: widget.task?.time ?? '');
    _priority = widget.task?.priority ?? 'low';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter task name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Date'),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dateController.text =
                        DateFormat('yyyy-MM-dd').format(pickedDate);
                  });
                }
              },
            ),
            TextFormField(
              controller: _timeController,
              decoration: InputDecoration(labelText: 'Time'),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _timeController.text = pickedTime.format(context);
                  });
                }
              },
            ),
            DropdownButtonFormField<String>(
              value: _priority,
              items: ['low', 'medium', 'high'].map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Task task = Task(
                id: widget.task?.id,
                name: _nameController.text,
                description: _descriptionController.text,
                date: _dateController.text,
                time: _timeController.text,
                priority: _priority,
                status: widget.task?.status ?? 'pending',
              );
              if (widget.task == null) {
                await widget.databaseHelper.insertTask(task.toMap());
              } else {
                await widget.databaseHelper.updateTask(task.toMap());
              }
              widget.onSave();
              Navigator.pop(context);
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  final List<Task> tasks;
  final DatabaseHelper databaseHelper;

  TaskSearchDelegate(this.tasks, this.databaseHelper);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<Task> searchResults = tasks
        .where((task) => task.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        Task task = searchResults[index];
        return ListTile(
          title: Text(task.name),
          subtitle: Text(task.description),
          onTap: () {
            close(context, task);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<Task> searchResults = tasks
        .where((task) => task.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        Task task = searchResults[index];
        return ListTile(
          title: Text(task.name),
          subtitle: Text(task.description),
          onTap: () {
            close(context, task);
          },
        );
      },
    );
  }
}
