import 'package:flutter/material.dart';

import 'package:meeting_app/application_state.dart';
import 'package:meeting_app/guest_book.dart';
import 'package:meeting_app/src/confirm_presence.dart';

import 'package:provider/provider.dart';

import 'package:google_fonts/google_fonts.dart';

import 'src/authentication.dart';

import 'src/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
                  ConfirmPresence(
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
