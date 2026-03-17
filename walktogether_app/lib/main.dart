import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/step_counter_service.dart';
import 'core/services/step_sync_service.dart';
import 'core/network/dio_client.dart';
import 'core/socket/socket_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/group/data/repositories/group_repository.dart';
import 'features/group/presentation/bloc/group_list_bloc.dart';
import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/presentation/bloc/conversation_list_bloc.dart';
import 'features/contest/data/repositories/contest_repository.dart';
import 'features/step_tracker/data/repositories/step_repository.dart';
import 'features/step_tracker/presentation/bloc/step_tracker_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize locale data for date formatting (Vietnamese)
  await initializeDateFormatting('vi', null);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final dioClient = DioClient(storageService);

  final authRepository = AuthRepository(
    dio: dioClient,
    storage: storageService,
  );

  final groupRepository = GroupRepository(dio: dioClient);
  final chatRepository = ChatRepository(dioClient);
  final contestRepository = ContestRepository(dio: dioClient);
  final stepRepository = StepRepository(dioClient);

  // Initialize step services
  final stepCounterService = StepCounterService();
  await stepCounterService.init();
  final stepSyncService = StepSyncService();
  await stepSyncService.init(dioClient);

  runApp(
    WalkTogetherApp(
      storageService: storageService,
      authRepository: authRepository,
      groupRepository: groupRepository,
      chatRepository: chatRepository,
      contestRepository: contestRepository,
      stepCounterService: stepCounterService,
      stepSyncService: stepSyncService,
      stepRepository: stepRepository,
    ),
  );
}

class WalkTogetherApp extends StatelessWidget {
  final StorageService storageService;
  final AuthRepository authRepository;
  final GroupRepository groupRepository;
  final ChatRepository chatRepository;
  final StepCounterService stepCounterService;
  final ContestRepository contestRepository;
  final StepSyncService stepSyncService;
  final StepRepository stepRepository;

  const WalkTogetherApp({
    super.key,
    required this.storageService,
    required this.authRepository,
    required this.groupRepository,
    required this.chatRepository,
    required this.contestRepository,
    required this.stepCounterService,
    required this.stepSyncService,
    required this.stepRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GroupRepository>.value(value: groupRepository),
        RepositoryProvider<ChatRepository>.value(value: chatRepository),
        RepositoryProvider<ContestRepository>.value(value: contestRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: authRepository)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) => GroupListBloc(repository: groupRepository),
          ),
          BlocProvider(
            create: (_) => ConversationListBloc(repository: chatRepository),
          ),
          BlocProvider(
            create: (_) => StepTrackerBloc(
              counterService: stepCounterService,
              syncService: stepSyncService,
              stepRepository: stepRepository,
            ),
          ),
        ],
        child: _AppView(storageService: storageService),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  final StorageService storageService;
  const _AppView({required this.storageService});

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final AuthChangeNotifier _authNotifier;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthChangeNotifier();
    _appRouter = AppRouter(authNotifier: _authNotifier);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        bool isLoggedIn = false;
        String? companyStatus;
        bool isConnectingServer = false;

        if (state is AuthConnectingServer || state is AuthConnectingFailed) {
          isConnectingServer = true;
        } else if (state is AuthAuthenticated) {
          isLoggedIn = true;
          companyStatus = 'approved';
          // Switch step counter to this user's box
          StepCounterService().switchUser(state.user.id);
          // Auto-start step tracking
          if (context.mounted) {
            context.read<StepTrackerBloc>().add(StepTrackerStartRequested());
          }
          // Connect socket with stored token
          _connectSocket();
        } else if (state is AuthPendingApproval) {
          isLoggedIn = true;
          companyStatus = 'pending';
        } else if (state is AuthCompanyRejected) {
          isLoggedIn = true;
          companyStatus = 'rejected';
        } else if (state is AuthCompanySuspended) {
          isLoggedIn = true;
          companyStatus = 'suspended';
        } else if (state is AuthUnauthenticated) {
          // Detach step data (preserves per-user data), stop sync, disconnect socket
          StepCounterService().detachUser();
          StepSyncService().clearQueue();
          SocketService().disconnect();
        }

        _authNotifier.update(
          isLoggedIn: isLoggedIn,
          companyStatus: companyStatus,
          isConnectingServer: isConnectingServer,
        );
      },
      child: MaterialApp.router(
        title: 'Runly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _appRouter.router,
      ),
    );
  }

  Future<void> _connectSocket() async {
    final token = await widget.storageService.getAccessToken();
    if (token != null) {
      SocketService().connect(token);
    }
  }
}
