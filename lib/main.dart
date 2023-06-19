// ignore_for_file: deprecated_member_use, avoid_print, prefer_const_constructors, use_key_in_widget_constructors, unused_field, must_be_immutable, camel_case_types, sized_box_for_whitespace, unnecessary_brace_in_string_interps
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'flutter_switch.dart';
import 'package:permission_handler/permission_handler.dart';

//藍芽初始化
FlutterBlue flutterBlue = FlutterBlue.instance;

//控制變數------------------
dynamic dname = ''; //裝置名稱
dynamic did = ''; //裝置位置
dynamic rssi = ''; //訊號強度
dynamic mC = ''; //mCharacteristic 特徵值
dynamic locktext = '未連接';
//String electricity = '80%'; //電量
String cname = '未連接裝置'; //連接狀態中文
dynamic device = ''; //UUID
Map<String, ScanResult> scanResults = new Map();
List allname = []; //裝置名稱
List alllc = []; // 裝置位置
//預設開關
bool devicestate = false; //連接狀態
bool isBleOn = false; //藍芽狀態
bool con = true; //連結開關
bool msg = true; //手機通知開關
bool bell = false; //車上警鈴開關
bool sound = false; //手機通知聲音開關
bool lock = true; //鎖定狀態

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //移除debug圖示
      home: MyHome(),
    );
  }
}

//藍芽狀態偵測
void connectedset() {
  flutterBlue.state.listen((state) {
    if (state == BluetoothState.on) {
      print('藍牙狀態爲開啟');
      isBleOn = true;
      devicestate = true;
      //con = true;
    } else if (state == BluetoothState.off) {
      print('藍牙狀態爲關閉');
      devicestate = false;
      isBleOn = false;
      con = false;
    }
  });
}

//位置權限偵測
void requestLocation() async {
  if (await Permission.location.isGranted) {
    print('位置權限已開啟');
  } else {
    print('藍芽搜索需開啟位置權限');
    if (await Permission.location.request().isGranted) {
      print('位置權限已開啟');
    } else {
      print('位置權限請求失敗');
    }
  }
}

//啟動畫面
class MyHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SplashPage();
}

class SplashPage extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        body: Center(
            child: Image.asset(
          'assets/logo2.png',
        )));
  }

  @override
  void initState() {
    super.initState();
    set(); //跳頁
    connectedset(); //藍芽狀態
    requestLocation(); //位置權限偵測
  }

  //倒數跳頁
  void set() {
    Timer(Duration(seconds: 3), () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyHomePage(), maintainState: false));
    });
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

//主頁執行內容------------------------------------------------
class _MyHomePageState extends State {
//回傳刷新
  void _lock() {
    setState(() {
      if (isBleOn == false) {
        lock = false;
        locktext = '未連接';
      } else if (lock == true) {
        lock = false;
        locktext = '鎖定';
      } else if (lock == false) {
        locktext = '解鎖';
        lock = true;
      }
      print('狀態 = $lock');
      print('顯示 = $locktext');
    });
  }

//通知測試
  void msgtest() async {
    if (msg != false) {
      await _showNotification();
      print('通知');
    } else {
      print('通知已關閉');
    }
    //print('連接');
  }

/*計時套件
  void main() {
    Timer(Duration(seconds: 10), () {
      _showNotification();
    });
  }
*/
//彈出通知
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: android);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
    //   onSelectNotification: onSelectNotification);
  }

  Future _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channelid', 'flutterfcm',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, '防盜偵測系統通知', '偵測到異常移動!!，發出警告!', platformChannelSpecifics,
        payload: 'item x');
  } //彈出結束

  @override
  Widget build(BuildContext context) {
    //藍芽狀態列-------------
    var top = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Image.asset('assets/icon.png', width: 40, height: 40, fit: BoxFit.fill),
        Text(cname,
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
            )),
        RaisedButton(
          //按鈕
          child: const Text('連接',
              style: TextStyle(
                //color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold, //粗體
                fontSize: 20,
              )),
          onPressed: () {
            //跳頁按鈕
            //btnEvent;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BluetoothApp(),
                    maintainState: false));
          },
          color: const Color.fromARGB(255, 79, 183, 243),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)), //圓弧角
        )
      ],
    );
//灰框裝置名稱---------------
    var top2 = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          width: 312,
          height: 40,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 144, 144, 144),
            borderRadius: BorderRadius.all(
              Radius.elliptical(5, 5), //邊角圓度
            ),
          ),
          padding: EdgeInsets.all(10),
          child: Text(
            cname, //裝置名稱
          ),
        ),
      ],
    );
//電量,鎖定顯示-------------
    var top3 = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, //Row水平
      crossAxisAlignment: CrossAxisAlignment.center, //Row垂直
      children: <Widget>[
        /*
        //電量
        Container(
          //width: 150,
          //height: 150,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 90, 236, 122),
            borderRadius: BorderRadius.all(Radius.elliptical(130, 130)),
          ),
          alignment: Alignment.center, //在容器中置中對齊
          child: Text(
            electricity,
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 1),
              fontFamily: 'Roboto',
              fontSize: 25,
            ),
          ),
        ),*/
        //鎖定狀態
        SizedBox(
          width: 150,
          height: 150,
          child: RaisedButton(
            color: const Color.fromARGB(255, 238, 91, 91),

            shape: const CircleBorder(), //圓弧角
            onPressed: _lock,
            child: Text(
              locktext,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 30,
              ),
            ),
          ),
        ),
      ],
    );
//iocn圖示-------------
    var icon = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Image.asset('assets/battery.png',
            width: 40, height: 30, fit: BoxFit.fill),
        Image.asset('assets/lock.png', width: 35, height: 40, fit: BoxFit.fill),
      ],
    );
//第二層iocn圖示-------------
    var icon2 = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Image.asset('assets/phone.png',
            width: 50, height: 50, fit: BoxFit.fill),
        Image.asset('assets/power.png',
            width: 50, height: 50, fit: BoxFit.fill),
      ],
    );
//第一層開關--------------
    var buttom = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        //手機通知開關
        Image.asset('assets/msg2.png', width: 70, height: 70, fit: BoxFit.fill),
        FlutterSwitch(
          value: msg,
          showOnOff: true,
          onToggle: (value) {
            setState(() {
              msg = value;
              print('msg = $msg');
            });
          },
        ),
        //車上警報器開關
        Image.asset('assets/bell.png', width: 70, height: 70, fit: BoxFit.fill),
        FlutterSwitch(
          value: bell,
          showOnOff: true, //開關文字顯示
          onToggle: (value) {
            setState(() {
              bell = value;
              print('bell = $bell');
            });
          },
        ),
      ],
    );
//第二層開關--------------
    var buttom2 = Row(
      //手機通知音效開關
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Image.asset('assets/sound.png',
            width: 70, height: 70, fit: BoxFit.fill),
        FlutterSwitch(
          value: sound,
          showOnOff: true, //開關文字顯示
          onToggle: (value) {
            setState(() {
              sound = value;
              print('sound = $sound');
            });
          },
        ),
        //裝置連結開關
        Image.asset('assets/conn.png', width: 70, height: 70, fit: BoxFit.fill),
        FlutterSwitch(
          value: con,
          showOnOff: true, //開關文字顯示
          onToggle: (value) {
            setState(() {
              con = value;
              connectedset();
              //isBleOn = value;
              print('con = $con');
              print('isBleOn = $isBleOn');
            });
          },
        ),
      ],
    );

//主頁UI------------------------------------------------------
    return MaterialApp(
        debugShowCheckedModeBanner: false, //移除debug圖示
        theme: ThemeData(
            scaffoldBackgroundColor: const Color.fromARGB(255, 235, 235, 235)),
        home: Scaffold(
          appBar: AppBar(
            title: Center(child: Text('Bike Smart Luck 6')),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: const [
                      Color.fromARGB(255, 23, 23, 24),
                      Color(0xFF00CCFF),
                    ],
                    begin: FractionalOffset(0.0, 0.0),
                    end: FractionalOffset(1.0, 0.0),
                    tileMode: TileMode.clamp),
              ),
            ),
          ),

          //由上到下
          body: Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20), //上下左右空間設定
              child: Column(
                //匯集各層----------------------
                mainAxisAlignment: MainAxisAlignment.spaceAround, //平分空間?
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  top,
                  top2,
                  //icon,
                  top3,
                  icon2,
                  buttom,
                  buttom2,
                  SizedBox(
                      width: 120,
                      height: 120,
                      //margin: EdgeInsets.fromLTRB(0, 64.0, 0, 0),
                      child: InkWell(
                          onTap: msgtest,
                          child: const Image(
                            image: AssetImage('assets/logo2.png'),
                          ))),
                  Text('連接 = $con  鎖定狀態 = $lock  藍芽狀態 = $isBleOn'),
                ],
              )),
        ));
  }
}

//轉第二頁------------------------------------------------
class BluetoothApp extends StatefulWidget {
  @override
  bluesetpage createState() => bluesetpage();
}

//變數宣告
class Product {}

//第二頁執行內容------------------------------------------------
class bluesetpage extends State {
  var order = 0; //裝置數量
  @override
  void initState() {
    super.initState();
    if (isBleOn == false) {
      dname = '未開啟藍芽';
      did = '';
      rssi = '';
    }
  }

//藍芽寫入測試
  void testwrite() async {
    mC.write([123]);
  }

  //重整按鈕
  void btnEvent() {
    print('重整');
    setState(() {
      if (isBleOn == true) {
        scanLister(); //掃描
        //startBle();
        print('搜尋中....');
      } else if (isBleOn == false) {
        show1(); //提示跳窗
        dname = '未開啟藍芽';
        did = '';
        rssi = '';
        print('藍牙狀態爲關閉');
        print("手機藍牙未打開，請打開後再掃描設備");
      }
    });
  }

//掃描藍芽設備
  void scanLister() {
    order = 0;
    print('搜尋中');
    flutterBlue.stopScan();
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        order = 3;
        scanResults[r.device.name] = r;
        //print(r.advertisementData.serviceUuids.toString().substring(5, 9));//裝置特徵值

        if (r.advertisementData.serviceUuids.toString().substring(5, 9) ==
            "1818") {
          print(
              '裝置名稱:${r.device.name}\nUUID:${r.device.id.id}\n訊號強度: ${r.rssi}');
          allname.clear();
          allname.add(r.device.name);
          alllc.add(r.device.id.id);
          dname = r.device.name; //裝置名稱
          did = r.device.id.id; //裝置位置
          rssi = r.rssi; //訊號強度
        }
        flutterBlue.stopScan();
      }
    });
  }

//連接動作
  void connectb() async {
    print(allname);
    //更新過濾藍牙名字
    List distinctIds = allname.toSet().toList();

    print("過濾後的裝置名稱 $distinctIds");
    for (var i = 0; i < distinctIds.length; i++) {
      bool isEquipment = distinctIds[i].contains("Cycling Power");
      if (isEquipment) {
        ScanResult? r = scanResults[distinctIds[i]];
        device = r?.device;
        //print(device);
//device 裝置所有資訊
        flutterBlue.stopScan();
        connectb2();
      }
    }
  }

//連接藍芽2
  void connectb2() async {
    print("連接設備中..");
    cname = dname;
    await device.connect(autoConnect: false, timeout: Duration(seconds: 10));
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      var value = service.uuid.toString();
      //print(value);
      print("所有服務值 --- $value");
      print('測試${service.uuid}');
      if (service.uuid.toString().toUpperCase().substring(5, 9) == "1818") {
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        for (var characteristic in characteristics) {
          var valuex = characteristic.uuid.toString();
          print("所有特征值 --- $valuex");

          if (characteristic.uuid.toString() ==
              "00001818-0000-1000-8000-00805f9b34fb") {
            print("匹配到正确的特征值");
            print('c:$characteristic');
            mC = characteristic;

            const timeout = const Duration(seconds: 30);
            Timer(timeout, () {
              dataCallbackBle();
            });
          }
        }
      }
      nameud();
      mC.write([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);

      //dcd(); //名字刷新
      // do something with service
    }
  }

  void dataCallbackBle() async {
    await mC.setNotifyValue(true);
    mC.value.listen((value) {
      // do something with new value
      print("藍芽返回數據 - $value");
      if (value == null) {
        print("空值!");
        return;
      }
      List data = [];
      for (var i = 0; i < value.length; i++) {
        String dataStr = value[i].toRadixString(16);
        if (dataStr.length < 2) {
          dataStr = "0" + dataStr;
        }
        String dataEndStr = "0x" + dataStr;
        data.add(dataEndStr);
      }
      print("藍芽返回數據 - $data");
      //device.disconnect();
    });
  }

//回傳名字刷新
  void nameud() {
    setState(() {
      if (dname == '') {
        dname = 'N/A';
      } else {
        dname = dname;
      }
    });
  }

//藍芽未開啟通知窗
  void show1() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: const [
            Icon(Icons.bluetooth,
                size: 28.0, color: CupertinoColors.activeBlue),
            Text('  藍芽功能未開啟 ')
          ]),
          content: Text("手機藍牙未打開，請打開啟後再掃描設備。"),
          actions: <Widget>[
            FlatButton(
              child: Text("開啟藍芽"),
              onPressed: () {
                //Put your code here which you want to execute on Yes button click.
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("CANCEL"),
              onPressed: () {
                //Put your code here which you want to execute on Cancel button click.
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

//UI內容
//空格
  var space = Row(
    children: <Widget>[
      Container(
        height: 20,
      ),
    ],
  );
//分割線
  var line = Divider(
    color: Color.fromARGB(255, 79, 79, 79),
    height: 5,
    indent: 30,
    endIndent: 30,
  );
//連接按鈕
  var conbutton = FlatButton(
    color: Colors.blue,
    child: Text(
      'Connect',
      style: TextStyle(color: Colors.white),
    ),
    onPressed: () {
      print('斷開連接${did}');
    },
  );

  @override
  Widget build(BuildContext context) {
    //藍芽列表
    List<Product> listItems = List<Product>.generate(order, (i) {
      return Product();
    });

    //第二頁頂端 狀態列-------------
    var top = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/icon.png', width: 40, height: 40, fit: BoxFit.fill),
        Text(dname,
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
            )),
      ],
    );
    //藍芽列表
    var blueview = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: listItems.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.bluetooth),
              title: Text(dname),
              subtitle: Text('${did}\n${rssi}'),
              trailing: conbutton,
              onTap: () async {
                connectb();
                print('開始連接${did}');
              },
            );
          },
        ),
      ],
    );
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 235, 235, 235),
      appBar: AppBar(
        title: Center(child: Text('　  　連接設備')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 23, 23, 24),
                Color(0xFF00CCFF),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          FlatButton.icon(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            label: Text(
              "Refresh",
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            onPressed: btnEvent,
          ),
        ],
      ),
      //下方內容
      body: Center(
          child: Column(
              //mainAxisAlignment: MainAxisAlignment.spaceAround, //平分空間?
              //crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            space,
            top,
            line,
            Text('裝置列表',
                style: TextStyle(
                  fontSize: 20,
                )),
            Text('$dname\n$did\n$rssi'),
            blueview,
            space,
            line,
            RaisedButton(
              child: Text("掃描"),
              onPressed: btnEvent,
            ),

            /*RaisedButton(
              child: Text("返回主頁面"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),*/
          ])),
    );
  }
}
