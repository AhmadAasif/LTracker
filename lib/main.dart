import 'package:flutter/material.dart';
import 'data/store.dart';
import 'screens/profile.dart';
import 'services/reminder_service.dart';

void main() async { WidgetsFlutterBinding.ensureInitialized(); await Store.db; await ReminderService.instance.restoreSavedReminder(); runApp(const EloraApp()); }
const bg=Color(0xFF071522), card=Color(0xFF102B40), blue=Color(0xFF49B8E8), mint=Color(0xFF79D6B0);
class EloraApp extends StatelessWidget { const EloraApp({super.key}); @override Widget build(BuildContext context)=>MaterialApp(title:'ELORA',debugShowCheckedModeBanner:false,theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:bg,colorScheme:const ColorScheme.dark(primary:blue,secondary:mint,surface:card),useMaterial3:true,cardTheme:CardThemeData(color:card,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))),home:const Shell());}
class Shell extends StatefulWidget {const Shell({super.key});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{int tab=0;final pages=const [Home(),Habits(),Fitness(),Food(),Money(),EloraChat(),Profile()];final names=['Home','Routine','Fitness','Food','Money','ELORA','You'];final icons=[Icons.home,Icons.check_circle_outline,Icons.fitness_center,Icons.restaurant,Icons.wallet,Icons.auto_awesome,Icons.person_outline];@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Row(children:[Icon(Icons.circle,color:blue),SizedBox(width:10),Text('ELORA',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:2))]),backgroundColor:bg),body:IndexedStack(index:tab,children:pages),bottomNavigationBar:NavigationBar(backgroundColor:card,selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:List.generate(7,(i)=>NavigationDestination(icon:Icon(icons[i]),label:names[i]))));}
Widget scroll(List<Widget> w)=>SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:w));
Widget title(String t,String s)=>Padding(padding:const EdgeInsets.only(top:12,bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text(s,style:const TextStyle(color:Colors.white60))]));
Widget box(Widget w)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:w));
String today(){final d=DateTime.now();return d.year.toString()+'-'+d.month.toString().padLeft(2,'0')+'-'+d.day.toString().padLeft(2,'0');}
String rupee(num n)=>'₹'+n.toStringAsFixed(0);
Future<String?> ask(BuildContext c,String label)=>showDialog<String>(context:c,builder:(x){final ctl=TextEditingController();return AlertDialog(backgroundColor:card,title:Text(label),content:TextField(controller:ctl,decoration:InputDecoration(hintText:label)),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(x,ctl.text.trim()),child:const Text('Save'))]);});
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return scroll([
      title('Your day, your pace.', 'Your Personal Life Intelligence.'),
      box(FutureBuilder<String>(future: Store.profileName(), builder: (context, snapshot) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hello${snapshot.data == null || snapshot.data!.isEmpty ? '' : ', ${snapshot.data}'}! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Small steps count. Let’s make today a little better.'),
        const SizedBox(height: 12),
        const Text('I’m here whenever you need a hand.', style: TextStyle(color: blue)),
      ]))),
      title('Today at a glance', 'Your personal progress, stored on this device.'),
      FutureBuilder<Map<String, Object>>(
        future: Store.summary(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final data = snapshot.data!;
          final budget = data['budget'] as double;
          final spent = data['spent'] as double;
          final remaining = (budget - spent).clamp(0, double.infinity);
          return Column(
            children: [
              box(Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Habits completed'),
                  Text(data['done'].toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mint)),
                ],
              )),
              box(Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Spent this month'),
                  Text(rupee(spent), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: blue)),
                ],
              )),
              box(Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly budget left'),
                  Text(budget > 0 ? rupee(remaining) : 'Not set', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )),
            ],
          );
        },
      ),
      title('A gentle reminder', 'You do not need a perfect day. Just a better next step.'),
    ]);
  }
}

class Habits extends StatefulWidget{const Habits({super.key});@override State<Habits> createState()=>_HabitsState();}
class _HabitsState extends State<Habits>{void reload()=>setState((){});@override Widget build(BuildContext c)=>scroll([title('Daily routine','Build consistency one small habit at a time.'),FilledButton.icon(onPressed:()async{final v=await ask(c,'Habit name');if(v!=null&&v.isNotEmpty){await Store.addHabit(v);reload();}},icon:const Icon(Icons.add),label:const Text('Add habit')),FutureBuilder<List<Map<String,Object?>>>(future:Store.habits(),builder:(c,s){if(!s.hasData)return const LinearProgressIndicator();if(s.data!.isEmpty)return const Padding(padding:EdgeInsets.all(24),child:Text('Your routine starts with one small habit. Add your first one above.'));return Column(children:s.data!.map((h)=>Card(child:CheckboxListTile(value:h['done']==1&&h['day']==today(),onChanged:(_)async{await Store.toggle(h['id'] as int);reload();},title:Text(h['name'] as String),activeColor:blue,secondary:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await Store.delete(h['id'] as int);reload();})))).toList());})]);}
class Fitness extends StatelessWidget {
  const Fitness({super.key});

  static const beginner = [
    '2 rounds: 10 chair squats, 8 wall push-ups, 10 glute bridges and a comfortable 20-second plank.',
    '10-minute walk or march in place, followed by gentle stretches.',
    'Upper body: wall push-ups, arm circles and shoulder mobility.',
    'Lower body: chair squats, glute bridges and supported reverse lunges.',
  ];
  static const intermediate = [
    '3 rounds: 12 squats, 10 incline push-ups, 12 glute bridges and 30-second plank.',
    '20-minute brisk walk, cycling or low-impact cardio.',
    '3 rounds: 10 reverse lunges per side, 12 hip hinges and 15 calf raises.',
    'Upper body: 3 rounds of incline push-ups, backpack rows and shoulder taps.',
  ];
  static const experienced = [
    'Strength circuit: 3-4 rounds of squats, push-ups, hip hinges and planks with controlled form.',
    '25-minute moderate cardio session. Keep a pace where you can still speak in short sentences.',
    'Lower-body strength: split squats, glute bridges and calf raises, 3 controlled sets.',
    'Upper-body strength: push-ups, backpack rows and pike push-ups, adjusted to your ability.',
  ];

  @override
  Widget build(BuildContext c) => FutureBuilder<String>(
    future: Store.getSetting('fitness_level', fallback: 'Beginner'),
    builder: (c, snapshot) {
      final level = snapshot.data ?? 'Beginner';
      final plans = level == 'Experienced' ? experienced : level == 'Intermediate' ? intermediate : beginner;
      return StatefulBuilder(builder: (context, refresh) => scroll([
        title('Home fitness', '$level plan · simple sessions, no gym required.'),
        box(const Text('Start comfortably, rest when needed and stop if you feel pain. Adapt every movement to your ability.')),
        ...plans.asMap().entries.map((entry) => box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Session ${entry.key + 1}', style: const TextStyle(color: mint, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(entry.value),
          const SizedBox(height: 10),
          FilledButton.tonal(onPressed: () async {
            await Store.log('workouts', 'Session ${entry.key + 1} · $level');
            if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Workout recorded. Nice work!')));
          }, child: const Text('Mark completed')),
        ]))),
        title('Weight check-in', 'Optional tracking. Your entries stay private on this phone.'),
        box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FilledButton.tonalIcon(onPressed: () async {
            final value = await ask(c, 'Weight in kilograms');
            final kg = double.tryParse(value ?? '');
            if (kg == null || kg < 20 || kg > 500) {
              if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Enter a valid weight in kilograms.')));
              return;
            }
            await Store.logWeight(kg);
            refresh(() {});
          }, icon: const Icon(Icons.monitor_weight_outlined), label: const Text('Log today’s weight')),
          FutureBuilder<List<Map<String, Object?>>>(future: Store.weightHistory(), builder: (context, history) {
            if (!history.hasData) return const LinearProgressIndicator();
            if (history.data!.isEmpty) return const Padding(padding: EdgeInsets.only(top: 10), child: Text('No weight entries yet. You can skip this completely.'));
            return Column(children: history.data!.take(7).map((row) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${(row['weight_kg'] as num).toStringAsFixed(1)} kg'),
              subtitle: Text(row['day'] as String),
            )).toList());
          }),
        ])),
        title('Recent workouts', 'Your completed sessions stay on this device.'),
        FutureBuilder<List<Map<String,Object?>>>(future: Store.list('workouts'), builder: (c,s) => !s.hasData ? const LinearProgressIndicator() : Column(children: s.data!.take(8).map((e) => ListTile(leading: const Icon(Icons.fitness_center,color:blue),title:Text(e['name'] as String),subtitle:Text(e['day'] as String))).toList())),
      ]));
    },
  );
}

class Food extends StatelessWidget {
  const Food({super.key});
  static const meals = [
    'Vegetarian · Dal, rice or roti, vegetables and curd',
    'Vegetarian · Paneer or chickpea bowl with vegetables',
    'Vegetarian · Idli or dosa with sambar',
    'Non-vegetarian · Eggs with whole-grain toast and fruit',
    'Non-vegetarian · Grilled chicken or fish with rice and vegetables',
    'Non-vegetarian · Egg or chicken wrap with salad',
  ];

  @override
  Widget build(BuildContext c) => FutureBuilder<String>(
    future: Store.getSetting('food_preference', fallback: 'Flexible'),
    builder: (c, snapshot) {
      final preference = snapshot.data ?? 'Flexible';
      final options = meals.where((m) {
        if (preference == 'Vegetarian') return m.startsWith('Vegetarian');
        if (preference == 'Non-vegetarian') return m.startsWith('Non-vegetarian');
        if (preference == 'Eggetarian') return m.startsWith('Vegetarian') || m.contains('Egg');
        return true;
      }).toList();
      return StatefulBuilder(builder: (context, refresh) => scroll([
        title('Food & nutrition', '$preference ideas · flexible, balanced meals.'),
        box(const Text('These are meal ideas, not a medical diet or calorie prescription. Choose portions and foods that suit your needs.')),
        ...options.map((m) => Card(child: ListTile(leading: const Icon(Icons.restaurant,color:mint),title:Text(m),trailing:IconButton(icon:const Icon(Icons.add_circle_outline),onPressed:()async{await Store.log('meals',m);if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Meal saved.')));})))) ,
        title('Hydration', 'A simple water check-in. Adjust your target to suit your day.'),
        FutureBuilder<int>(future: Store.waterToday(), builder: (context, water) => FutureBuilder<String>(
          future: Store.getSetting('water_goal_ml', fallback: '2000'),
          builder: (context, goalSnapshot) {
            if (!water.hasData || !goalSnapshot.hasData) return const LinearProgressIndicator();
            final goal = int.tryParse(goalSnapshot.data!) ?? 2000;
            final total = water.data!;
            return box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${total} ml / ${goal} ml', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: blue)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (total / goal).clamp(0.0, 1.0), color: mint),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                FilledButton.tonal(onPressed: () async { await Store.addWater(250); refresh(() {}); }, child: const Text('+ 250 ml')),
                FilledButton.tonal(onPressed: () async { await Store.addWater(500); refresh(() {}); }, child: const Text('+ 500 ml')),
                OutlinedButton(onPressed: () async {
                  final value = await ask(c, 'Daily water goal in ml');
                  final parsed = int.tryParse(value ?? '');
                  if (parsed != null && parsed >= 500 && parsed <= 5000) {
                    await Store.setSetting('water_goal_ml', parsed.toString());
                    refresh(() {});
                  }
                }, child: const Text('Set goal')),
              ]),
              const SizedBox(height: 6),
              const Text('A general reminder tool, not a medical hydration prescription.', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ]));
          },
        )),
        title('Food log','Your saved meal ideas.'),
        FutureBuilder<List<Map<String,Object?>>>(future:Store.list('meals'),builder:(c,s)=>!s.hasData?const LinearProgressIndicator():Column(children:s.data!.take(8).map((e)=>ListTile(title:Text(e['name'] as String),subtitle:Text(e['day'] as String))).toList())),
      ]));
    },
  );
}

class Money extends StatefulWidget{const Money({super.key});@override State<Money> createState()=>_MoneyState();}
class _MoneyState extends State<Money>{void refresh()=>setState((){});@override Widget build(BuildContext c)=>scroll([title('Your money','Awareness first. Better choices follow.'),Wrap(spacing:8,children:[FilledButton.icon(onPressed:()async{final desc=await ask(c,'Expense description');if(desc==null||desc.isEmpty)return;final amt=await ask(c,'Amount in rupees');final n=double.tryParse(amt??'');if(n==null||n<=0)return;final cat=await ask(c,'Category')??'Other';await Store.expense(desc,n,cat);refresh();},icon:const Icon(Icons.add),label:const Text('Add expense')),OutlinedButton.icon(onPressed:()async{final v=await ask(c,'Monthly budget in rupees');final n=double.tryParse(v??'');if(n!=null&&n>=0){await Store.budget(n);refresh();}},icon:const Icon(Icons.savings),label:const Text('Set budget'))]),FutureBuilder<Map<String,Object>>(future:Store.finance(),builder:(c,s){if(!s.hasData)return const LinearProgressIndicator();final d=s.data!;final b=d['budget'] as double;final spent=d['spent'] as double;return Column(children:[box(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Spent this month',style:TextStyle(color:Colors.white60)),Text(rupee(spent),style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold)),Text(b>0?'Budget '+rupee(b)+' · Remaining '+rupee((b-spent).clamp(0,double.infinity)):'No monthly budget set'),const SizedBox(height:10),LinearProgressIndicator(value:b<=0?0:(spent/b).clamp(0,1),color:spent>b?Colors.orange:mint)])),title('Recent expenses','Your records, not bank-linked transactions.'),...(d['items'] as List<Map<String,Object?>>).map((e)=>ListTile(leading:const Icon(Icons.receipt_long,color:blue),title:Text(e['name'] as String),subtitle:Text((e['category'] as String)+' · '+(e['day'] as String)),trailing:Text(rupee(e['amount'] as num))))]);})]);}
class EloraChat extends StatefulWidget{const EloraChat({super.key});@override State<EloraChat> createState()=>_ChatState();}
class _ChatState extends State<EloraChat>{final ctl=TextEditingController();final msgs=['Hi, I’m ELORA. I work offline and can help with your habits, spending, fitness and meals.'];Future<String> answer(String q)async{final s=await Store.finance();final x=q.toLowerCase();if(x.contains('budget')||x.contains('spend')||x.contains('money'))return 'You recorded '+rupee(s['spent'] as num)+' this month. Your budget is '+((s['budget'] as double)>0?rupee(s['budget'] as double):'not set')+'. I will not change your money settings without your approval.';if(x.contains('habit')||x.contains('routine')){final h=await Store.habits();final n=h.where((e)=>e['done']==1&&e['day']==today()).length;return 'You completed '+n.toString()+' of '+h.length.toString()+' habits today. Choose one small next step.';}if(x.contains('workout')||x.contains('fitness'))return 'Try a short, comfortable home session with chair squats, wall push-ups and gentle stretching. Stop if you feel pain.';if(x.contains('food')||x.contains('meal'))return 'Build a balanced plate with vegetables, a protein such as dal, beans, eggs, paneer, fish or chicken, and rice or roti.';return 'I’m your offline companion. I use built-in guidance rather than a cloud AI model. Ask me about budget, habits, fitness or meals. Your personal records stay on this device.';}void send()async{final q=ctl.text.trim();if(q.isEmpty)return;ctl.clear();setState(()=>msgs.add('You: '+q));final a=await answer(q);if(mounted)setState(()=>msgs.add('ELORA: '+a));}@override void dispose(){ctl.dispose();super.dispose();}@override Widget build(BuildContext c)=>Column(children:[Expanded(child:ListView(padding:const EdgeInsets.all(16),children:[title('Talk with ELORA','A helpful companion, even without internet.'),...msgs.map((m)=>Align(alignment:m.startsWith('You:')?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),constraints:const BoxConstraints(maxWidth:320),decoration:BoxDecoration(color:m.startsWith('You:')?const Color(0xFF17415B):card,borderRadius:BorderRadius.circular(16)),child:Text(m))))])),SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:ctl,onSubmitted:(_)=>send(),decoration:const InputDecoration(hintText:'Ask ELORA...'))),IconButton.filled(onPressed:send,icon:const Icon(Icons.send))]))) ]);}
