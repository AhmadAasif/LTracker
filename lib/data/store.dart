import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
class Store{
 static Database? _database;
 static Future<Database> get db async{if(_database!=null)return _database!;final dir=await getDatabasesPath();_database=await openDatabase(p.join(dir,'elora.db'),version:1,onCreate:(d,v)async{await d.execute('CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,done INTEGER NOT NULL DEFAULT 0,day TEXT NOT NULL)');await d.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,amount REAL NOT NULL,category TEXT NOT NULL,day TEXT NOT NULL)');await d.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');await d.execute('CREATE TABLE workouts(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,day TEXT NOT NULL)');await d.execute('CREATE TABLE meals(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,day TEXT NOT NULL)');});return _database!;}
 static String get day{final d=DateTime.now();return d.year.toString()+'-'+d.month.toString().padLeft(2,'0')+'-'+d.day.toString().padLeft(2,'0');}
 static String month(DateTime d)=>d.year.toString()+'-'+d.month.toString().padLeft(2,'0');
 static Future<List<Map<String,Object?>>> habits()async=>(await (await db).query('habits',orderBy:'id DESC'));
 static Future<void> addHabit(String n)async{await (await db).insert('habits',{'name':n,'done':0,'day':day});}
 static Future<void> toggle(int id)async{final d=await db;final rows=await d.query('habits',where:'id=?',whereArgs:[id],limit:1);if(rows.isEmpty)return;final h=rows.first;final value=h['done']==1&&h['day']==day?0:1;await d.update('habits',{'done':value,'day':day},where:'id=?',whereArgs:[id]);}
 static Future<void> delete(int id)async{await (await db).delete('habits',where:'id=?',whereArgs:[id]);}
 static Future<void> log(String table,String name)async{if(!['meals','workouts'].contains(table))throw ArgumentError('Unsupported log');await (await db).insert(table,{'name':name,'day':day});}
 static Future<List<Map<String,Object?>>> list(String table)async{if(!['meals','workouts'].contains(table))throw ArgumentError('Unsupported table');return (await (await db).query(table,orderBy:'id DESC'));}
 static Future<void> expense(String name,double amount,String category)async{if(amount<=0)throw ArgumentError('Amount must be positive');await (await db).insert('expenses',{'name':name,'amount':amount,'category':category,'day':day});}
 static Future<void> budget(double amount)async{await (await db).insert('settings',{'key':'budget','value':amount.toString()},conflictAlgorithm:ConflictAlgorithm.replace);}
 static Future<double> getBudget()async{final r=await (await db).query('settings',where:'key=?',whereArgs:['budget'],limit:1);return r.isEmpty?0:double.tryParse(r.first['value'] as String)??0;}
 static Future<Map<String,Object>> finance()async{final all=await (await db).query('expenses',orderBy:'id DESC');final items=all.where((e)=>(e['day'] as String).startsWith(month(DateTime.now()))).toList();final spent=items.fold<double>(0,(s,e)=>s+(e['amount'] as num).toDouble());return {'items':items,'spent':spent,'budget':await getBudget()};}
 static Future<Map<String,Object>> summary()async{final h=await habits();final f=await finance();final done=h.where((e)=>e['done']==1&&e['day']==day).length;return {'done':done,'spent':f['spent'] as double,'budget':f['budget'] as double};}
}
