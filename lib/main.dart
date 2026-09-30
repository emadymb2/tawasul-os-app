import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api_client.dart';
import 'core/l10n.dart';
import 'core/offline_store.dart';
import 'core/session.dart';
import 'data/console_repository.dart';
import 'screens/console_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = TawasulApiClient();
  final store = OfflineStore();
  final session = SessionController(api: api, store: store);
  final repository = ConsoleRepository(api: api, store: store);
  repository.startConnectivitySync();
  session.restore();
  runApp(TawasulApp(session: session, repository: repository));
}

class TawasulApp extends StatefulWidget {
  const TawasulApp({super.key, required this.session, required this.repository});

  final SessionController session;
  final ConsoleRepository repository;

  @override
  State<TawasulApp> createState() => _TawasulAppState();
}

class _TawasulAppState extends State<TawasulApp> {
  String _language = 'ar';

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      languageCode: _language,
      onChanged: (code) => setState(() => _language = code),
      child: MaterialApp(
        title: 'Tawasul School OS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: Locale(_language),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: AnimatedBuilder(
          animation: widget.session,
          builder: (context, _) {
            switch (widget.session.status) {
              case SessionStatus.loading:
                return const Scaffold(
                  backgroundColor: AppColors.cream,
                  body: Center(child: CircularProgressIndicator(color: AppColors.pine)),
                );
              case SessionStatus.signedOut:
                return LoginScreen(session: widget.session);
              case SessionStatus.signedIn:
                return ConsoleScreen(
                  key: ValueKey(widget.session.user?.personId),
                  session: widget.session,
                  repository: widget.repository,
                );
            }
          },
        ),
      ),
    );
  }
}
