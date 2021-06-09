import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meeting_app/guest_book.dart';
import 'package:meeting_app/guest_book_message.dart';
import 'package:meeting_app/src/yes_no_selection.dart';

import 'package:provider/provider.dart';

import 'package:google_fonts/google_fonts.dart';

import 'src/authentication.dart';

import 'src/widgets.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, _) => App(),
    ),
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Meetup',
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Meetup'),
      ),
      body: ListView(
        children: <Widget>[
          Image.asset('assets/codelab.png'),
          const SizedBox(height: 8),
          const IconAndDetail(Icons.calendar_today, 'October 30'),
          const IconAndDetail(Icons.location_city, 'San Francisco'),
          Consumer<ApplicationState>(
            builder: (context, appState, _) => Authentication(
              email: appState.email,
              loginState: appState.logginState,
              startLoginFlow: appState.starLoginFlow,
              verifyEmail: appState.verifyEmail,
              signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
              cancelRegistration: appState.cancelRegistration,
              registerAccount: appState.registerAccount,
              signOut: appState.signOut,
            ),
          ),
          const Divider(
            height: 8,
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: Colors.grey,
          ),
          const Header("What we'll be doing"),
          const Paragraph(
            'Join us for a day full of Firebase Workshops and Pizza!',
          ),
          Consumer<ApplicationState>(
            builder: (context, appState, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appState.attendees > 1)
                  Paragraph('${appState.attendees} people going.'),
                if (appState.attendees == 1) const Paragraph('1 person going.'),
                if (appState.attendees == 0) const Paragraph('No one going.'),
                if (appState.logginState == ApplicationLoginState.loggedIn) ...[
                  YesNoSelection(
                    state: appState.attendding,
                    onSelection: (attendding) =>
                        appState.attendding = attendding,
                  ),
                  const Header('Discussion'),
                  GuestBook(
                    messages: appState.guestBookMessages,
                    addMessage: (message) {
                      appState.addMessageToGuestBook(message);
                    },
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  Future<void> init() async {
    await Firebase.initializeApp();

    //adds a subscription to the attendees collection
    _listenerCountSubscription = FirebaseFirestore.instance
        .collection('attendees')
        .where('attendding', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _attendees = snapshot.docs.length;
      notifyListeners();
    });

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginState = ApplicationLoginState.loggedIn;

        //adds a subscription to the guestbook collection on firebase.
        _guestBookSubscription = FirebaseFirestore.instance
            .collection('guestbook')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          _guestBookMessages = [];

          for (var document in snapshot.docs) {
            _guestBookMessages.add(
              GuestBookMessage(
                name: document.data()['name'].toString(),
                message: document.data()['text'].toString(),
              ),
            );
          }
          notifyListeners();
        });

        _attenddingSubscription = FirebaseFirestore.instance
            .collection('attendees')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.data() != null) {
            if (snapshot.data()!['attendding'] as bool) {
              _attendding = Attendding.yes;
            } else {
              _attendding = Attendding.no;
            }
          } else {
            _attendding = Attendding.unknown;
          }
          notifyListeners();
        });
      } else {
        _loginState = ApplicationLoginState.loggedOut;

        _guestBookMessages = [];
        _guestBookSubscription?.cancel();

        _attenddingSubscription?.cancel();
        _listenerCountSubscription?.cancel();
      }

      notifyListeners();
    });
  }

  ApplicationLoginState _loginState = ApplicationLoginState.loggedOut;
  ApplicationLoginState get logginState => _loginState;

  String? _email;

  String? get email => _email;

  StreamSubscription<QuerySnapshot>? _guestBookSubscription;
  List<GuestBookMessage> _guestBookMessages = [];
  List<GuestBookMessage> get guestBookMessages => _guestBookMessages;

  int _attendees = 0;
  Attendding _attendding = Attendding.unknown;
  Attendding get attendding => _attendding;

  int get attendees => _attendees;
  StreamSubscription<DocumentSnapshot>? _attenddingSubscription;
  StreamSubscription<QuerySnapshot>? _listenerCountSubscription;

  set attendding(Attendding attendding) {
    final userDoc = FirebaseFirestore.instance
        .collection('attendees')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    final data = {'attendding': false};

    if (attendding == Attendding.yes) {
      data['attendding'] = true;
    }

    userDoc.set(data);
  }

  void starLoginFlow() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCalback,
  ) async {
    try {
      var methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (methods.contains('password')) {
        _loginState = ApplicationLoginState.password;
      } else {
        _loginState = ApplicationLoginState.register;
      }

      _email = email;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCalback(e);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      _loginState = ApplicationLoginState.loggedIn;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void cancelRegistration() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> registerAccount(
      String email,
      String displayName,
      String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user!.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _loginState = ApplicationLoginState.loggedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _listenerCountSubscription?.cancel();
    super.dispose();
  }

  Future<DocumentReference> addMessageToGuestBook(String messageContent) {
    if (_loginState != ApplicationLoginState.loggedIn) {
      throw Exception('Must be logged in!');
    }

    final message = <String, dynamic>{};
    message['text'] = messageContent;
    message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    message['name'] = FirebaseAuth.instance.currentUser!.displayName;
    message['userID'] = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance.collection('guestbook').add(message);
  }
}
