import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'dart:convert'; // to convert Response object to Map object
import 'dart:async';
import 'package:http/http.dart' as http;
// AppState
class AppState {
  int _counter;
  String _quote;
  String _author;

  int get counter => _counter;
  String get quote => _quote;
  String get author => _author;

  AppState(this._counter, this._quote, this._author);
}
// Sync Action
enum Action {
  IncrementAction
}
class UpdateQuoteAction {
  String _quote;
  String _author;

  String get quote => this._quote;
  String get author => this._author;

  UpdateQuoteAction(this._quote, this._author);
}
// ThunkAction
ThunkAction<AppState> getRandomQuote = (Store<AppState> store) async {

  http.Response response = await http.get(
    Uri.encodeFull('http://quotesondesign.com/wp-json/posts?filter[orderby]=rand&filter[posts_per_page]=1'),
  );
  List<dynamic> result = json.decode(response.body);

  // This is to remove the <p></p> html tag received. This code is not crucial.
  String quote = result[0]['content'].replaceAll(new RegExp('[(<p>)(</p>)]'), '').replaceAll(new RegExp('&#8217;'),'\'');
  String author = result[0]['title'];

  store.dispatch(
      new UpdateQuoteAction(
          quote,
          author
      )
  );
};

// Reducer
AppState reducer(AppState prev, dynamic action) {

  if (action == Action.IncrementAction) {

    AppState newAppState = new AppState(prev.counter + 1, prev.quote, prev.author);

    return newAppState;

  } else if (action is UpdateQuoteAction) {
    AppState newAppState = new AppState(prev.counter, action.quote, action.author);

    return newAppState;
  } else {
    return prev;
  }

}
// store that hold our current appstate
final store = new Store<AppState>(
  reducer,
  initialState: new AppState(0, "", ""),
  middleware: [thunkMiddleware]
);


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: new MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'You have pushed the button this many times:',
            ),
            StoreConnector<AppState, int>(
              converter: (store) => store.state.counter,
              builder: (_, counter) {
                return new Text(
                  '$counter',
                  style: Theme.of(context).textTheme.display1,
                );
              },
            ),

            // display random quote and its author
            StoreConnector<AppState, AppState>(
              converter: (store) => store.state,
              builder: (_, state) {
                return new Text(
                    ' ${state.quote} \n -${state.author}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20.0
                  ),
                );
              },
            ),

            // generate quote button
            StoreConnector<AppState, GenerateQuote>(
              converter: (store) => () => store.dispatch(getRandomQuote),
              builder: (_, generateQuoteCallback) {
                return new FlatButton(
                  color: Colors.lightBlue,
                    onPressed: generateQuoteCallback,
                    child: new Text("generate random quote")
                );
              },
            )

          ],
        ),
      ),
      floatingActionButton: StoreConnector<AppState, IncrementCounter>(
        converter: (store) => () => store.dispatch(Action.IncrementAction),
        builder: (_, incrementCallback) {
          return new FloatingActionButton(
            onPressed: incrementCallback,
            tooltip: 'Increment',
            child: new Icon(Icons.add),
          );
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

typedef void IncrementCounter(); // This is sync.
typedef void GenerateQuote(); // This is async.