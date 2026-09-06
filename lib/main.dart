import 'package:flutter/material.dart';
import 'valve_command.dart';

void main() => runApp(const OrbiValveApp());

class OrbiValveApp extends StatelessWidget {
  const OrbiValveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ORBI Valve',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xfff3f5f8),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  bool obscure = true;

  void login() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.water_drop_rounded, size: 52),
                const SizedBox(height: 10),
                const Text('ORBI VALVE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Valve Management System'),
                const SizedBox(height: 28),
                TextField(controller: user, decoration: const InputDecoration(labelText: 'Username / Email', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: pass, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)), border: const OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: login, child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w900)))),
                const SizedBox(height: 14),
                TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                const SizedBox(height: 8),
                const Text('App Version: 1.0.0', style: TextStyle(color: Colors.grey)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [
    DashboardPage(),
    GsmPage(),
    LoraPage(),
    ValveDetailsPage(),
    MapPage(),
    SchedulePage(),
    Rs485DevicesPage(),
    CandidateDriversPage(),
    DriverInstallPage(),
  ];
  final names = const ['Dashboard','GSM Valve','LoRa Valve','Valve Details','Map View','Scheduling','RS485 Devices','Candidate Drivers','Driver Installation'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(names[index]), centerTitle: false),
      drawer: Drawer(
        child: SafeArea(child: Column(children: [
          const Padding(padding: EdgeInsets.all(20), child: Row(children: [Icon(Icons.water_drop_rounded, size: 30), SizedBox(width: 10), Text('ORBI VALVE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))])),
          const Divider(),
          Expanded(child: ListView.builder(itemCount: pages.length, itemBuilder: (_, i) => ListTile(leading: CircleAvatar(radius: 14, child: Text('${i + 1}')), title: Text(names[i]), selected: i == index, onTap: () { setState(() => index = i); Navigator.pop(context); })) ),
        ])),
      ),
      body: pages[index],
    );
  }
}

const valveId = 'ORBI-VALVE-001';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [
    Header(id: valveId),
    const Section(title: 'Protection / Health', child: HealthGrid()),
    Section(title: 'Valve Opening', child: Column(children: [const Text('68%', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)), const LinearProgressIndicator(value: .68), const SizedBox(height: 16), ControlButtons()])),
    const Card(child: Padding(padding: EdgeInsets.all(14), child: SizedBox(width: double.infinity, child: Center(child: Text('STATUS — CHECK WHEN NEEDED', style: TextStyle(fontWeight: FontWeight.w900))))),
  ]);
}

class GsmPage extends StatelessWidget {
  const GsmPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(id: valveId), Section(title: 'Valve Control', child: ControlButtons()), const Section(title: 'Protection / Health', child: HealthGrid()), Section(title: 'Adjustable Protection', child: GridFields(fields: const {'Current Min':'0.20 A','Current Max':'2.50 A','Motor Disengage':'0.40 A','Voltage Trip':'11.60 V'})), Section(title: 'GSM Power', child: Row(children: [Expanded(child: ActionButton('SLEEP', Icons.bedtime_outlined)), const SizedBox(width: 10), Expanded(child: ActionButton('WAKEUP', Icons.wb_sunny_outlined))])), Section(title: 'OTA Firmware Update', child: GridFields(fields: const {'Current FW':'GSM-VALVE-1.0.0','Available FW':'GSM-VALVE-1.0.1'})), Row(children: [Expanded(child: ActionButton('CHECK UPDATE', Icons.refresh)), const SizedBox(width: 10), Expanded(child: ActionButton('UPDATE FIRMWARE', Icons.system_update))])]);
}

class LoraPage extends StatelessWidget {
  const LoraPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(id: valveId), Section(title: 'Gateway Link', child: GridFields(fields: const {'GW ID':'ORBI-GW-001','RSSI':'▮▮▯ GOOD','Spreading Factor':'SF9','Bandwidth':'125 kHz'})), Section(title: 'Valve Control', child: ControlButtons()), const Section(title: 'Protection / Health', child: HealthGrid()), Row(children: [Expanded(child: ActionButton('CALIBRATION', Icons.tune)), const SizedBox(width: 10), Expanded(child: ActionButton('SCHEDULING', Icons.schedule))])]);
}

class ValveDetailsPage extends StatelessWidget {
  const ValveDetailsPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(id: valveId), Section(title: 'Valve Details', child: GridFields(fields: const {'Valve ID':valveId,'Status':'OPEN','Firmware':'GSM-VALVE-1.0.0','Opening':'68%','Connection':'GSM ONLINE','Last Status':'On demand'}))]);
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(title: 'Map View', id: valveId), SizedBox(height: 400, child: Card(child: Stack(children: const [Center(child: Icon(Icons.map_outlined, size: 180, color: Colors.grey)), Positioned(left: 90, top: 90, child: Pin('1')), Positioned(right: 100, top: 210, child: Pin('2')), Positioned(left: 190, bottom: 55, child: Pin('3'))]))), Section(title: 'Selected Valve', child: GridFields(fields: const {'Valve ID':valveId,'Location':'Field A','Status':'NORMAL','Opening':'68%'})), Row(children: [Expanded(child: ActionButton('VIEW DETAILS', Icons.info_outline)), const SizedBox(width: 10), Expanded(child: ActionButton('REMOVE FROM MAP', Icons.location_off_outlined))])]);
}

class Pin extends StatelessWidget { final String text; const Pin(this.text,{super.key}); @override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(10),decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.black87),child:Text(text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))); }

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(title: 'Scheduling', id: valveId), Section(title: 'Schedule', child: GridFields(fields: const {'Schedule':'Daily','Time':'06:00','Action':'OPEN 50%','Enabled':'YES'})), Row(children: [Expanded(child: ActionButton('ADD SCHEDULE', Icons.add)), const SizedBox(width: 10), Expanded(child: ActionButton('EDIT', Icons.edit)), const SizedBox(width: 10), Expanded(child: ActionButton('DISABLE', Icons.pause_circle_outline))])]);
}

class Rs485DevicesPage extends StatelessWidget {
  const Rs485DevicesPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(title: 'RS485 DEVICES', id: valveId), Section(title: 'EXISTING MODBUS DEVICES', child: const DeviceCard(name:'Device 1', fields:{'Slave ID':'1','Status':'VALID'})), Section(title: '⚠ NEW DEVICE FOUND', child: const DeviceCard(name:'ABC FLOW-X100', fields:{'Manufacturer':'ABC','Model':'FLOW-X100','Device ID':'ABC123456','Slave ID':'3'}, newDevice:true)), ActionButton('SEARCH DRIVER', Icons.search, filled:true)]);
}

class CandidateDriversPage extends StatelessWidget {
  const CandidateDriversPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(title:'CANDIDATE DRIVERS', id:valveId), Section(title:'NEW DEVICE', child:GridFields(fields:const {'Manufacturer':'ABC','Model':'FLOW-X100','Device ID':'ABC123456','Slave ID':'3'})), const DriverCard(name:'ABC FLOW-X100', id:'abc_flow_x100', version:'1.0.0', match:'98%'), const DriverCard(name:'ABC FLOW-X100 Legacy', id:'abc_flow_x100_legacy', version:'0.9.2', match:'84%')]);
}

class DriverInstallPage extends StatelessWidget {
  const DriverInstallPage({super.key});
  @override Widget build(BuildContext context) => AppPage(children: [Header(title:'DRIVER INSTALLATION', id:valveId), Section(title:'SELECTED DRIVER', child:GridFields(fields:const {'Driver':'abc_flow_x100','Version':'1.0.0','Device ID':'ABC123456','Slave ID':'3','Function':'03','Telemetry':'2 values'})), const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('⚠ Install this driver for this Modbus device?',style:TextStyle(fontWeight:FontWeight.w900)))), Row(children:[Expanded(child:ActionButton('CANCEL',Icons.close)),const SizedBox(width:10),Expanded(child:ActionButton('INSTALL DRIVER',Icons.download,filled:true))])]);
}

class AppPage extends StatelessWidget { final List<Widget> children; const AppPage({super.key,required this.children}); @override Widget build(BuildContext c)=>SingleChildScrollView(padding:const EdgeInsets.all(18),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:900),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:children.map((w)=>Padding(padding:const EdgeInsets.only(bottom:14),child:w)).toList()))); }
class Header extends StatelessWidget { final String id; final String? title; const Header({super.key,required this.id,this.title}); @override Widget build(BuildContext c)=>Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(title??'ORBI VALVE',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Chip(label:Text(id,style:const TextStyle(fontWeight:FontWeight.w800)))]); }
class Section extends StatelessWidget { final String title; final Widget child; const Section({super.key,required this.title,required this.child}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(17),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:13),child]))); }
class HealthGrid extends StatelessWidget { const HealthGrid({super.key}); @override Widget build(BuildContext c)=>Wrap(spacing:8,runSpacing:8,children:const [Health('🟢','SYSTEM','NORMAL'),Health('🟢','VOLTAGE','NORMAL'),Health('🟢','MOTOR','NORMAL'),Health('🟢','RS485','ONLINE')]); }
class Health extends StatelessWidget { final String icon,name,value; const Health(this.icon,this.name,this.value,{super.key}); @override Widget build(BuildContext c)=>Container(width:160,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xfff7f9fb),borderRadius:BorderRadius.circular(12)),child:Text('$icon $name\n$value',style:const TextStyle(fontWeight:FontWeight.w800))); }
class ControlButtons extends StatelessWidget { const ControlButtons({super.key}); @override Widget build(BuildContext c)=>Row(children:[Expanded(child:ActionButton('OPEN',Icons.arrow_upward,filled:true)),const SizedBox(width:8),Expanded(child:ActionButton('E-STOP',Icons.stop_circle_outlined)),const SizedBox(width:8),Expanded(child:ActionButton('CLOSE',Icons.arrow_downward))]); }
class ActionButton extends StatelessWidget { final String text; final IconData icon; final bool filled; const ActionButton(this.text,this.icon,{super.key,this.filled=false}); @override Widget build(BuildContext c)=>SizedBox(height:52,child:filled?FilledButton.icon(onPressed:(){},icon:Icon(icon),label:Text(text,style:const TextStyle(fontWeight:FontWeight.w900))):OutlinedButton.icon(onPressed:(){},icon:Icon(icon),label:Text(text,style:const TextStyle(fontWeight:FontWeight.w900)))); }
class GridFields extends StatelessWidget { final Map<String,String> fields; const GridFields({super.key,required this.fields}); @override Widget build(BuildContext c)=>Wrap(spacing:10,runSpacing:10,children:fields.entries.map((e)=>SizedBox(width: (MediaQuery.sizeOf(c).width-75)/2, child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xfff7f9fb),borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e.key.toUpperCase(),style:const TextStyle(fontSize:10,color:Colors.grey,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(e.value,style:const TextStyle(fontWeight:FontWeight.w800))])))).toList()); }
class DeviceCard extends StatelessWidget { final String name; final Map<String,String> fields; final bool newDevice; const DeviceCard({super.key,required this.name,required this.fields,this.newDevice=false}); @override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(border:Border.all(color:Colors.black12),borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),const SizedBox(height:10),GridFields(fields:fields)])); }
class DriverCard extends StatelessWidget { final String name,id,version,match; const DriverCard({super.key,required this.name,required this.id,required this.version,required this.match}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Chip(label:Text('MATCH $match'))]),Text('$id • v$version',style:const TextStyle(color:Colors.grey)),const SizedBox(height:10),GridFields(fields:const {'Function':'03','Telemetry':'2 values'}),const SizedBox(height:10),ActionButton('SELECT',Icons.check_circle,filled:true)]))); }
""